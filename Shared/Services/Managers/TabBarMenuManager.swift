//
//  TabBarMenuManager.swift
//

import Foundation
import SwiftUI

/// Manages the tab bar state, navigation, and user interactions across the application.
/// This singleton class handles tab switching logic, maintains current/previous tab states,
/// and coordinates with other managers (MapManager, StopViewerViewModel, etc.) to ensure
/// proper UI state when navigating between tabs.
@MainActor
class TabBarMenuManager: ObservableObject {

	// MARK: - Published Properties

	/// The currently displayed view tab (e.g., .planTrip, .routes, .myTrips)
	@Published var currentViewTab: TabBarItemType = .planTrip

	/// The currently selected tab bar item (may differ from currentViewTab for overlays)
	@Published var currentItemTab: TabBarItemType = .planTrip

	/// The previously displayed view tab, used for navigation back operations
	@Published var previousViewTab: TabBarItemType = .planTrip

	/// The previously selected tab bar item, used for restoring state
	@Published var previousItemTab: TabBarItemType = .planTrip

	/// Controls visibility of the profile popup menu
	@Published var pubShowProfilePopUp: Bool = false

	/// Controls visibility of the tabs popup menu (used in AODA mode)
	@Published var pubShowTabsPopUp: Bool = false

	/// The currently selected tab item object, used for UI rendering
	@Published var seletedTab: TabBarItem = TabBarItem(type: .planTrip)
    
    @Published var pubSelectedTabMenuItem: TabBarMenuItem = TabBarMenuItem(type: .planTrip, action: {})

	/// Array of available tabs to display, dynamically configured based on login state
	@Published var availableTabs: [TabBarMenuItem] = []

	/// Counter to force UI refresh when tab selection changes
	@Published var refreshCounter: Int = 0

	// MARK: - Singleton

	/// Shared singleton instance of TabBarMenuManager
	public static let shared: TabBarMenuManager = {
		let mgr = TabBarMenuManager()
		mgr.initializeDefaultTabs()
		return mgr
	}()

	// MARK: - Tab Configuration

	/// Initializes default tabs for logged out state.
	/// Called during singleton initialization to ensure tabs are always available.
	private func initializeDefaultTabs() {
		configureTabs(isLoggedIn: false)
		// Set default selection to Plan Trip
		selectTab(.planTrip)
	}

	/// Configures the available tabs based on user authentication state.
	/// When logged in, shows Plan Trip, Routes, My Trips, and User Profile tabs.
	/// When logged out, shows Plan Trip, Routes, and Sign In tabs.
	/// - Parameter isLoggedIn: Boolean indicating if user is authenticated
	func configureTabs(isLoggedIn: Bool) {
		var tabs: [TabBarMenuItem] = []

		// Plan Trip tab - always available
		tabs.append(TabBarMenuItem(
			type: .planTrip,
			action: { [weak self] in
				self?.handlePlanTripTap()
			}
		))

		// Routes tab - always available
		tabs.append(TabBarMenuItem(
			type: .routes,
			action: { [weak self] in
				self?.handleRoutesTap()
			}
		))

		// Conditional tabs based on authentication
		if isLoggedIn {
			// My Trips tab - only for logged in users
			tabs.append(TabBarMenuItem(
				type: .myTrips,
				action: { [weak self] in
					self?.handleMyTripsTap()
				}
			))

			// User Profile tab - only for logged in users
			tabs.append(TabBarMenuItem(
				type: .user,
				action: { [weak self] in
					self?.handleUserTap()
				}
			))
		} else {
			// Sign In tab - only for logged out users
			tabs.append(TabBarMenuItem(
				type: .signIn,
				action: { [weak self] in
					self?.handleSignInTap()
				}
			))
		}

		self.availableTabs = tabs

		// Increment counter to force SwiftUI refresh when tabs change
		refreshCounter += 1
	}

	// MARK: - Tab Selection

	/// Selects a tab and triggers UI refresh
	/// - Parameter type: The tab type to select
	func selectTab(_ type: TabBarItemType) {
		currentItemTab = type
		seletedTab = TabBarItem(type: type)
        setSelectedMenuItem(type: type)
		// Increment counter to force SwiftUI refresh
		refreshCounter += 1
	}

    func setSelectedMenuItem(type: TabBarItemType) {
        if let currentMenuItem = self.availableTabs.first(where: { $0.type == type }) {
            pubSelectedTabMenuItem = currentMenuItem
        } else{
            pubSelectedTabMenuItem = TabBarMenuItem(type: .planTrip, action: self.handlePlanTripTap)
        }
        
    }
    
	/// Checks if a tab is currently selected
	/// - Parameter type: The tab type to check
	/// - Returns: True if the tab is selected
	func isTabSelected(_ type: TabBarItemType) -> Bool {
		return currentItemTab == type
	}

	// MARK: - Tab Actions

	/// Handles tap on Plan Trip tab.
	/// Resets UI state, closes popups, hides stop viewer, and either redraws the route
	/// if in trip planning mode or cleans the map and redraws from/to markers.
	private func handlePlanTripTap() {
		// Reset bottom slide bar position
		BottomSlideBarViewModel.shared.lastOffset = 0

		// Close any open popups
		pubShowProfilePopUp = false

		// Hide stop viewer and reset its state
		StopViewerViewModel.shared.pubIsShowingStopViewer = false
		StopViewerViewModel.shared.pubKeepShowingStopViewer = false

		// Update previous tab tracking
		previousViewTab = .planTrip
		previousItemTab = .planTrip

		// Close map settings if open
		MapManager.shared.isMapSettings = false

		// Restore stop viewer if it should remain visible
		StopViewerViewModel.shared.pubIsShowingStopViewer = StopViewerViewModel.shared.pubKeepShowingStopViewer

		// Handle map state based on current mode
		if MapManager.shared.pubIsInTripPlan {
			// In trip planning mode: force clean and redraw route
			MapManager.shared.forceCleanMapReDrawRoute()
		} else {
			// Normal mode: clean route and redraw markers
			MapManager.shared.cleanPlotRoute()
			MapManager.shared.reDrawFromToMarkers()
		}

		// Set current tab state and trigger refresh
		currentViewTab = .planTrip
		selectTab(.planTrip)
	}

