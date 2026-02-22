//
//  SearchConfig.swift
//

import Foundation

class TripSettings: Codable {
    var from: Autocomplete.Feature?
    var to: Autocomplete.Feature?
    var filters: [Filter] = []
}

extension TripSettings {
    /// Toggle
    /// Toggles.
    func toggle() {
        let newTo = from
        from = to
        to = newTo
    }
    
    /// Top filters.
    /// - Parameters:
    ///   - [TripFilter]: Parameter description
    var topFilters: [TripFilter] {
        return filters.map({ $0.top })
    }
    
    /// All filters.
    /// - Parameters:
    ///   - [TripFilter]: Parameter description
    var allFilters: [TripFilter] {
        return filters.reduce([TripFilter](), { result, item in
            var newFilters = result
            newFilters.append(contentsOf: item.allFilters())
            return newFilters
        })
    }
}

struct SearchConfig: Codable {
    let defaultCriterias: Criterias
    let criterias: CriteriasData
    let defaultFilters: [Filter]
    let searchErrorListMapping: String?
    
    /// Trip settings.
    /// - Parameters:
    ///   - TripSettings: Parameter description
    lazy var tripSettings: TripSettings = {
        var settings = TripSettings()
        settings.filters = defaultFilters
        return settings
    }()
    
    /// User criterias.
    /// - Parameters:
    ///   - Criterias: Parameter description
    lazy var userCriterias: Criterias = {
        return defaultCriterias
    }()
    
    lazy var dateSettings: DateSettings = DateSettings()
    
    struct DateSettings: Codable {
        var departAt: Date?
        var arriveBy: Date?
    }
    
    struct Criterias: Codable, Equatable {
        var maximumWalk: String
        var walkSpeed: Int
        var optimize: String
    }
    
    struct CriteriasData: Codable {
        let maximumWalk: [String]
        let walkSpeed: [Int]
        let optimize: [String]
    }
}

extension SearchConfig {
    /// Default top filters.
    /// - Parameters:
    ///   - [TripFilter]: Parameter description
    var defaultTopFilters: [TripFilter] {
        return defaultFilters.map({ $0.top })
    }
}
