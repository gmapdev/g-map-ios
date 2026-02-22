//
//  IndoorNavigation.swift
//

import Foundation

struct TurnByTurnNote: Equatable{
    public var id: String
    public var instruction: String
    public var distance: Float
    public var floor: String?
    public var decisionPoint: JMapWaypoint
    public var completionPoint: JMapWaypoint
}

struct TriggerableLocations: Codable {
    let latitude, longitude: Double
    let address, place: String
    let venueID, radiusInMeters: Int
    let coordinates: [CLLocationCoordinate2D]?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, address, place
        case venueID = "venueId"
        case radiusInMeters, coordinates, type
    }
    
    // MARK: - Manually Encoding & Decoding for CLLocationCoordinate2D

    // Custom decoding for CLLocationCoordinate2D array
    /// Initializes a new instance.
    /// - Parameters:
    ///   - decoder: Decoder
    /// - Throws: Error if operation fails
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        address = try container.decode(String.self, forKey: .address)
        place = try container.decode(String.self, forKey: .place)
        venueID = try container.decode(Int.self, forKey: .venueID)
        radiusInMeters = try container.decode(Int.self, forKey: .radiusInMeters)
        type = try container.decodeIfPresent(String.self, forKey: .type)

        if let coordinatesArray = try container.decodeIfPresent([[Double]].self, forKey: .coordinates) {
            coordinates = coordinatesArray.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        } else {
            coordinates = nil
        }
    }

    // Custom encoding for CLLocationCoordinate2D array
    /// Encode.
    /// - Parameters:
    ///   - encoder: Encoder
    /// - Throws: Error if operation fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
        try container.encode(place, forKey: .place)
        try container.encode(venueID, forKey: .venueID)
        try container.encode(radiusInMeters, forKey: .radiusInMeters)
        try container.encodeIfPresent(type, forKey: .type)

        // Encode the coordinates as an array of [longitude, latitude]
        if let coordinates = coordinates {
            let coordinatesArray = coordinates.map { [$0.longitude, $0.latitude] }
            try container.encode(coordinatesArray, forKey: .coordinates)
        }
    }
}

struct IndoorMainEntranceLocation: Codable {
    let venueID: Int
    let place: String
    let mainLatitude, mainLongitude: Double
    let radiusInMeter: Int
    let popupTitle, popupMessage: String

    enum CodingKeys: String, CodingKey {
        case venueID = "venueId"
        case place, mainLatitude, mainLongitude, radiusInMeter, popupTitle, popupMessage
    }
}

struct EntranceExitLocation: Codable{
    let type : String
    let name : String
    var message : String?
}
