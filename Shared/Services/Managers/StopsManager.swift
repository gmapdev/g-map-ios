//
//  StopsManager.swift
//

import Foundation

enum StopAttributes: String {
	case stopName
	case stopId
}

class StopsManager: ObservableObject {
	
	@Published var pubLastUpdated = Date().timeIntervalSince1970
	
	@Inject var userAccountProvider: UserAccountProvider
	
 /// Shared.
 /// - Parameters:
 ///   - StopsManager: Parameter description
	public static var shared: StopsManager = {
		let mgr = StopsManager()
		return mgr
	}()
	
 /// Find stop by name.
 /// - Parameters:
 ///   - stopName: Parameter description
 /// - Returns: Stop?
	public func findStopByName(stopName: String) -> Stop? {
		return findStopByAttribute(value: stopName, stopAttribute: .stopName)
	}
	
 /// Find stop by name and id.
 /// - Parameters:
 ///   - stopName: Parameter description
 ///   - stopId: Parameter description
 /// - Returns: Stop?
	public func findStopByNameAndId(stopName: String, stopId: String) -> Stop? {
		let stops = MapViewModel.shared.stops
		var retStop: Stop?
		for stop in stops {
			if stop.name == stopName && stop.id == stopId{
				retStop = stop
			}
		}
		return retStop
	}
	
 /// Find stop by id.
 /// - Parameters:
 ///   - stopId: Parameter description
 /// - Returns: Stop?
	public func findStopById(stopId: String) -> Stop? {
		return findStopByAttribute(value: stopId, stopAttribute: .stopId)
	}
	
 /// Find stop by attribute.
 /// - Parameters:
 ///   - value: Parameter description
 ///   - stopAttribute: Parameter description
 /// - Returns: Stop?
	private func findStopByAttribute(value: String, stopAttribute: StopAttributes) -> Stop? {
		let stops = MapViewModel.shared.stops
		var retStop: Stop?
		for stop in stops {
			if stopAttribute == .stopName {
                if stop.name == value {
					retStop = stop
				}
			}
			else if stopAttribute == .stopId {
                if stop.id == value {
					retStop = stop
				}
			}
		}
		return retStop
	}
	
 /// Remove favourite stop.
 /// - Parameters:
 ///   - stopId: Parameter description
 /// Removes favourite stop.
	public func removeFavouriteStop(stopId: String){
		if isFavouriteStop(stopId: stopId) {
			var newSavedLocation = [FavouriteLocation]()
			if let locations = AppSession.shared.loginInfo?.savedLocations {
				for location in locations {
					if location.type == "stop" {
						if let _ = findStopByNameAndId(stopName: location.name, stopId: stopId) {}
						else {
							newSavedLocation.append(location)
						}
					}
					else{
						newSavedLocation.append(location)
					}
				}
			}
			
			AppSession.shared.loginInfo?.savedLocations = newSavedLocation
			
			userAccountProvider.storeUserInfoToServer { success in
				if success {
					DispatchQueue.main.async {
						self.pubLastUpdated = Date().timeIntervalSince1970
					}
				}else{
                    AlertManager.shared.presentAlert(message: "Failed to remove the favorite stop".localized())
				}
			}
		}
	}
	
 /// Favourite stop.
 /// - Parameters:
 ///   - stopId: Parameter description
	public func favouriteStop(stopId: String) {
		guard let mapStop = findStopById(stopId: stopId) else {
			return
		}
		
		if !isFavouriteStop(stopId: stopId) {
			let address = mapStop.name
			let icon = "ic_stop"
			let lat = mapStop.lat
			let lon = mapStop.lon
			let name = mapStop.name
			let type = "stop"
			let favouriteLocation: FavouriteLocation = FavouriteLocation(address: address, icon: icon, lat: lat, lon: lon, name: name, type: type)
			
			AppSession.shared.loginInfo?.savedLocations?.append(favouriteLocation)
			userAccountProvider.storeUserInfoToServer { success in
				if success {
					DispatchQueue.main.async {
						self.pubLastUpdated = Date().timeIntervalSince1970
					}
				}else{
					AlertManager.shared.presentAlert(message: "Failed to add the favorite stop")
				}
			}
		}
	}
	
 /// Is favourite stop.
 /// - Parameters:
 ///   - stopId: Parameter description
 /// - Returns: Bool
	public func isFavouriteStop(stopId: String) -> Bool {
		if let locations = AppSession.shared.loginInfo?.savedLocations {
			for location in locations {
				if let _ = findStopByNameAndId(stopName: location.name, stopId: stopId) {
					return true
				}
			}
		}
		return false
	}
}
