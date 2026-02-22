//
//  DefaultsHelper.swift
//

import Foundation

public struct DefaultsHelper {
    /// Initializes a new instance.
    public init() { }
    
    public static let userDefault = UserDefaults.standard
    
    /// Sets.
    /// - Parameters:
    ///   - value: T
    ///   - key: String
    public static func set<T: Codable>(_ value: T, forKey key: String) {
		let data = try? JSONEncoder().encode(value)
        userDefault.setValue(data, forKey: key)
		userDefault.synchronize()
    }
    
    /// Codable.
    /// - Parameters:
    ///   - key: String
    /// - Returns: T?
    public static func codable<T: Codable>(forKey key: String) -> T? {
        guard let data = userDefault.data(forKey: key) else { return nil }
        let value = try? JSONDecoder().decode(T.self, from: data)
        return value
    }
}

extension DefaultsHelper {
    enum Keys: String, CaseIterable {
        case recentSearch = "com.user.recent.search"
    }
    
    /// Clear all data
    /// Clears all data.
    static func clearAllData() {
        for key in Keys.allCases {
            userDefault.removeObject(forKey: key.rawValue)
        }
    }
}

extension DefaultsHelper {
    /// Save recent.
    /// - Parameters:
    ///   - feature: Parameter description
    /// Saves recent.
    static func saveRecent(feature: Autocomplete.Feature) {
        let recent: [Autocomplete.Feature]? = DefaultsHelper.codable(forKey: DefaultsHelper.Keys.recentSearch.rawValue)
        var recentLocations = recent ?? []
        
        while recentLocations.count > 2 {
            recentLocations.removeLast(1)
        }
        
        guard !recentLocations.contains(where: { $0.properties.label == feature.properties.label }) else {
            return
        }
        recentLocations.insert(feature, at: 0)
        
        DefaultsHelper.set(recentLocations, forKey: DefaultsHelper.Keys.recentSearch.rawValue)
        SearchLocationViewModel.shared.getRecentLocations()
    }
    
    /// Get recent locations
    /// - Returns: [SearchLocationItem]
    /// Retrieves recent locations.
    static func getRecentLocations() -> [SearchLocationItem] {
        let recent: [Autocomplete.Feature]? = DefaultsHelper.codable(forKey: DefaultsHelper.Keys.recentSearch.rawValue)
        if let recent = recent {
            return recent.map({ SearchLocationItem(feature: $0) })
        } else {
            return []
        }
    }
}