	/// Handles tap on Routes tab.
	/// Resets UI state, deselects all map annotations, cleans the map,
	/// and removes autocomplete suggestions.
	private func handleRoutesTap() {
		// Reset bottom slide bar position
		BottomSlideBarViewModel.shared.lastOffset = 0

		// Close any open popups
		pubShowProfilePopUp = false

		// Update previous tab tracking
		previousViewTab = .routes
		previousItemTab = .routes

		// Only perform cleanup if switching from a different view
		if currentViewTab != .routes {
			// Deselect all map annotations
			if let annotationsInMap = MapManager.shared.mapView.annotations {
				for annotation in annotationsInMap {
					MapManager.shared.mapView.deselectAnnotation(annotation, animated: false)
				}
			}

			// Close map settings if open
			MapManager.shared.isMapSettings = false

			// Clean any plotted routes
			MapManager.shared.cleanPlotRoute()

			// Remove all map annotations
			if let annotations = MapManager.shared.mapView.annotations {
				MapManager.shared.mapView.removeAnnotations(annotations)
			}

			// Clear autocomplete suggestions
			AutoCompleteManager.shared.pubFilteredItems.removeAll()
		}

		// Set current tab state and trigger refresh
		currentViewTab = .routes
		selectTab(.routes)
	}

	/// Handles tap on My Trips tab.
	/// Simply switches to the My Trips view without additional cleanup.
	private func handleMyTripsTap() {
		currentViewTab = .myTrips
		selectTab(.myTrips)
	}

	/// Handles tap on User Profile tab.
	/// Shows/hides profile popup, cleans map annotations (except tap-selected markers),
	/// and manages navigation state. If already on user tab, returns to previous view.
	private func handleUserTap() {
		// Initially close popup (will be reopened if needed)
		pubShowProfilePopUp = false

		// If coming from My Trips, set previous tab to Plan Trip
		if currentViewTab == .myTrips {
			previousViewTab = .planTrip
			previousItemTab = .planTrip
		}

		// If already on user tab in plan trip view, close popup and return to previous view
		if currentViewTab == .planTrip && currentItemTab == .user {
			pubShowProfilePopUp = false
			currentViewTab = previousViewTab
			selectTab(previousItemTab)
			return
		}

		// Show profile popup
		pubShowProfilePopUp = true

		// Clean any plotted routes
		MapManager.shared.cleanPlotRoute()

		// Remove all annotations except tap-selected markers
		if let annotations = MapManager.shared.mapView.annotations {
			var removeAnnotations = [MGLGeneralAnnotation]()
			for annotation in annotations {
				if let anno = annotation as? MGLGeneralAnnotation, anno.markerType != .tapSelectedMarker {
					removeAnnotations.append(anno)
				}
			}
			MapManager.shared.mapView.removeAnnotations(removeAnnotations)
		}

		// Redraw from/to markers
		MapManager.shared.reDrawFromToMarkers()

		// Set to plan trip view with user item selected
		currentViewTab = .planTrip
		selectTab(.user)
	}

	/// Handles tap on Sign In tab.
	/// Opens login page, cleans map annotations (except tap-selected markers),
	/// and returns to the previous view state.
	private func handleSignInTap() {
		// Open login page
		LoginFlowManager.shared.pubPresentLoginPage = true

		// Close any open popups
		pubShowProfilePopUp = false

		// Clean any plotted routes
		MapManager.shared.cleanPlotRoute()

		// Remove all annotations except tap-selected markers
		if let annotations = MapManager.shared.mapView.annotations {
			var removeAnnotations = [MGLGeneralAnnotation]()
			for annotation in annotations {
				if let anno = annotation as? MGLGeneralAnnotation, anno.markerType != .tapSelectedMarker {
					removeAnnotations.append(anno)
				}
			}
			MapManager.shared.mapView.removeAnnotations(removeAnnotations)
		}

		// Redraw from/to markers
		MapManager.shared.reDrawFromToMarkers()

		// Return to previous view state
		currentViewTab = previousViewTab
		selectTab(previousItemTab)
	}

	// MARK: - Helper Methods

	/// Programmatically switches to a specific tab by executing its action.
	/// Useful for navigation triggered by code rather than user tap.
	/// - Parameter type: The tab type to switch to
	func switchToTab(_ type: TabBarItemType) {
		if let tab = availableTabs.first(where: { $0.type == type }) {
			tab.action()
		}
	}
}

// MARK: - Tab Bar Menu Item

/// Represents a single tab bar menu item with its type and associated action.
/// Used to dynamically configure the tab bar based on application state.
struct TabBarMenuItem: Identifiable, Equatable {
	/// Unique identifier for the tab item
	let id = UUID()

	/// The type of tab (e.g., .planTrip, .routes, .myTrips)
	let type: TabBarItemType

	/// The action to execute when this tab is tapped
	let action: () -> Void

	/// Equatable conformance - compares based on type only
	static func == (lhs: TabBarMenuItem, rhs: TabBarMenuItem) -> Bool {
		return lhs.type == rhs.type
	}
}
