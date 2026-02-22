//
//  LiveRouteManager.swift
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation


/// This class is used to manage the activated when user select one of itinerary candidates.
class LiveRouteManager: ObservableObject {
	
	@Published var pubLastUpdated = Date().timeIntervalSince1970
	@Published var pubIsRouteActivated = false
    @Published var pubIsShowRouteDetails = false
    @Published var tripHasEndedStatus = false
    @Published var pubServerInstructions : String = "Calculating..."
    @Published var pubServerMessage : String = "Fetching the instructions..."
    @Published var pubLiveTrackingAudioAlertDialog = false
    @Published var pubLiveTrackingAudioAlert = false
    @Published var pubLiveTrackingLoading = false
    
    // This is used to define this Live Tracking mode is preview mode or not.
    @Published var pubIsPreviewMode = false
	
	// for server reporting purpose.
	public var reportServerFrequencyInSecs: Double = 5
	public var tripId: String = ""
    
    private var tripIdforReroutedPath: String = ""
	public var journeyId: String = ""
	public var instruction: String = ""
	public var periodicallyReportTimer: Timer? = nil
	public var reportedLocation = [TrackingLocation]()
 /// Label: "reported.location.lock"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - label: "reported.location.lock"
	public var reportedLocationLock = DispatchQueue.init(label: "reported.location.lock")
    private var isRouteReportingActive = false  // Controls whether location reporting should proceed

	public var arriveText = "\("Calculating".localized())..."
	public var minLeft = "Time".localized()
	public var distanceLeft = "Distance".localized()
	
	// This variable is used to fix the minLeft without live tracking.
	public var staticMinLeftText:String?
	
	/// Used to remember how many time it spends since the route starts
	private var totalSecondsCost: Int = 0
	
	/// Used to remember how many total mins, it needs to finish the trip
	private var totalMins: Double = 0
	
	/// Used to remember how many kilometers, it need to finish the trip
	private var totalDistanceMeters: Double = 0
	
	/// Used to reference the distance, so that, we can use the ratio to get the approximate ETA, this is two point distance.
	private var referenceLengthMeters: Double = 0
	
	/// Used to periodically check the ETA and so on.
	private var routeMonitoringTimer: Timer?
    
    /// Timer to check for route deviation duration
    private var isRerouting: Bool = false
    private var deviationTimestamp: TimeInterval? = nil
    
    /// Time interval (in seconds) after which rerouting will be triggered if the user remains in a deviated state.
    private var deviatedDuration: TimeInterval = FeatureConfig.shared.live_tracking_deviation_waittime_seconds
    
    private var lastInstructionTimestamp: TimeInterval = 0
    /// Time interval (in seconds) after already announced instruction can be re-announced
    private var instructionRepeatThreshold: TimeInterval = FeatureConfig.shared.live_tracking_repeat_instruction_waittime_seconds
    
    private var previousLocateMeSetting: Bool? = nil
    
    // To hold the last played instruction
    private var lastPlayedInstruction: String?
    
    // To check weather Arrived at Destination is Already announced or not
    private var isArrivedAnnoncedAlready : Bool = false
    
    public var from : CLLocation = CLLocation(latitude: 0, longitude: 0)
    public var to : CLLocation = CLLocation(latitude: 1, longitude: 1)
    
    // To Hold the Map Layer setting for TripPlanning
    private var previousLayerSelection: [MapLayerItem]? = nil
	
 /// Shared.
 /// - Parameters:
 ///   - LiveRouteManager: Parameter description
	public static var shared: LiveRouteManager = {
		let mgr = LiveRouteManager()
		return mgr
	}()
	
 /// Calculate itinerary distance
 /// - Returns: Double
 /// Calculates itinerary distance.
	public func calculateItineraryDistance() -> Double {
		var distance = 0.0
		if let itinerary = TripPlanningManager.shared.pubSelectedItinerary {
			if let legs = itinerary.legs {
				for leg in legs {
					let f = placeCLLocation(Coordinate(latitude: leg.from?
						.lat ?? 0, longitude: leg.from?.lon ?? 0))
					let t = placeCLLocation(Coordinate(latitude: leg.to?
						.lat ?? 0, longitude: leg.to?.lon ?? 0))
					distance += distanceInMeters(from: f, to: t)
				}
			}
		}
		return distance
	}
	
