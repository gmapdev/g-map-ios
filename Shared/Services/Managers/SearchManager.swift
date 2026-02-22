//
//  SearchManager.swift
//

import Foundation
import SwiftUI

/// Represents a filter configuration combining primary and secondary transit modes.
///
/// Filters allow users to specify which transit modes they want to use for trip planning.
/// Primary modes are always enabled, while secondary modes can be toggled on/off.
///
/// Example:
/// ```swift
/// let filter = Filter(
///     primary: [busMode, railMode],
///     secondary: [ferryMode, bikeMode]
/// )
/// ```
struct Filter {
	/// Primary transit modes (always enabled)
	let primary: [SearchMode]

	/// Secondary transit modes (can be toggled)
	var secondary: [SearchMode]
}

/// Trip planning criteria and preferences.
///
/// Defines user preferences for trip planning including:
/// - Walking distance limits
/// - Walking speed
/// - Optimization preferences (fastest, fewest transfers, etc.)
/// - Accessibility requirements
/// - Bike/scooter rental options
///
/// Example:
/// ```swift
/// let criteria = Criterias(
///     maximumWalk: "0.5",
///     walkSpeed: 3,
///     optimize: "QUICK",
///     avoidWalking: false,
///     accessibleRouting: true,
///     allowBikeRental: false,
///     allowScooterRental: false
/// )
/// ```
public struct Criterias {
	/// Maximum walking distance in miles (e.g., "0.5", "1.0")
	var maximumWalk: String

	/// Walking speed level (1=slow, 2=normal, 3=fast)
	var walkSpeed: Int

	/// Optimization preference ("QUICK", "SAFE", "FLAT", "TRANSFERS")
	var optimize: String

	/// Whether to avoid walking when possible
    var avoidWalking: Bool?

	/// Whether to use wheelchair-accessible routes only
    var accessibleRouting: Bool?

	/// Whether to allow bike rental in trip plans
    var allowBikeRental: Bool?

	/// Whether to allow scooter rental in trip plans
    var allowScooterRental: Bool?

	/// Compares two criteria for equality (basic properties only)
	static func == (lhs: Criterias, rhs: Criterias) -> Bool {
		return lhs.maximumWalk == rhs.maximumWalk && lhs.walkSpeed == rhs.walkSpeed && lhs.optimize == rhs.optimize
	}

	/// Checks if two criteria are different
	static func != (lhs: Criterias, rhs: Criterias) -> Bool {
		return lhs.maximumWalk != rhs.maximumWalk || lhs.walkSpeed != rhs.walkSpeed || lhs.optimize != rhs.optimize
	}
}

/// Available options for trip planning criteria.
///
/// Defines the possible values users can select for each criteria type.
/// Used to populate UI pickers and validate user input.
///
/// Example:
/// ```swift
/// let data = CriteriasData(
///     maximumWalk: ["0.25", "0.5", "1.0", "2.0"],
///     walkSpeed: [[1: 2.5], [2: 3.5], [3: 4.5]], // mph
///     optimize: ["QUICK", "SAFE", "FLAT", "TRANSFERS"]
/// )
/// ```
public struct CriteriasData {
	/// Available maximum walk distance options (in miles)
	var maximumWalk: [String]

	/// Available walk speed options (level -> mph mapping)
    var walkSpeed: [[Int : Double]]

	/// Available optimization options
	var optimize: [String]
}

/// Date and time settings for trip planning.
///
/// Allows users to specify when they want to travel:
/// - Depart at a specific time
/// - Arrive by a specific time
/// - Use current time
///
/// Example:
/// ```swift
/// var settings = DateSettings()
/// settings.departAt = Date().addingTimeInterval(3600) // 1 hour from now
/// ```
public struct DateSettings: Codable {
	/// Departure time (if user wants to depart at a specific time)
	var departAt: Date?

	/// Arrival time (if user wants to arrive by a specific time)
	var arriveBy: Date?

	/// Generic time field (used for current time or custom time)
    var time: Date?
}

/// Manages trip search state and user preferences.
///
/// SearchManager is the central coordinator for trip planning, maintaining:
/// - Origin and destination locations
/// - User preferences (walking distance, speed, optimization)
/// - Date/time settings
/// - Selected transit modes
///
/// This singleton is used throughout the app to maintain consistent search
/// state across different views and screens.
///
/// Example:
/// ```swift
/// let manager = SearchManager.shared
/// manager.from = originLocation
/// manager.to = destinationLocation
/// manager.userCriterias.maximumWalk = "1.0"
/// manager.selectedModes = [busMode, railMode]
/// ```
class SearchManager: ObservableObject {

	/// Origin location for trip planning
	public var from: Autocomplete.Feature?

	/// Destination location for trip planning
	public var to: Autocomplete.Feature?

	/// User's trip planning preferences
	public var userCriterias: Criterias = FeatureConfig.shared.defaultCriterias

	/// Date and time settings for the trip
	public var dateSettings: DateSettings = DateSettings()

	/// Selected transit modes for trip planning
	public var selectedModes: [SearchMode] = []

	/// Shared singleton instance of SearchManager.
	///
	/// Use this instance throughout the app to maintain consistent search state.
	public static var shared: SearchManager = {
		let mgr = SearchManager()
		return mgr
	}()

	/// Swaps the origin and destination locations.
	///
	/// This convenience method allows users to quickly reverse their trip
	/// direction by swapping the from and to locations.
	///
	/// Example:
	/// ```swift
	/// // Before: from=Home, to=Work
	/// SearchManager.shared.switchFromAndTo()
	/// // After: from=Work, to=Home
	/// ```
	func switchFromAndTo(){
		let newTo = from
		from = to
		to = newTo
	}
}
