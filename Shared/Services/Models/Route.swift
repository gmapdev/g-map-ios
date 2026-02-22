//
//  Route.swift
//

import Foundation

/// Represents a transit route with all associated metadata.
///
/// A TransitRoute contains comprehensive information about a public transit route including:
/// - Route identification (ID, short name, long name)
/// - Visual styling (color, text color)
/// - Agency information
/// - Route patterns and stops
/// - Accessibility features (bikes allowed)
/// - Transit mode (bus, rail, ferry, etc.)
///
/// Routes are used throughout the app for:
/// - Displaying route information in the route viewer
/// - Trip planning and itinerary display
/// - Real-time vehicle tracking
/// - Map visualization with route colors
///
/// Example:
/// ```swift
/// let route = TransitRoute(
///     id: "metro:1",
///     agency: Agency(id: "metro", name: "Metro Transit"),
///     shortName: "1",
///     longName: "Downtown - University",
///     type: 3, // Bus
///     color: "#0000FF",
///     textColor: "#FFFFFF",
///     mode: .bus
/// )
/// ```
public struct TransitRoute: Codable, Equatable{
    /// Unique identifier for the route (format: "agency:routeId")
    let id: String

    /// Transit agency operating this route
    var agency: Agency?

    /// Short route name displayed to riders (e.g., "1", "A", "Red Line")
    let shortName, longName: String?

    /// GTFS route type (0=Tram, 1=Subway, 2=Rail, 3=Bus, 4=Ferry, etc.)
    let type: Int?

    /// Hex color code for route visualization (e.g., "#FF0000")
    let color, textColor: String?

    /// Whether route has eligibility restrictions (1=restricted, 0=unrestricted)
    let eligibilityRestricted: Int?

    /// Bike accessibility flags
    let routeBikesAllowed, bikesAllowed : String?

    /// Whether a custom sort order has been set
    let sortOrderSet: Bool?

    /// Custom sort order for route display (lower numbers appear first)
    var sortOrder: Int? = 0

    /// Name of the operating agency
    var agencyName: String?

    /// Agency identifier
    let agencyId: String?

    /// URL for route information
    let url: String?

    /// Transit mode (bus, rail, ferry, etc.)
    var mode: Mode?

    /// Route description
    let desc: String?

    /// Resolves the SearchMode configuration for this route's mode.
    ///
    /// This computed property looks up the route's mode in the global mode list
    /// to get display properties like icons, colors, and labels. Falls back to
    /// a default bus mode if the mode is not found.
    ///
    /// - Returns: SearchMode configuration for this route, or default bus mode
    var searchMode : SearchMode? {
        if let mode = self.mode{
            let allModesList = FeatureConfig.shared.allModesList
            if let searchMode = allModesList.first(where: { $0.mode == mode.rawValue}){
                return searchMode
            } else {
                OTPLog.log(info: "Didn't find Mode Value- \(mode.rawValue) in our Generic Mode List")
                return allModesList.count > 0 ? allModesList.first! : SearchMode(mode: "BUS", label: "Bus", mode_image: "ic_bus", marker_image: "ic_marker_bus", line_color: "#7da8ef", color: "#e05522")
            }
        }
        return nil
    }

	/// Pattern ID used for drawing the route line in the stop viewer
	let patternId: String?

    /// Array of route patterns (different paths the route can take)
    let patterns: [RoutePattern]?

    // MARK: - Equatable Implementation
    /// Compares two TransitRoute instances for equality.
    ///
    /// Routes are equal if all their properties match, including ID, agency,
    /// names, colors, patterns, and metadata.
        public static func == (lhs: TransitRoute, rhs: TransitRoute) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.agency == rhs.agency &&
                   lhs.shortName == rhs.shortName &&
                   lhs.longName == rhs.longName &&
                   lhs.type == rhs.type &&
                   lhs.color == rhs.color &&
                   lhs.textColor == rhs.textColor &&
                   lhs.eligibilityRestricted == rhs.eligibilityRestricted &&
                   lhs.routeBikesAllowed == rhs.routeBikesAllowed &&
                   lhs.bikesAllowed == rhs.bikesAllowed &&
                   lhs.sortOrderSet == rhs.sortOrderSet &&
                   lhs.sortOrder == rhs.sortOrder &&
                   lhs.agencyName == rhs.agencyName &&
                   lhs.agencyId == rhs.agencyId &&
                   lhs.url == rhs.url &&
                   lhs.mode == rhs.mode &&
                   lhs.desc == rhs.desc &&
                   lhs.patternId == rhs.patternId &&
                   lhs.patterns == rhs.patterns
        }
}

/// Represents a specific pattern (path) that a route can take.
///
/// A RoutePattern defines one possible path a route takes, including:
/// - The sequence of stops served
/// - The geographic path (encoded polyline)
/// - The destination headsign
///
/// Routes often have multiple patterns for different directions or variations
/// (e.g., "Downtown" vs "Uptown", or express vs local service).
///
/// Example:
/// ```swift
/// let pattern = RoutePattern(
///     id: "metro:1:pattern1",
///     headsign: "Downtown",
///     name: "Route 1 to Downtown",
///     patternGeometry: PatternGeometry(points: "encodedPolyline"),
///     stops: [stop1, stop2, stop3]
/// )
/// ```
struct RoutePattern: Codable, Equatable {
    /// Compares two patterns for equality based on all properties
    static func == (lhs: RoutePattern, rhs: RoutePattern) -> Bool {
        return lhs.id == rhs.id && lhs.headsign == rhs.headsign && lhs.name == rhs.name && lhs.patternGeometry == rhs.patternGeometry && lhs.stops == rhs.stops
    }

    /// Unique identifier for this pattern
    let id: String

    /// Destination headsign shown to riders (e.g., "Downtown", "Airport")
    let headsign: String?

    /// Full pattern name
    let name: String?

    /// Encoded geographic path of the route
    let patternGeometry: PatternGeometry?

    /// Ordered list of stops served by this pattern
    let stops: [Stop]?

}

/// Represents the geographic path of a route pattern.
///
/// Contains an encoded polyline string representing the route's path on the map.
/// The polyline is typically encoded using Google's polyline encoding algorithm
/// for efficient storage and transmission.
///
/// Example:
/// ```swift
/// let geometry = PatternGeometry(points: "_p~iF~ps|U_ulLnnqC_mqNvxq`@")
/// // Decode this string to get lat/lon coordinates for map display
/// ```
struct PatternGeometry: Codable, Equatable {
    /// Encoded polyline string representing the route path
    let points: String?
    let length: Int?
}
extension Array where Element == TransitRoute {
    /// Apply sort
    /// - Returns: [TransitRoute]
    /// Applies sort.

    /// - Returns: [TransitRoute]
    func applySort() -> [TransitRoute] {
        /*
         TODO: implement the same algorithm as on web.
         Line: 393 - 403
         https://github.com/opentripplanner/otp-ui/blob/master/packages/core-utils/src/route.js#L393-L403
         */
        return self
    }
}

struct RealTimeBus: Codable {
    
    let vehicleId: String
    let label: String
    let lat: Double
    let lon: Double
    let speed: Double
    let heading: Double
    let seconds: Double
    let patternId: String
    let mode: SearchMode?
}


