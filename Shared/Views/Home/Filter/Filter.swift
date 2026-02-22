//
//  Filter.swift
//

import Foundation
import CoreVideo

struct Filter: Codable {
    let top: TripFilter
    var subItems: [TripFilter]
    
    
    /// All filters
    /// - Returns: [TripFilter]
    /// All filters.
    func allFilters() -> [TripFilter] {
        var allFilters: [TripFilter] = [top]
        allFilters.append(contentsOf: subItems)
        return allFilters
    }
}

enum TripFilter: String, Codable, Comparable {
    static func < (lhs: TripFilter, rhs: TripFilter) -> Bool {
        lhs.rawValue != rhs.rawValue
    }
    
    case transit, walk, car, bicycle, rent, rail, subway, tram, bus, micromobility, ferry, gondola, waterTaxi, link, streetcar
    
    /// Mode combination name.
    /// - Parameters:
    ///   - String: Parameter description
    var modeCombinationName: String {
        switch self {
        case .transit:
            return "TRANSIT"
        case .walk:
            return "WALK"
        case .car:
            return "CAR"
        case .bicycle:
            return "BICYCLE"
        case .rent:
            return "ST-RENT"
        case .rail:
            return "RAIL"
        case .subway:
            return "SUBWAY"
        case .tram:
            return "TRAM"
        case .bus:
            return "BUS"
        case .micromobility:
            return "MICROMOBILITY"
        case .ferry:
            return "FERRY"
        case .gondola:
            return "GONDOLA"
        case .waterTaxi:
            return "WATER_TAXI"
        case .link:
            return "TRAM"
		case .streetcar:
			return "STREETCAR"
        }
    }
    
    
    /// Icon.
    /// - Parameters:
    ///   - String: Parameter description
    var icon: String {
        switch self {
        case .transit: return "ic_bus"
        case .walk: return "ic_walk"
        case .car: return "filter_car_icon"
        case .bicycle: return "ic_bike"
        case .bus: return "ic_bus"
        case .rent: return "ic_mobile"
        case .rail: return "ic_rail"
        case .tram: return "ic_streetcar"
        case .subway: return "ic_streetcar"
        case .micromobility: return "ic_streetcar"
        case .ferry: return "ic_ferry"
        case .gondola: return "ic_aerial_tram"
        case .waterTaxi: return "ic_water_taxi"
        case .link: return "ic_light_rail"
		case .streetcar: return "ic_streetcar"
        }
    }
    
    /// Display name.
    /// - Parameters:
    ///   - String: Parameter description
    var displayName: String {
        switch self {
        case .transit: return "Transit"
        case .walk: return "Walk"
        case .car: return "Car"
        case .bicycle: return "Bike"
        case .rent: return "Rental"
        case .bus: return "Bus"
        case .rail: return AppSettings.shared.config.railName ?? "Rail"
        case .tram: return AppSettings.shared.config.tramName ?? "Streetcar"
        case .subway: return AppSettings.shared.config.tramName ?? "Streetcar"
        case .ferry: return "Ferry"
        case .gondola: return "Aerial Tram"
        case .waterTaxi: return "Water Taxi"
        case .link: return "Link Light Rail"
		case .streetcar: return "Street Car"
        default: return rawValue
        }
    }
}

extension Array where Element == TripFilter {
    /// Modes.
    /// - Parameters:
    ///   - [ModeFilter]: Parameter description
    var modes: [ModeFilter] {
        let isCar = self.contains(.car)
        let isRent = self.contains(.rent)
        let isBus = self.contains(.bus)
        let isSubway = self.contains(.tram) || self.contains(.subway)
        let isRail = self.contains(.rail)
        let isBicycle = self.contains(.bicycle)
        let isWalk = self.contains(.walk)
        let isFerry = self.contains(.ferry)
        let isGondola = self.contains(.gondola)
     
		return ModeFilterManager.shared.requestModeFilter(isBus: isBus,
                                                          isSubway: isSubway,
                                                          isRail: isRail,
														  isWalk: isWalk,
														  isCar: isCar,
														  isBicycle: isBicycle,
														  isRent: isRent,
                                                          isFerry: isFerry,
                                                          isGondola: isGondola)
    }
}

extension TripFilter {
    /// Mode.
    /// - Parameters:
    ///   - ItineraryMode: Parameter description
    var mode: ItineraryMode {
        switch self {
        case .transit: return .transit
        case .walk: return .walk
        case .car: return .car
        case .bicycle: return .bicycle
        case .rent: return .carRent
        case .rail: return .rail
        case .subway: return .subway
        case .tram: return .tram
        case .bus: return .bus
        case .micromobility: return .micromobility
        case .ferry: return .ferry
        case .gondola: return .gondola
        case .waterTaxi: return .waterTaxi
        case .link: return .link
		case .streetcar: return .streetcar
        }
    }
}
