//
//  TabBarItem.swift
//

import Foundation
import SwiftUI

/// Represents a single tab bar item with its type and optional tap action.
/// Used for legacy tab bar implementation (now replaced by TabBarMenuManager).
struct TabBarItem: Identifiable, Equatable {
	/// Unique identifier for the tab item
	let id = UUID()

	/// The type of tab (e.g., .planTrip, .routes, .myTrips)
	var type: TabBarItemType

	/// Optional callback when tab is tapped. Returns tuple of (viewType, itemType) to navigate to.
	/// First type is for the view to display, second type is for the item to select.
	var onTapped: (() -> (TabBarItemType?, TabBarItemType?))?

	/// Compares two tab items for equality based on their type.
	/// - Parameters:
	///   - lhs: Left-hand side tab item
	///   - rhs: Right-hand side tab item
	/// - Returns: True if both items have the same type
	static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
		return lhs.type == rhs.type
	}

	/// Initializes a tab bar item with a type and optional tap handler.
	/// - Parameters:
	///   - type: The tab type
	///   - onTapped: Optional closure to execute when tab is tapped
	init(type: TabBarItemType, onTapped: (() -> (TabBarItemType?, TabBarItemType?))? = nil) {
		self.type = type
		self.onTapped = onTapped
	}
}

/// Defines all possible tab bar item types in the application.
/// Each type has associated icon, title, and color properties.
enum TabBarItemType: Hashable {
	case planTrip, routes, stops, signIn, myTrips, user, currentStop, menu

	/// Returns the icon asset name for this tab type.
	var iconName: String {
		switch self {
		case .planTrip: return "ic_plantrip"
		case .routes: return "ic_routes"
		case .stops: return "ic_stops"
		case .signIn: return "ic_signin"
		case .myTrips: return "ic_save"
		case .user: return "ic_signin"
		case .currentStop: return "currentStop"
		case .menu: return "menu_icon"
		}
	}

	/// Returns the localized display title for this tab type.
	/// For user tab, returns the logged-in user's short name if available.
	var title: String {
		switch self{
		case .planTrip: return "Plan trip"
		case .routes: return "Routes"
		case .stops: return "Stops"
		case .signIn: return "Sign In"
		case .myTrips: return "My Trips"
		case .menu: return "Menu"
		case .user:
			if let login = AppSession.shared.loginInfo {
				return login.shortName()
			}
			return ""
		case .currentStop: return "currentStop"
		}
	}

	/// Returns the color to use when this tab is selected.
	/// Currently all tabs use the same red foreground color.
	var color: Color {
		switch self{
		case .planTrip: return Color.redForeground
		case .routes: return Color.redForeground
		case .stops: return Color.redForeground
		case .signIn: return Color.redForeground
		case .myTrips: return Color.redForeground
		case .user : return Color.redForeground
		case .currentStop: return Color.redForeground
		case .menu: return Color.redForeground
		}
	}
}

/// SwiftUI PreferenceKey for collecting tab bar items from child views.
/// Used in legacy modifier-based tab bar implementation.
struct TabBarItemsPreferenceKey: PreferenceKey{
	static var defaultValue: [TabBarItem] = []

	/// Combines tab items from multiple child views by appending them.
	/// - Parameters:
	///   - value: Current accumulated tab items
	///   - nextValue: Closure providing next batch of tab items to add
	static func reduce(value: inout [TabBarItem], nextValue: () -> [TabBarItem]) {
		value += nextValue()
	}
}

/// View modifier that conditionally displays content based on tab selection state.
/// Used in legacy modifier-based tab bar implementation.
struct TabBarItemViewModifier: ViewModifier {
	let tab: TabBarItem
	@Binding var view: TabBarItemType
	@Binding var item: TabBarItemType

	/// Displays content when either the view or item matches this tab's type.
	/// Also sets the preference key to register this tab with the parent container.
	/// - Parameter content: The content to conditionally display
	/// - Returns: Modified view with conditional display logic
	func body(content: Content) -> some View {
		return ZStack{
			// Show content if this is the current view
			if view == tab.type {
				content
			}

			// Show content if this is the current item but not the current view
			if view != tab.type && item == tab.type {
				content
			}
		}
		.preference(key: TabBarItemsPreferenceKey.self, value: [tab])
	}
}

extension View {
	/// Applies tab bar item modifier to a view (legacy implementation).
	/// This modifier registers the view as a tab and conditionally displays it based on tab selection.
	/// Note: This is legacy code, new implementation uses TabBarMenuManager directly.
	/// - Parameters:
	///   - type: The tab type for this view
	///   - view: Binding to the current view tab
	///   - item: Binding to the current item tab
	///   - onTapped: Optional closure to execute when tab is tapped
	/// - Returns: Modified view with tab bar item behavior
	func tabBarItem(type: TabBarItemType,
					view: Binding<TabBarItemType>,
					item: Binding<TabBarItemType>,
					onTapped: (()-> (TabBarItemType?, TabBarItemType?))? = nil) -> some View{
		let tbItem = TabBarItem(type: type, onTapped: onTapped)
		return modifier(TabBarItemViewModifier(tab: tbItem, view: view, item: item))
	}
}
