//
//  TripViewerViewModel.swift
//

import SwiftUI
import Mapbox
import Combine

class TripViewerViewModel: ObservableObject,TripsService {
    @State var coordinateCenter: CLLocationCoordinate2D = BrandConfig.shared.default_location
    @Published var zoomLevel = Double(BrandConfig.shared.zoom_level)
    @Published var itinerary: OTPItinerary? = nil
    @Published var itineraryStop: OTPLeg? = nil
    @Published var isLoading: Bool = false
    @Published var showAlert = false
	@Published var pubIsShowingTripViewer = false
	
    private var cancellableSet = Set<AnyCancellable>()
    var service: APIServiceProtocol = APIService()
    var errorMessage: String = ""
    private var stopTimes: [StopTime] = []
    var tripDetails: TripDetails?
    @Published var tripInfoItems: [TripInfoItem] = []
	
 /// Shared.
 /// - Parameters:
 ///   - TripViewerViewModel: Parameter description
	static var shared: TripViewerViewModel = {
		let mgr = TripViewerViewModel()
		return mgr
	}()
    
    /// Prepare trip viewer data
    /// Prepare trip viewer data.
    func prepareTripViewerData() {
        if let itineraryStop = itineraryStop, let trip = itineraryStop.trip, let tripId = trip.gtfsID{
            
            getStopTimes(tripId: tripId)
            getTripDetails(tripId: tripId)
		}
    }
    
    /// Get stops.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// Retrieves stops.
    private func getStops(tripId: String) {
        let cancellable = stops(tripId: tripId)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Handle error: \(error)")
                    self?.errorMessage = error.displayMessage
                    self?.showAlert = true
                case .finished:
                    break
                }

            }) { [weak self] (response) in
                guard let self = self else { return }
                self.tripInfoItems = response.map({ TripInfoItem(stop: $0, stopTime: self.stopTimes(for: $0)) })
                self.isLoading = false
        }
        cancellableSet.insert(cancellable)
    }
    
    /// Stop times.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: StopTime?
    private func stopTimes(for stop: Stop) -> StopTime? {
        return stopTimes.first(where: { $0.stopID == stop.id })
    }
    
    /// Get stop times.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// Retrieves stop times.
    private func getStopTimes(tripId: String) {
        let cancellable = stopTimes(tripId: tripId)
            .sink(receiveCompletion: { [weak self] result in
				DispatchQueue.main.async {
					self?.isLoading = false
				}
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Handle error: \(error)")
					DispatchQueue.main.async {
						self?.errorMessage = error.displayMessage
						self?.showAlert = true
					}
                case .finished:
                    break
                }
            }) { [weak self] (response) in
                guard let self = self else { return }
				DispatchQueue.main.async {
					self.stopTimes = response
					self.getStops(tripId: tripId)
				}
        }
        cancellableSet.insert(cancellable)
    }
    
    /// Get trip details.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// Retrieves trip details.
    private func getTripDetails(tripId: String){
        let cancellable = tripDetails(tripId: tripId)
            .sink(receiveCompletion: { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Handle error: \(error)")
                    DispatchQueue.main.async {
                        self?.errorMessage = error.displayMessage
                        self?.showAlert = true
                    }
                case .finished:
                    break
                }
            }) { [weak self] (response) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.tripDetails = response
                }
        }
        cancellableSet.insert(cancellable)
        
    }
}
