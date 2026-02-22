//
//  LocationService.swift
//

import Foundation
import UIKit
import MapKit

/// This is the delegate, which is used to handle the location callback function
public protocol LocationServiceDelegate: AnyObject {
	
	/// If there is a location updates, this function will be called. if the simulation mode is enabled. this function will receive the simulation updates.
	func locationUpdated(manager:CLLocationManager, locations:[CLLocation])
	
	/// Any errors related to the location will pass to this delegate.
	func locationError(message: String)
}

open class LocationService: NSObject {
	
	// MARK: PRIVATE DEFINITION
	/// Default CLLocationManager instance from iOS framework
	fileprivate var  locationManager:CLLocationManager?
	
	/// Remember the user current location
	fileprivate var userLocation: CLLocation?
	
	/// Flag to indicate whether the simualtor is enabled or not
	fileprivate var simulatorIsEnabled: Bool = false
	
	/// This timer is used to move the current location when the simulatorIsEnabled becomes to true
	fileprivate var simulatorTimer: Timer?
	
	/// This is the index which is used to control the moving point
	private var simulatorPointIndex: Int = 0
	
	/// This is the container which is used to hold the simulation point
	private var simulatorPoints = [CLLocationCoordinate2D]()
	
	/// This is the simulated speed for the simulator
	private var simulatorSpeedKMH: Double = 60

	/// The default init for the TravelIQLocation
	override init() {
		super.init()
		
		locationManager = CLLocationManager()
		locationManager?.delegate = self
		locationManager?.pausesLocationUpdatesAutomatically = false
		locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
	}
	
	// MARK: PUBLIC DEFINITION
	
	/// This is used to setup the default location if no GPS signal is found
	public var defaultLocation: CLLocation?
	
	/// Used to hold the location services delegate
	public weak var locationDelegate:LocationServiceDelegate?
	
	/// The shared instance of the location service.
	public static var shared: LocationService = {
		let locationService = LocationService()
		return locationService
	}()
	
	/// Get the current location of the user
 /// Retrieves current location.
 /// - Returns: CLLocation
	public func getCurrentLocation()->CLLocation {
		return userLocation ?? (defaultLocation ?? CLLocation(latitude: 0, longitude: 0))
	}
	
