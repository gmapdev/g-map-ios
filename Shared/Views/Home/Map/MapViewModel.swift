//
//  MapViewModel.swift
//

import Combine
import SwiftUI
import Mapbox

struct RequestMapStops: Codable {
    let query: String
}

class MapViewModel: ObservableObject {
    var service: APIServiceProtocol = APIService()
    var searchCompletion: (() -> Void)? = nil
    
    
    public var stops = [Stop]()
    /// Label: "ibigroup.map.stops.locker"
    /// Initializes a new instance.
    /// - Parameters:
    ///   - label: "ibigroup.map.stops.locker"
    private var stopsLocker = DispatchQueue.init(label: "ibigroup.map.stops.locker")
    
    private var cancellableSet = Set<AnyCancellable>()
    public static let shared: MapViewModel = {
        let mgr = MapViewModel()
        mgr.getStops()
        return mgr
    }()
    
    @Published var annotations: [MGLPointAnnotation] = []
    @Published var coordinateCenter: CLLocationCoordinate2D = BrandConfig.shared.default_location
    @Published var zoomLevel = Double(BrandConfig.shared.zoom_level)
    
    /// Add marker
    /// Adds marker.
    func addMarker() {
        annotations = [
            MGLPointAnnotation(title: "IBI",
                               coordinate: BrandConfig.shared.default_location)
        ]
    }
    
    /// Get stops
    /// Retrieves stops.
    func getStops() {
        MapAnnotationsFeedProvider.shared.getMapStops { filteredStopList in
            if let filteredStopList = filteredStopList {
                self.consolidateStops(comingStops: filteredStopList)
                self.annotations = filteredStopList.map( { MGLPointAnnotation(stop: $0) })
            }
        }
    }
    
    // For later favourite stop use
    /// Consolidate stops.
    /// - Parameters:
    ///   - comingStops: [Stop]
    public func consolidateStops(comingStops: [Stop]){
        stopsLocker.async {
            var newStops = [Stop]()
            for comingStop in comingStops {
                var existed = false
                for stop in self.stops {
                    if stop.id == comingStop.id {
                        existed = true
                        break
                    }
                }
                if !existed {
                    newStops.append(comingStop)
                }
            }
            self.stops.append(contentsOf: newStops)
        }
    }
}
