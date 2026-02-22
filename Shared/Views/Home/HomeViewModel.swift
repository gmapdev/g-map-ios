//
//  HomeViewModel.swift
//

import SwiftUI
import Mapbox

class HomeViewModel: ObservableObject {

	@Published var pubOpenSideMenu = false
	@Published var zoomLevel = Double(BrandConfig.shared.zoom_level)
    @Published var pubLastUpdated = Date().timeIntervalSince1970

	@State var coordinateCenter: CLLocationCoordinate2D = BrandConfig.shared.default_location
    @State var fromString: String = ""
    @State var toString: String = ""
    var annotations: [MGLPointAnnotation] = []
    
    /// Shared.
    /// - Parameters:
    ///   - HomeViewModel: Parameter description
    public static var shared: HomeViewModel = {
        let viewModel = HomeViewModel()
        return viewModel
    }()
    
    /// Zoom up
    /// Zoom up.
    func zoomUp() {
        zoomLevel = zoomLevel + 1
    }
    
    /// Zoom down
    /// Zoom down.
    func zoomDown() {
        zoomLevel = zoomLevel - 1
    }
    
    /// Did select.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// Handles when did select.
    func didSelect(itinerary: OTPItinerary) {
        // TODO: show on map
    }
}

