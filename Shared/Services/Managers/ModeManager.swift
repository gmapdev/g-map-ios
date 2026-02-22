//
//  ModeManager.swift
//

import Foundation

/// Specifies the type of icon to retrieve for a transit mode.
///
/// Used to differentiate between map markers and mode icons in the UI.
enum IconType {
    /// Map marker icon (used for map annotations)
    case marker

    /// Mode icon (used in lists, buttons, and UI elements)
    case mode
}

/// Represents all possible transportation modes in the transit system.
///
/// This enum defines every mode of transportation supported by the app,
/// including public transit, personal vehicles, shared mobility, and walking.
/// Each mode corresponds to a specific GTFS route type or custom mode.
///
/// Mode Categories:
/// - **Public Transit**: bus, tram, ferry, rail, subway, light_rail, etc.
/// - **Personal**: walk, bicycle, car
/// - **Shared Mobility**: bicycle_rent, car_rent, scooter_rent, carpool
/// - **Parking**: bicycle_park, car_park
/// - **Other**: airplane, gondola, funicular, cable_car
///
/// Example:
/// ```swift
/// let mode = Mode.bus
/// print(mode.rawValue) // "BUS"
/// ```
public enum Mode: String, Codable{
    case transit = "TRANSIT"
    case bus = "BUS"
    case walk = "WALK"
    case tram = "TRAM"
    case ferry = "FERRY"
    case rail = "RAIL"
    case streetcar = "STREETCAR"
    case water_taxi = "WATER_TAXI"
    case bicycle = "BICYCLE"
    case bicycle_rent = "BICYCLE_RENT"
    case bicycle_park = "BICYCLE_PARK"
    case car = "CAR"
    case rent = "ST-RENT"
    case subway = "SUBWAY"
    case car_park = "CAR_PARK"
    case car_hail = "Car_HAIL"
    case car_rent = "CAR_RENT"
    case carpool = "CARPOOL"
    case microbility = "MICROMOBILITY"
    case microbility_rent = "MICROMOBILITY_RENT"
    case airplane = "AIRPLANE"
    case gondola = "GONDOLA"
    case funicular = "FUNICULAR"
    case light_rail = "LIGHT_RAIL"
    case monorail = "MONORAIL"
    case link = "LINK"
    case allMode = "All Modes"
    case cableCar = "CABLE_CAR"
    case scooter = "SCOOTER"
    case linkLightRail = "LINK_LIGHT_RAIL"
    case scooter_rent = "SCOOTER_RENT"
}

/// Represents a searchable transit mode with visual styling and configuration.
///
/// SearchMode extends the basic Mode enum with display properties including:
/// - User-facing labels
/// - Icon assets for UI and map markers
/// - Color schemes for route visualization
/// - Selection state for filtering
/// - Sub-mode hierarchies
///
/// SearchModes are loaded from server configuration and used throughout the app
/// for trip planning, filtering, and visualization.
///
/// Example:
/// ```swift
/// let busMode = SearchMode(
///     mode: "BUS",
///     label: "Bus",
///     mode_image: "ic_bus",
///     marker_image: "ic_marker_bus",
///     line_color: "#0000FF",
///     color: "#0000FF",
///     selectedSubModes: nil,
///     isSelected: true
/// )
/// ```
public struct SearchMode: Codable, Equatable, Hashable{
    /// Mode identifier (matches Mode enum raw values)
    var mode: String

    /// User-facing display label
    var label: String

    /// Icon asset name for UI elements
    var mode_image: String

    /// Icon asset name for map markers
    var marker_image: String

    /// Hex color for route lines on map
    var line_color: String

    /// Hex color for UI elements
    var color: String

    /// Sub-modes that can be selected (e.g., bus types, rail lines)
    var selectedSubModes: [SearchMode]?

    /// Whether this mode is currently selected for trip planning
    var isSelected: Bool? = true

    /// Compares two SearchModes for equality based on visual properties
    public static func == (lhs: SearchMode, rhs: SearchMode) -> Bool {
        return lhs.mode == rhs.mode && lhs.label == rhs.label && lhs.mode_image == rhs.mode_image && lhs.marker_image == rhs.marker_image && lhs.line_color == rhs.line_color
        && lhs.color == rhs.color
    }

    /// Checks if two SearchModes are different
    static func != (lhs: SearchMode, rhs: SearchMode) -> Bool {
        return lhs.mode != rhs.mode || lhs.label != rhs.label || lhs.mode_image != rhs.mode_image || lhs.marker_image != rhs.marker_image || lhs.line_color != rhs.line_color
        || lhs.color != rhs.color
    }

    /// Implements Hashable protocol for use in Sets and Dictionary keys.
    ///
    /// Hashes based on the mode identifier only.
    public func hash(into hasher: inout Hasher) {
            hasher.combine(mode)
        }
}

/// Manages transportation mode configurations and icon mappings.
///
/// ModeManager provides centralized management of:
/// - Mode consolidation (grouping similar modes)
/// - Icon resolution for different contexts
/// - Mode combination handling
/// - Agency-specific mode overrides
///
/// The manager works with server-provided mode combinations and applies
/// agency-specific customizations from FeatureConfig.
///
/// Example:
/// ```swift
/// let manager = ModeManager.shared
/// let consolidated = manager.consolidateModes("BUS") // Returns "transit"
/// let icon = manager.getImageIconforSearchRoute(leg: leg, type: .marker)
/// ```
class ModeManager{
    /// Mode combinations fetched from server configuration.
    ///
    /// These define which modes can be combined in trip planning
    /// (e.g., "Walk + Bus", "Bike + Rail").
    var modeCombinations: [ModeCombination]?