	/// This is used to start the simulator and move the location in the map
 /// Starts simulator.
 /// - Parameters:
 ///   - points: [CLLocationCoordinate2D]
 ///   - simulatedSpeedKMH: Double = 60
	public func startSimulator(points: [CLLocationCoordinate2D], simulatedSpeedKMH: Double = 60) {
		if let timer = self.simulatorTimer {
			timer.invalidate()
			self.simulatorTimer = nil
		}
		
		// Reset the simulator index, so that we can start from the front
		self.simulatorPointIndex = 0
		
		// replace the simulator points
		self.simulatorPoints = points
		
		self.simulatorSpeedKMH = simulatedSpeedKMH
		
		// Prepare the simulator data
		self.simulatorIsEnabled = true
		
		// Start to run the simulator
		MapManager.shared.removeSimulatedLocation()
		self.simulatorTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(simulateLocation), userInfo: nil, repeats: true)
	}
	
	/// This function will be frequently called to update the location for the simulator
 /// Simulate location.
	@objc private func simulateLocation() {
		
		if self.simulatorPointIndex >= self.simulatorPoints.count {
			self.simulatorPointIndex = 0
		}
		var simLatitude = getCurrentLocation().coordinate.latitude
		var simLongitude = getCurrentLocation().coordinate.longitude

		if self.simulatorPointIndex < self.simulatorPoints.count {
			simLatitude = self.simulatorPoints[self.simulatorPointIndex].latitude
			simLongitude = self.simulatorPoints[self.simulatorPointIndex].longitude
		}
		else{
			self.simulatorPointIndex = 0
		}

		let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: simLatitude, longitude: simLongitude), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: self.simulatorSpeedKMH/3.6, timestamp: Date())

		if let manager = locationManager {
			
			LiveRouteManager.shared.updateTrackedLocation(location: location)
			
			self.locationDelegate?.locationUpdated(manager: manager, locations: [location])
            
            /// This is used to check weather the current location is in Trigger GeoFence
            JMapManager.shared.checkGeoFenceDetection(currentLocations: [location])
            
            /// This is used to check weather the current location is near to Main Entrance of Indoor Nav
            JMapManager.shared.checkMainEntranceforIndoorNav(currentLocations: [location])

		}
		
		DispatchQueue.main.async{
			MapManager.shared.removeSimulatedLocation()
			MapManager.shared.addSimulatedLocation(coordinate: location.coordinate)
		}
		self.simulatorPointIndex += 1
	}
	
	/// This is used to stop the simuatlor
 /// Stops simulator.
	public func stopSimulator() {
		
		self.simulatorIsEnabled = false
		
		if let timer = self.simulatorTimer {
			timer.invalidate()
			self.simulatorTimer = nil
		}
	}
	
	/// This is used to require location permission, without permission, location service won't work. this function should be called before the start() function
 /// Require permission.
	public func requirePermission (){
		guard let manager = locationManager else { return }

		// Only request authorization if it hasn't been determined yet
		let status = manager.authorizationStatus
		if status == .notDetermined {
			manager.requestAlwaysAuthorization()
		}
	}
	
	/// This function is used to check whether user gave the location service permission to the app or not.
 /// Checks if location service enabled.
 /// - Returns: Bool
	public func isLocationServiceEnabled() -> Bool {
		// Use the existing locationManager instance instead of creating a new one
		guard let manager = locationManager else { return false }
		let status = manager.authorizationStatus
		return status == .authorizedAlways || status == .authorizedWhenInUse
	}
	
	/// Start the service of the locaion manager, after this function is called, the call back location update delegate will have effect
 /// Starts.
	public func start(){

		guard let manager = locationManager else { return }

		// Only request authorization if it hasn't been determined yet
		let status = manager.authorizationStatus
		if status == .notDetermined {
			manager.requestAlwaysAuthorization()
		}

		// Start to prepare the location update
		manager.allowsBackgroundLocationUpdates = false

        //allow background location update based on config
        if BrandConfig.shared.enable_background_location_update{
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        }

		DispatchQueue.global().async {
			if CLLocationManager.locationServicesEnabled() {
				self.locationManager?.startUpdatingLocation()
			}else{
				self.locationDelegate?.locationError(message: "Location Services is not available. Please turn it on.")
			}
		}
	}
	
	/// Stop the location services, so that, the app can save the battery and the location update delegate won't be called any more until the start function is called again.
 /// Stops.
	public func stop(){
		locationManager?.stopUpdatingLocation()
	}
	
	/// This is used to get the distace in meters between two locations.
 /// Distance in meters.
 /// - Parameters:
 ///   - from: CLLocation
 ///   - to: CLLocation
 /// - Returns: Double
	public static func distanceInMeters(from: CLLocation, to: CLLocation) -> Double {
		let distance = to.distance(from: from)
		return distance
	}
	
 /// Tracked location
 /// - Returns: TrackingLocation
 /// Tracked location.
	public func trackedLocation() -> TrackingLocation {
		var location = TrackingLocation()
		location.bearing = userLocation?.course
		location.lat = userLocation?.coordinate.latitude ?? 0
		location.lon = userLocation?.coordinate.longitude ?? 0
		location.speed = userLocation?.speed
		location.timestamp = Int(Date().timeIntervalSince1970)
		return location
	}
}

/// TravelIQ Location Manager Delegate implementation, which is used to capture the location update callback from iOS framework
extension LocationService: CLLocationManagerDelegate {

	/// Handle authorization status changes (iOS 14+)
	/// This delegate method is called when the authorization status changes
	public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		let status = manager.authorizationStatus

		switch status {
		case .authorizedAlways, .authorizedWhenInUse:
			OTPLog.log(level: .info, info: "Location authorization granted: \(status == .authorizedAlways ? "Always" : "When In Use")")
			// Authorization granted, location updates can proceed

		case .denied, .restricted:
			OTPLog.log(level: .warning, info: "Location authorization denied or restricted")
			locationDelegate?.locationError(message: "Location access denied. Please enable location services in Settings.")

		case .notDetermined:
			OTPLog.log(level: .info, info: "Location authorization not determined")

		@unknown default:
			OTPLog.log(level: .warning, info: "Unknown location authorization status")
		}
	}

	/// Location Manager callback function implementation here. and simulator implemetation will be placed here as well.
	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

		if !self.simulatorIsEnabled {

			if locations.count > 0 {
				userLocation = locations[0]
			}

			if let loc = userLocation {
				LiveRouteManager.shared.updateTrackedLocation(location: loc)
			}

			self.locationDelegate?.locationUpdated(manager: manager, locations: locations)
		}
        /// This is used to call the check weather the current location is in Trigger GeoFence
        JMapManager.shared.checkGeoFenceDetection(currentLocations: locations)

        /// This is used to check weather the current location is near to Main Entrance of Indoor Nav
        JMapManager.shared.checkMainEntranceforIndoorNav(currentLocations: locations)

	}
}
