//
//  SearchLocationViewModel.swift
//

import Combine
import SwiftUI
import Mapbox

struct SearchLocationItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    let feature: Autocomplete.Feature
}

extension SearchLocationItem {
    /// Name.
    /// - Parameters:
    ///   - String: Parameter description
    var name: String {
        feature.properties.label
    }
}

class SearchLocationViewModel: ObservableObject, AutocompleteService {
    var service: APIServiceProtocol = APIService()
    private var cancellableSet = Set<AnyCancellable>()
    
    @Published var pubSavedHomeAddress: FavouriteLocation?
    @Published var pubSavedWorkAddress: FavouriteLocation?
    @Published var locations: [SearchLocationItem] = []
    @Published var searchedSavedLocations: [FavouriteLocation] = []
    @Published var recentLocations: [SearchLocationItem] = []
    /// Search text.
    /// - Parameters:
    ///   - String: Parameter description
    @Published var searchText: String = "" {
        didSet {
            searchSavedLocations()
            getLocations()
        }
    }
	
	public var firstIgnore = true
	public var firstIngoreTimer: Timer?
    
    public static let shared: SearchLocationViewModel = {
        let model = SearchLocationViewModel()
        model.getRecentLocations()
        if let _ = AppSession.shared.loginInfo{
            model.retrieveSavedLocations()
        }
        return model
    }()
	
    /// Get recent locations
    /// Retrieves recent locations.
    func getRecentLocations(){
        self.recentLocations = DefaultsHelper.getRecentLocations()
    }
    
    /// Retrieve saved locations
    /// Retrieve saved locations.
    func retrieveSavedLocations(){
        AppSession.shared.loginInfo?.savedLocations?.forEach({ location in
            if location.type == "home"{
                self.pubSavedHomeAddress = location
            }
            else if location.type == "work"{
                self.pubSavedWorkAddress = location
            }
        })

    }
    
    /// Saves feature.
    func saveFeature(_ feature: Autocomplete.Feature,
                     isRecent: Bool = false) {
        if !isRecent {
            DefaultsHelper.saveRecent(feature: feature)
        }
    }
    
    /// Get locations
    /// Retrieves locations.
    func getLocations() {
        cancellableSet.removeAll()
        guard !searchText.isEmpty else {
            locations = []
            return
        }
        let cancellable = locations(for: searchText,  boundary: BrandConfig.shared.boundary)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Handle error: \(error)")
                case .finished:
                    break
                }

            }) { [weak self] (response) in
                self?.locations = response.features.map( { SearchLocationItem(feature: $0) })
        }
        cancellableSet.insert(cancellable)
    }
    
    /// Search saved locations
    /// Searches saved locations.
    func searchSavedLocations(){
        searchedSavedLocations.removeAll()
        var savedLocations = [FavouriteLocation]()
        if AppSession.shared.loginInfo != nil {
            if let locations = AppSession.shared.loginInfo?.savedLocations {
                savedLocations = locations
            }
            let filteredLocation = savedLocations.filter({ $0.name.lowercased().contains(searchText.lowercased()) || $0.address.contains(searchText.lowercased().lowercased())  })
            savedLocations = filteredLocation
            
        }
        searchedSavedLocations = savedLocations
    }
    
    /// Get stop locations
    /// - Returns: [SearchLocationItem]
    /// Retrieves stop locations.
    func getStopLocations() -> [SearchLocationItem]{
        if locations.count > 0 {
            let stops = locations.filter({$0.feature.properties.layer == AutoCompleteItemType.stopLocation.rawValue})
            if !stops.isEmpty {
                if stops.count > 10 {
                    return Array(stops.prefix(10))
                } else {
                    return stops
                }
            }
        }
        return []
    }
    
    /// Get other locations
    /// - Returns: [SearchLocationItem]
    /// Retrieves other locations.
    func getOtherLocations() -> [SearchLocationItem]{
        if locations.count > 0 { 
            let otherLocations = locations.filter({$0.feature.properties.layer != AutoCompleteItemType.stopLocation.rawValue})
            return otherLocations
        }
        return []
    }
    
}
