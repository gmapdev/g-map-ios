//
//  Autocomplete.swift
//

import Foundation

struct Autocomplete: Codable {
    struct Properties: Codable, Equatable {
        let id: String?
        let name: String
        var label: String
        let gid: String?
        let layer: String?
        let source: String?
        let source_id: String?
        let accuracy: String?
        let modes: [String]?
        let street: String?
        let neighbourhood: String?
        let locality: String?
        let region_a: String?
        let secondaryLabels: [String]?
    }
    
    
    struct Feature: Codable {
        var properties: Properties
        let geometry: Geometry?
        let id: String?
    }
    
    struct Geometry {
        var type: String
        var coordinate: Coordinate?
    }
    
    var features: [Feature]
}

extension Autocomplete.Geometry: Decodable, Encodable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case coordinate = "coordinates"
    }
    
    /// Initializes a new instance.
    /// - Parameters:
    ///   - decoder: Decoder
    /// - Throws: Error if operation fails
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        let locationPoint = try values.decode([Double].self, forKey: .coordinate)
        var point: Coordinate? = nil
        if locationPoint.count == 2,
           let latitude = locationPoint.last,
           let longitude = locationPoint.first {
            point = Coordinate(lat: latitude, long: longitude)
        }
        /// Type: type, point: point
        /// Initializes a new instance.
        /// - Parameters:
        ///   - type: type
        ///   - point: point
        self.init(type: type, point: point)
    }
    
    /// Encode.
    /// - Parameters:
    ///   - encoder: Encoder
    /// - Throws: Error if operation fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        if let coordinate = coordinate {
            
            // Here we re-order the array, so that we can match the decoding method. otherwise, we will have issue
            // result will be not inconsistent
            let location: [Double] = [coordinate.longitude, coordinate.latitude]
            try container.encode(location, forKey: .coordinate)
        }
    }
    
    /// Type:  string, point:  coordinate? = nil
    /// Initializes a new instance.
    /// - Parameters:
    ///   - type: String
    ///   - point: Coordinate? = nil
    init(type: String, point: Coordinate? = nil) {
        self.type = type
        self.coordinate = point
    }
}

extension Autocomplete.Feature {
    /// Trip request param.
    /// - Parameters:
    ///   - String: Parameter description
    var tripRequestParam: String {
        guard let coordinate = geometry?.coordinate else {
            return ""
        }
        return properties.label + "::" + "\(coordinate.latitude),\(coordinate.longitude)"
    }
}

// MARK: - AutocompleteV2
struct AutocompleteV2: Codable {
    let lat, lon: Double
    let name: String
    let rawGeocodedFeature: RawGeocodedFeature
    let label: String
}

// MARK: - RawGeocodedFeature
struct RawGeocodedFeature: Codable {
    let id, gid, layer, source: String
    let sourceID, countryCode, name: String
    let housenumber: String?
    let street, postalcode: String?
    let confidence, distance: Double?
    let accuracy, country, countryGid, countryA: String?
    let region, regionGid, regionA, county: String?
    let countyGid, countyA, locality, localityGid: String?
    let neighbourhood, neighbourhoodGid, continent, continentGid: String?
    let label, address: String?
    let latlng: Latlng

    enum CodingKeys: String, CodingKey {
        case id, gid, layer, source
        case sourceID = "source_id"
        case countryCode = "country_code"
        case name, housenumber, street, postalcode, confidence, distance, accuracy, country
        case countryGid = "country_gid"
        case countryA = "country_a"
        case region
        case regionGid = "region_gid"
        case regionA = "region_a"
        case county
        case countyGid = "county_gid"
        case countyA = "county_a"
        case locality
        case localityGid = "locality_gid"
        case neighbourhood
        case neighbourhoodGid = "neighbourhood_gid"
        case continent
        case continentGid = "continent_gid"
        case label, address, latlng
    }
}

// MARK: - Latlng
struct Latlng: Codable {
    let lat, lon: Double
}