    /// Shared singleton instance of ModeManager.
    ///
    /// Use this instance throughout the app for consistent mode handling.
    public static var shared: ModeManager = {
        let mgr = ModeManager()
        return mgr
    }()

    /// Consolidates specific transit modes into broader categories.
    ///
    /// This method groups similar modes together for simplified display and
    /// filtering. For example, all public transit modes (bus, tram, ferry, rail)
    /// are consolidated into "transit".
    ///
    /// Mode Groupings:
    /// - **transit**: bus, tram, ferry, rail, transit, monorail, subway
    /// - **bike**: bicycle
    /// - **bikeshare**: bicycle_rental, bicycle_rent
    /// - **drive**: car
    /// - **driveshare**: carpool
    /// - **walk**: walk
    /// - **scooter**: scooter
    ///
    /// - Parameter mode: The specific mode to consolidate
    /// - Returns: The consolidated group label, or the original mode if no grouping applies
    ///
    /// Example:
    /// ```swift
    /// ModeManager.shared.consolidateModes("BUS") // Returns "transit"
    /// ModeManager.shared.consolidateModes("BICYCLE_RENT") // Returns "bikeshare"
    /// ```
    func consolidateModes(_ mode: String) -> String {
        let transitMode = [Mode.bus.rawValue, Mode.tram.rawValue, Mode.ferry.rawValue, Mode.rail.rawValue, Mode.transit.rawValue, Mode.monorail.rawValue, Mode.subway.rawValue]
        let driveMode = [Mode.car.rawValue]
        let walkMode = [Mode.walk.rawValue]
        let driveShareMode = [Mode.carpool.rawValue]
        let bikeMode = [Mode.bicycle.rawValue]
        let bikeShareMode = ["BICYCLE_RENTAL","BICYCLE_RENT"]
        let scooterMode = ["SCOOTER"]
        if transitMode.contains(mode) { return GroupSectionLabel.transit.rawValue}
        if bikeMode.contains(mode) { return GroupSectionLabel.bike.rawValue}
        if bikeShareMode.contains(mode) {return GroupSectionLabel.bikeshare.rawValue}
        if driveMode.contains(mode) { return GroupSectionLabel.drive.rawValue}
        if driveShareMode.contains(mode) { return GroupSectionLabel.driveshare.rawValue}
        if walkMode.contains(mode) { return GroupSectionLabel.walk.rawValue}
        if scooterMode.contains(mode) { return GroupSectionLabel.scooter.rawValue}
        return mode
    }

    /// Retrieves the appropriate icon for a trip leg in search results.
    ///
    /// This method determines the correct icon to display for a leg based on:
    /// 1. The leg's mode (from SearchMode)
    /// 2. Agency-specific mode overrides (from FeatureConfig)
    /// 3. The requested icon type (marker vs mode)
    ///
    /// Agency overrides allow specific routes to use custom icons that differ
    /// from their default mode icon.
    ///
    /// - Parameters:
    ///   - leg: The trip leg to get an icon for
    ///   - type: The type of icon needed (.marker for map, .mode for UI)
    /// - Returns: The icon asset name
    ///
    /// Example:
    /// ```swift
    /// let markerIcon = ModeManager.shared.getImageIconforSearchRoute(
    ///     leg: busLeg,
    ///     type: .marker
    /// )
    /// // Returns: "ic_marker_bus" or custom override
    /// ```
    func getImageIconforSearchRoute(leg: OTPLeg?,type : IconType = .mode) -> String {
        guard let legItem = leg else {
            return "ic_bus"
        }
        
        var iconName = "ic_bus"
        var modeName = legItem.searchMode?.mode ?? "BUS"
        
        let agencyModeAliases = FeatureConfig.shared.route_mode_overrides
        if let routeId = legItem.route?.gtfsID,
           let aliasDict = agencyModeAliases.first(where: { $0.id == routeId }) {
            modeName = aliasDict.aliase
        }
        
        let mode = TripPlanningManager.shared.getSearchModefromName(mode: modeName)
        if type == .marker{
            iconName = mode.marker_image
        }else{
            iconName = mode.mode_image
        }
        return iconName
    }

    /// Retrieves the appropriate icon for a trip leg in saved trips.
    ///
    /// Similar to `getImageIconforSearchRoute`, but specifically for saved trips
    /// which may use a different route ID format. This method:
    /// 1. Extracts the mode from the leg's SearchMode
    /// 2. Applies agency-specific overrides if configured
    /// 3. Returns the appropriate icon based on type
    ///
    /// - Parameters:
    ///   - leg: The saved trip leg to get an icon for
    ///   - type: The type of icon needed (.marker for map, .mode for UI)
    /// - Returns: The icon asset name
    ///
    /// Example:
    /// ```swift
    /// let icon = ModeManager.shared.getImageIconforSavedTrip(
    ///     leg: savedLeg,
    ///     type: .mode
    /// )
    /// ```
    func getImageIconforSavedTrip(leg: OTPLeg?,type : IconType = .mode) -> String {
        guard let legItem = leg else {
            return "ic_bus"
        }
        
        var iconName = "ic_bus"
        var modeName = legItem.searchMode?.mode ?? "BUS"
        
        let agencyModeAliases = FeatureConfig.shared.route_mode_overrides
        if let route = legItem.route, let routeId = route.id,
           let aliasDict = agencyModeAliases.first(where: { $0.id == routeId }) {
            modeName = aliasDict.aliase
        }
        
        let mode = TripPlanningManager.shared.getSearchModefromName(mode: modeName)
        if type == .marker{
            iconName = mode.marker_image
        }else{
            iconName = mode.mode_image
        }
        return iconName
    }
}