 /// Place c l location.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: CLLocation
	public func placeCLLocation(_ coordinate: Coordinate?) -> CLLocation {
		let currentLocation = LocationService.shared.getCurrentLocation()
		let placeLat = coordinate?.latitude ?? currentLocation.coordinate.latitude
		let placeLon = coordinate?.longitude ?? currentLocation.coordinate.longitude
		let place = CLLocation(latitude: placeLat, longitude: placeLon)
		return place
	}
	
    /// Start monitoring route.
    /// - Parameters:
    ///   - isReroute: Parameter description
    /// Starts monitoring route.
    public func startMonitoringRoute(isReroute: Bool = false){
		
		self.pubIsRouteActivated = true
        self.setOnlyTransitStopsVisibleforLiveTracking(set: true)
        self.setLocateMeEnabledbyDefault(true)
		let basicSpeed = 16.6667
		self.totalDistanceMeters = calculateItineraryDistance()
		self.totalMins = self.totalDistanceMeters/basicSpeed/60
        referenceLengthMeters = distanceInMeters(from: self.from, to: self.to)
		
		DispatchQueue.main.async {
			self.routeMonitoringTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updateActiveRouteInfo), userInfo: nil, repeats: true)
		}
		
		// prepare to report to server for the location.
		if FeatureConfig.shared.isLiveTrackingEnable {
            prepareToStartReportTracking(isReroute: isReroute)
		}
	}
	
 /// Prepare to start report tracking.
 /// - Parameters:
 ///   - isReroute: Parameter description
	private func prepareToStartReportTracking(isReroute: Bool){
		self.clearRouteReporting()
        
        if !isReroute{
            let tripId = TripPlanningManager.shared.pubSelectedItinerary?.id ?? "n/a"
            self.tripId = tripId
            self.tripIdforReroutedPath = self.tripId
        }else{
            self.tripId = self.tripIdforReroutedPath
        }
        self.isRouteReportingActive = true
		self.instruction = ""
		self.reportLocation()
		self.periodicallyReportLocation()
	}
	
 /// Clear route reporting
 /// Clears route reporting.
	private func clearRouteReporting(){
		if let t = periodicallyReportTimer {
			t.invalidate()
			self.periodicallyReportTimer = nil
		}
		self.tripId = ""						// used for server to track the journey.
		self.journeyId = ""
		self.reportServerFrequencyInSecs = 5 	// by default when we start a route we set it as default 5 seconds.
		self.instruction = ""
        clearTrackedLocation()
        DispatchQueue.main.async{
            self.pubIsShowRouteDetails = false
            self.tripHasEndedStatus = false
        }
	}
	
    /// Stop route reporting.
    /// - Parameters:
    ///   - completion: Parameter description
    /// - Returns: Void)? = nil)
    public func stopRouteReporting(completion: (() -> Void)? = nil) {
        // Stop new reporting immediately
        self.isRouteReportingActive = false

        if self.journeyId.count > 0 {
            APIManager.shared.stopReportTracking(journeyId: self.journeyId) { errorMsg in
                self.clearRouteReporting()
                if let errorMsg = errorMsg {
                    DispatchQueue.main.async {
                        AlertManager.shared.presentAlert(message: errorMsg)
                    }
                }
                completion?()
            }
        } else {
            completion?()
        }
    }

	
 /// Clear tracked location
 /// Clears tracked location.
	public func clearTrackedLocation(){
		self.reportedLocationLock.async {
			self.reportedLocation.removeAll()
		}
	}
    
 /// Update tracked location.
 /// - Parameters:
 ///   - location: Parameter description
    public func updateTrackedLocation(location:CLLocation){
        
        if self.pubIsRouteActivated {
            self.reportedLocationLock.async {
                self.reportedLocation.append(TrackingLocation(bearing: location.course,
                                                              lat: location.coordinate.latitude,
                                                              lon: location.coordinate.longitude,
                                                              speed: location.speed,
                                                              timestamp: Int(Date().timeIntervalSince1970),
                                                              locationAccuracy: location.horizontalAccuracy
                                                             )
                )
            }
        }
    }
	
    /// Periodically report location
    /// Periodically report location.
    public func periodicallyReportLocation() {
        DispatchQueue.main.async {
            self.periodicallyReportTimer?.invalidate() // Ensure old timer is cleared
            self.periodicallyReportTimer = nil

            // Only schedule if route reporting is active
            guard self.isRouteReportingActive else { return }

            self.periodicallyReportTimer = Timer.scheduledTimer(withTimeInterval: self.reportServerFrequencyInSecs, repeats: false) { timer in
                
                // Before executing reportLocation, check if reporting is still active
                guard self.isRouteReportingActive else { return }
                
                self.reportLocation()
            }
        }
    }

    
    /// Reroute deviated trip
    /// Reroute deviated trip.
    private func rerouteDeviatedTrip(){
        if self.reportedLocation.count > 0 && self.tripId.count > 0 {
            let locations = self.reportedLocation
            APIManager.shared.requestRoute(tripId: self.tripId, locations: locations) { trackingLocationRep, message in
                if let response = trackingLocationRep{
                    if let newItinery = response.itinery{
                        
                        MapManager.shared.cleanPlotRoute()
                        MapManager.shared.forceCleanMapReDrawRoute()
        
                        DispatchQueue.main.async {
                            TripPlanningManager.shared.pubPreviousSelectedItinerary = TripPlanningManager.shared.pubSelectedItinerary
                            TripPlanningManager.shared.pubSelectedItinerary = newItinery
                            TripPlanningManager.shared.didSelectItem(newItinery)
                            if let legs = newItinery.legs,
                               legs.count > 0 {
                                let firstLeg = legs.first!
                                let lastLeg = legs.last!
                                LiveRouteManager.shared.from = CLLocation(latitude: firstLeg.from?.lat ?? 0.0, longitude: firstLeg.from?.lon ?? 0.0)
                                LiveRouteManager.shared.to = CLLocation(latitude: lastLeg.to?.lat ?? 0.0, longitude: lastLeg.to?.lon ?? 0.0)
                                LiveRouteManager.shared.pubIsPreviewMode = false
                                LiveRouteManager.shared.startMonitoringRoute(isReroute: true)

                                GenericDialogBoxManager.shared.present(title: "Attention", message: "Reroute Successfully", primaryButtonText: "Ok", secondaryButtonText: nil) { result in
                                    self.isRerouting = false
                                    self.deviationTimestamp = nil
                                }
                            }
                        }
                    }else{
                        GenericDialogBoxManager.shared.present(title: "Attention", message: "There was no re-route itinerary found.", primaryButtonText: "Ok", secondaryButtonText: nil) { result in
                            self.isRerouting = false
                            self.deviationTimestamp = nil
                        }
                    }
                }else{
                    GenericDialogBoxManager.shared.present(title: "Attention", message: "Failed to re-route. Would you like to try again?", primaryButtonText: "Yes", secondaryButtonText: "No") { result in
                        if result == "Yes"{
                            self.rerouteDeviatedTrip()
                        }else{
                            self.isRerouting = false
                            self.deviationTimestamp = nil
                        }
                    }
                }
            }
        }
    }
        
    /// Report location
    /// Report location.
    private func reportLocation() {
        // Ensure there are locations to report and a valid trip ID; otherwise, clear and retry reporting later.
        guard isRouteReportingActive, !reportedLocation.isEmpty, !tripId.isEmpty else {
            clearTrackedLocation()
            periodicallyReportLocation()
            return
        }
        
        // Lock to safely read reported locations
        reportedLocationLock.async {
            let locations = self.reportedLocation
            
            DispatchQueue.main.async {  // Ensure API call runs on the main thread
                guard self.isRouteReportingActive else { return }  // Double-check before proceeding
                
                if self.pubLiveTrackingLoading {
                    LiveRouteManager.shared.pubLiveTrackingLoading = false
                }
                
                APIManager.shared.reportLocationV2(tripId: self.tripId, locations: locations) { trackingLocationRep in
                    guard let rep = trackingLocationRep, self.isRouteReportingActive else {
                        OTPLog.log(level: .error, info: "Failed to upload and report \(locations.count) GPS locations to server.")
                        return
                    }
                    
                    // Handle trip status updates (DEVIATED, COMPLETED)
                    if let status = rep.tripStatus {
                        switch status {
                        case "DEVIATED":
                            let currentTime = Date().timeIntervalSince1970
                            if self.deviationTimestamp == nil {
                                self.deviationTimestamp = currentTime
                            } else if (currentTime - self.deviationTimestamp!) > self.deviatedDuration, !self.isRerouting {
                                self.deviationTimestamp = nil
                                GenericDialogBoxManager.shared.present(
                                    title: "Attention",
                                    message: "It looks like you've deviated from your route. Would you like to re-route?".localized(),
                                    primaryButtonText: "Yes",
                                    secondaryButtonText: "No"
                                ) { result in
                                    if result == "Yes" {
                                        self.isRerouting = true
                                        self.rerouteDeviatedTrip()
                                    }
                                }
                            }
                            
                        case "COMPLETED":
                            
                                // Update instructions if available
                                if let instructions = rep.instruction, !instructions.isEmpty {
                                    self.pubServerInstructions = instructions
                                } else if self.pubServerInstructions == "Calculating..." {
                                    self.pubServerInstructions = "Calculating..."
                                }
                                self.tripHasEndedStatus = true
                                self.isRouteReportingActive = false
                                // Ensure last instruction is played before "arrived at" announcement
                                self.playAudioAnnouncementsAndHapticFeedback()
                                
                            
                        default:
                            break
                        }
                    }
                    
                    // Update reporting frequency if provided
                    if let fs = rep.frequencySeconds {
                        self.reportServerFrequencyInSecs = fs
                    }
                    
                    // Update instructions if available
                    if let instructions = rep.instruction, !instructions.isEmpty {
                        DispatchQueue.main.async { self.pubServerInstructions = instructions }
                    } else if self.pubServerInstructions == "Calculating..." {
                        self.pubServerInstructions = "Calculating..."
                    }
                    
                    // Update messages if available
                    if let message = rep.message, !message.isEmpty {
                        DispatchQueue.main.async { self.pubServerMessage = message }
                    } else {
                        DispatchQueue.main.async { self.pubServerMessage = "" }
                    }
                    
                    self.playAudioAnnouncementsAndHapticFeedback()
                    
                    OTPLog.log(level: .info, info: "Successfully uploaded and reported \(locations.count) GPS locations to server.")
                    self.clearTrackedLocation()
                    self.journeyId = rep.journeyId ?? ""
                    self.periodicallyReportLocation()
                }
            }
        }
    }

    /// Play audio announcements and haptic feedback
    /// Play audio announcements and haptic feedback.
    private func playAudioAnnouncementsAndHapticFeedback() {
        // Early exit if the instruction is empty or "Calculating..."
        let currentInstruction = self.pubServerInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentInstruction.isEmpty || currentInstruction == "Calculating..." {
            OTPLog.log(level: .info, info: "Skipping empty or 'Calculating...' instruction")
            return
        }
        
        // Variables
        let isHapticEnabled = ProfileManager.shared.isHapticFeedbackOpen
        let isAudioEnabled = self.pubLiveTrackingAudioAlert
        
        // Check if we should skip or repeat the same instruction
        if currentInstruction == self.lastPlayedInstruction {
            let timeSinceLastPlay = Date().timeIntervalSince1970 - self.lastInstructionTimestamp
            if timeSinceLastPlay < instructionRepeatThreshold {
                OTPLog.log(level: .info, info: "Skipping duplicate instruction within threshold: \(currentInstruction)")
                return
            } else {
                OTPLog.log(level: .info, info: "Repeating same instruction after \(Int(timeSinceLastPlay))s: \(currentInstruction)")
            }
        }
        
        // Handle Haptic Feedback (off main thread)
        if isHapticEnabled {
            // Async to avoid blocking main thread unnecessarily
            DispatchQueue.global(qos: .userInteractive).async {
                UINotificationFeedbackGenerator().notificationOccurred(AppSession.shared.hapticFeedbackStyle)
            }
        }
        
        // Handle Audio Announcement (off main thread)
        if isAudioEnabled {
            OTPLog.log(level: .info, info: "Playing instruction: \(currentInstruction)")
            TravelIQAudio.shared.playAudio(fromText: currentInstruction, parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in }
        }
        
        self.lastPlayedInstruction = currentInstruction
        self.lastInstructionTimestamp = Date().timeIntervalSince1970
        
        // If the trip is completed, handle "COMPLETED" status
        if self.tripHasEndedStatus {
            // Play the "COMPLETED" instruction
            if isHapticEnabled {
                DispatchQueue.global(qos: .userInteractive).async {
                    UINotificationFeedbackGenerator().notificationOccurred(AppSession.shared.hapticFeedbackStyle)
                }
            }
            
            if isAudioEnabled {
                TravelIQAudio.shared.playAudio(fromText: self.pubServerInstructions, parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in
                    // Queue arrival message only once
                    if !self.isArrivedAnnoncedAlready {
                        let arrivalMessage = "You have arrived at " + self.getToNameOfTrip()
                        TravelIQAudio.shared.playAudio(fromText: arrivalMessage, parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in
                            self.isArrivedAnnoncedAlready = true
                        }
                    }
                }
            }
            
            self.lastPlayedInstruction = currentInstruction
            self.lastInstructionTimestamp = Date().timeIntervalSince1970
            return // Exit early if trip is completed
        }
    }

 /// Stop monitoring route
 /// Stops monitoring route.
	public func stopMonitoringRoute(){
		self.pubIsRouteActivated = false
		if let timer = self.routeMonitoringTimer {
			timer.invalidate()
		}
		self.routeMonitoringTimer = nil
	}
    /// Get from name of trip
    /// - Returns: String
    /// Retrieves from name of trip.

    /// - Returns: String
    public func getFromNameOfTrip() -> String {
        return ProfileManager.shared.selectedTripNotification?.from.name ?? ""
    }
    /// Get to name of trip
    /// - Returns: String
    /// Retrieves to name of trip.
    public func getToNameOfTrip() -> String {
        return ProfileManager.shared.selectedTripNotification?.to.name ?? ""
    }
    /// Get total distance of trip
    /// - Returns: String
    public func getTotalDistanceOfTrip() -> String {
        var totalDistance = 0.0
        if let seletectItinerary = TripPlanningManager.shared.pubSelectedItinerary{
            if let legs = seletectItinerary.legs{
                for leg in legs {
                    totalDistance += leg.distance ?? 0.0
                }
            }
        }
        let distanceInMiles = totalDistance * 0.000621371
        let milesInString = String(format: "%.1f", distanceInMiles)
        return milesInString == "0.0" ? "" : "Around \(milesInString) Miles"
    }
	
 /// Update active route info
 /// Updates active route info.
	@objc private func updateActiveRouteInfo(){

		// calculate the approximate ETA and time
		let from = LocationService.shared.getCurrentLocation()
        let currentDistance = distanceInMeters(from: from, to: self.to)
		if referenceLengthMeters < 1 { referenceLengthMeters = 1 }
		let newDistance = currentDistance/referenceLengthMeters*totalDistanceMeters
		let newTimeMins = Int(currentDistance/referenceLengthMeters*totalMins)
		let newDate = Date().addingTimeInterval(Double(newTimeMins)*60)
		let readableDate = TravelIQUtils.convertTimestampToLocal(newDate.timeIntervalSince1970, toFormat: "hh:mm a", withAMSymbol: "a.m.", withPMSymbol: "p.m.")
		
		if newTimeMins == 0 {
			self.arriveText = "Arrive Destination".localized()
			self.minLeft = "\("Total Time Spent".localized()): "
			let totalTimeSpentText = "\(readableTrafficTime(mins: Int(self.totalSecondsCost/60)))"
			if totalTimeSpentText == "No delay".localized(){
				self.distanceLeft = "%1 min".localized("0")
			}else{
				self.distanceLeft = totalTimeSpentText
			}
			
		}
		else{
			let mile_localized = "miles".localized()
			self.totalSecondsCost += 1
			self.minLeft = "\(readableTrafficTime(mins: newTimeMins)) left"
			self.arriveText = "Arrive at \(readableDate)"
			var value:Double = (newDistance/1000)
			value = value * 0.621371
			let valueText = "\(value.format(f: ".2")) \(mile_localized)"
			self.distanceLeft = "around \(valueText)"
		}
		
		DispatchQueue.main.async {
			//MapManager.shared.mapView.setCenter(from.coordinate, animated: true)
			self.pubLastUpdated = Date().timeIntervalSince1970
		}
	}
	
 /// Distance in meters.
 /// - Parameters:
 ///   - from: Parameter description
 ///   - to: Parameter description
 /// - Returns: Double
	public func distanceInMeters(from: CLLocation, to: CLLocation) -> Double {
		let distance = to.distance(from: from)
		return distance
	}
	
 /// Readable traffic time.
 /// - Parameters:
 ///   - mins: Parameter description
 /// - Returns: String
	public func readableTrafficTime(mins: Int) -> String {
		if mins == 0 {
			return "No delay".localized()
		}
		if mins == 1 {
			return "1 min".localized()
		}
		let hour = mins/60
		let mins = mins%60
		var hourText = ""
		var minsText = ""
		if hour > 0 {
			hourText = "%1 hr".localized(hour) + " "
		}
		minsText = "%1 min".localized(mins)
		
		return "\(hourText)\(minsText)"
	}
    
    /// Reset live tracking
    /// Resets live tracking.
    @MainActor func resetLiveTracking(){
        self.stopRouteReporting()
        self.stopMonitoringRoute()
        self.pubServerInstructions = "Calculating..."
        self.pubServerMessage = "Fetching the instructions..."
        self.deviationTimestamp = nil
        self.isArrivedAnnoncedAlready = false
        self.isRouteReportingActive = false
        MapManager.shared.followMe(enable: false)
        TripPlanningManager.shared.pubSelectedItinerary = TripPlanningManager.shared.pubPreviousSelectedItinerary
        TripPlanningManager.shared.pubPreviousSelectedItinerary = nil
        MapManager.shared.forceCleanMapReDrawRoute()
        TabBarMenuManager.shared.currentViewTab = .myTrips
        TabBarMenuManager.shared.currentItemTab = .myTrips
        MapManager.shared.pubHideAddressBar = false
        self.setOnlyTransitStopsVisibleforLiveTracking(set: false)
        self.setLocateMeEnabledbyDefault(false)
        NotificationManager.shared.cancelRunningNotification()
    }
    
    /// Dismiss preview mode
    /// Dismisses preview mode.
    @MainActor func dismissPreviewMode(){
        LiveRouteManager.shared.pubIsPreviewMode = false
        LiveRouteManager.shared.pubIsRouteActivated = false
        MapManager.shared.followMe(enable: false)
        TripPlanningManager.shared.pubSelectedItinerary = TripPlanningManager.shared.pubPreviousSelectedItinerary
        TripPlanningManager.shared.pubPreviousSelectedItinerary = nil
        MapManager.shared.forceCleanMapReDrawRoute()
        TabBarMenuManager.shared.currentViewTab = .myTrips
        TabBarMenuManager.shared.currentItemTab = .myTrips
        MapManager.shared.pubHideAddressBar = false
    }
    
    /// Set only transit stops visiblefor live tracking.
    /// - Parameters:
    ///   - set: Parameter description
    /// Sets only transit stops visiblefor live tracking.
    func setOnlyTransitStopsVisibleforLiveTracking(set enable: Bool) {
        if enable {
            // Save current selection if not already stored
            if previousLayerSelection == nil {
                previousLayerSelection = MapManager.shared.layers
            }

            var updatedLayers = [MapLayerItem]()
            var layersToRemove = [MarkerType]()

            for item in MapManager.shared.layers {
                var newItem = item
                if item.type == .transitStop {
                    newItem.isSelected = true
                } else {
                    newItem.isSelected = false
                    layersToRemove.append(item.type)
                }
                updatedLayers.append(newItem)
            }

            MapManager.shared.layers = updatedLayers

            // Remove non-transitStop layers
            for type in layersToRemove {
                MapManager.shared.removeAnnotationLayer(layerName: type.rawValue)
            }
        } else {
            // Restore the previous state if it exists
            if let original = previousLayerSelection {
                MapManager.shared.layers = original
                previousLayerSelection = nil
            }
            MapManager.shared.renderMarkerInMap()
        }
    }
    
    /// Set locate me enabledby default.
    /// - Parameters:
    ///   - _: Parameter description
    /// Sets locate me enabledby default.
    func setLocateMeEnabledbyDefault(_ enable: Bool){
        if enable {
            if self.previousLocateMeSetting == nil {
                self.previousLocateMeSetting = MapManager.shared.isLocateMe
                
                MapManager.shared.followMe(enable: true)
            }
        }else{
            if let originalSetting = self.previousLocateMeSetting {
                MapManager.shared.isLocateMe = originalSetting
                self.previousLocateMeSetting = nil
            }
        }
        
    }

}
