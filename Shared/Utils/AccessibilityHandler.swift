//
//  AccessibilityHandler.swift
//

import SwiftUI

extension View {
    /// Add accessibility.
    /// - Parameters:
    ///   - text: Parameter description
    /// - Returns: some View
    /// Adds accessibility.
    public func addAccessibility(text:String) -> some View {
        self.accessibilityElement().accessibility(label: Text(text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
    }
    
    /// Add tab accessibility.
    /// - Parameters:
    ///   - tab: Parameter description
    /// - Returns: some View
    func addTabAccessibility(tab: TabBarItem) -> some View{
        var label = ""
        switch tab.type{
        case .planTrip:
            label = AvailableAccessibilityItem.planTripTab.rawValue.localized()
        case .routes:
            label = AvailableAccessibilityItem.routesTab.rawValue.localized()
        case .stops:
            label = AvailableAccessibilityItem.stopsTab.rawValue
        case .signIn:
            label = AvailableAccessibilityItem.signInTab.rawValue.localized()
        case .user:
            label = AvailableAccessibilityItem.userTab.rawValue.localized()
        case .myTrips:
            label = AvailableAccessibilityItem.myTripsTab.rawValue.localized()
        case .currentStop:
            label = AvailableAccessibilityItem.myTripsTab.rawValue.localized()
        case .menu:
            label = AvailableAccessibilityItem.menuTab.rawValue.localized()
        }
        
        return self.accessibilityElement().accessibility(label: Text(label).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
    }
    
    /// Available accessibility.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    public func availableAccessibility(_ view: AvailableAccessibilityItem) -> some View{
        let hidden = AccessibilityHandler.shared.hideAccessibility(view)
        return self.accessibility(hidden: hidden)
    }
}

public class AccessibilityHandler {
    
    /// Shared.
    /// - Parameters:
    ///   - AccessibilityHandler: Parameter description
    public static var shared: AccessibilityHandler = {
        var shared = AccessibilityHandler()
        return shared
    }()
        
    /// Mapping accessibility result.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: [AvailableAccessibilityItem: Bool]
    private static func mappingAccessibilityResult(_ accessibilityItems: [AvailableAccessibilityItem]) -> [AvailableAccessibilityItem: Bool] {
        var mappingResult = [AvailableAccessibilityItem: Bool]()
        for item in accessibilityItems {
            mappingResult[item] = true
        }
        return mappingResult
    }
    
    let planTripContainer = AccessibilityHandler.mappingAccessibilityResult([.mapView, .searchBarView, .mapLayerButton, .locateMe, .bottomSildingUpContainer])
    let tripItinerariesContainer = AccessibilityHandler.mappingAccessibilityResult([.searchBarView, .bottomSildingUpContainer])
    let searchPageContainer = AccessibilityHandler.mappingAccessibilityResult([.searchBarView ,.routesSearchBar, .routesListView])
    let stopViewerContainer = AccessibilityHandler.mappingAccessibilityResult([.backButton, .searchBarView])
    
    /// Hide accessibility.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func hideAccessibility(_ currentPage: AvailableAccessibilityItem ) -> Bool
    {
        if AutoCompleteManager.shared.pubOpenPage{
            return searchPageContainer[currentPage] ?? false
        }
        
        if StopViewerViewModel.shared.pubIsShowingStopViewer{
            return stopViewerContainer[currentPage] ?? false
        }
        return false
    }
}


public enum AvailableAccessibilityItem : String{
    case backButton = "Back button, double tap to go back"
    case mapLayerButton = "map settings, double tap to activate"
    case locateMe = "Locate Me, Double tap to activate"
    case switchAddress = "Switch Origin and Destination Button, Double tap to activate"
    case busButton = "Bus Button, Double tap to activate"
    case walkButton = "Walk Button, Double tap to activate"
    case carButton = "Car Button, Double tap to activate"
    case bicycleButton = "Bicycle Button, Double tap to activate"
    case rentalButton = "Rentals Button, Double tap to activate"
    case settingsButton = "Settings Button, Double tap to activate"
    case expandButton = "Expand Search Bar Button, Double tap to activate"
    case detailsButton = "Details Button, Double tap to activate"
    case collapseButton = "Collapse Button, Double tap to activate"

    
    case tabBar = "Tab Bar"
    case planTripTab = "Plan Trip button, Double tap to activate"
    case routesTab = "Routes button, Double tap to activate"
    case stopsTab = "Stops button, Double tap to activate"
    case myTripsTab = "My Trip button, Double tap to activate"
    case myProfileTab = "My Profile button, Double tap to activate"
    case signInTab = "Sign In button, Double tap to activate"
    case userTab = "User Profile button, Double tap to activate"
    case menuTab = "Menu button, Double tap to activate"
    case blackAreaMenu = "Double tap to dismiss the side menu panel or swipe to select menu items"
    
    case mapView = "Map View"
    case mapLayerView = "Map Layer View"
    case itinerariesView = "Itineraries View"
    case itineraryDetailsView = "Itinerary Details View"
    case searchBarView = "Search Bar View"
    case bottomSildingUpContainer = "Bottom Sliding Up Container"
    
    case clearSearchTextButton = "Clear button, double tap to clear searched location"
    
    //Home View
    
    case searchRouteTextField = "Find A Route text field"
    case settingButton = "Setting Button, Double tap to activate"
    case filterButton = "Select modes of transportation"
    case resetButton = "Reset Button, Double tap to activate"
    case planTripButton = "Plan trip"
    case favouriteButton = "Save the Route Button, Double tap to activate"
    case blackAreaFliter = "Double tap to dismiss the transportation mode selector or swipe to select modes of transportation"
    case tripDetailsView = "Trip Details View"
    
    // Route View
    
    case agencyFilter = "Agency Filter Button, Double tap to activate"
    case modeFilter = "Mode Filter Button, Double tap to activate"
    case routesSearchBar = "Search Route"
    case routesListView = "Routes List"
    
    // My Trip
    case cancelButton = "Cancel Button, Double tap to activate"
    case savePreferencesButton = "Save Preferences Button, Double tap to activate"
    case resumeButton = "Resume Saved Trip Button, Double tap to activate"
    case pauseButton = "Pause Saved Trip Button, Double tap to activate"
    case pauseUntilResumedButton = "Pause Saved Trip Until Resumed Button, Double tap to activate"
    case editButton = "Edit Button, Double tap to activate"
    case liveTrackingButton = "Live Tracking Button, Double tap to activate"
    case previewButton = "Preview Button, Double tap to activate"
    case deleteButton = "Delete Button, Double tap to activate"
    case snoozeButton = "Pause for the rest of the day Button, Double tap to activate"
    case unSnoozeButton = "Resume trip analysis Button, Double tap to activate"
    
    // Stop Viewer
    case stopViewerButton = "Stop Viewer Button, Double Tap to Open Stop Viewer"
    case stopViewerBottmView = "Stop Viewer Bottom View"
    case fromHereButton = "From here button, Double Tap to Open"
    case toHereButton = "To here button, Double Tap to Open"
    case autoRefreshButton = " Auto refresh Button, Double tap to refresh departure times"
    case departureExpandButton = "button, Double tap to expand details of departures"
    case departureCollapsButton = "button, Double tap to collapse details of departures"
    
    // Trip Viewer
    case tripViewerButton = "Trip Viewer Button, Double Tap to Open Trip Viewer"
    
    // Login Viewer
    case emailTextField = "Enter email text field"
    case passwordTextField = "Enter password text field"
    case showPasswordButton = "Reveal password button"
    
    // User profile Viewer
    case AddAnotherPlaceButton = "Add another place button, double tap to activate"
    case enterLocationTextfield = "Enter location textfield, double tap to activate"
    case searchForLocationTextField = "Search for location textfield"
    case setPlaceNameTextField = "Set place name textfield"
    case saveButton = "Save Button, Double tap to activate"
    
    // Save favourite place
    case LocationTypeAddressSelected = "Location type, Address is selected"
    case LocationTypeAddressNotSelected = "Location type, Address, Double tap to select"
    case LocationTypeDineInSelected = "Location type, Dine In is selected"
    case LocationTypeDineInNotSelected = "Location type, Dine In, Double tap to select"
    
    // Map Layer View
    case mapLayerViewCloseButton = "Map layer view close button, Double tap to close"
    
    // General
    case closeButton = "Close Button, Double tap to activate"

}

