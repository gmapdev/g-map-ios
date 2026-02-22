//
//  TripPlan.swift
//

import SwiftUI

struct ItineraryFare: Codable, Equatable {
    let fare: ItineraryFareFare
}

struct ItineraryFareFare: Codable, Equatable {
    let regular: ItineraryFareFareRegular?
}

struct ItineraryFareFareRegular: Codable, Equatable {
    let cents: Double
}

enum Direction: String, Codable, Equatable {
    case depart = "DEPART",
         left = "LEFT",
         right = "RIGHT",
         north = "NORTH",
         east = "EAST",
         west = "WEST",
         south = "SOUTH",
         northEast = "NORTHEAST",
         northWest = "NORTHWEST",
         southWest = "SOUTHWEST",
         southEast = "SOUTHEAST",
         uturnRight = "UTURN_RIGHT",
         uturnLeft = "UTURN_LEFT",
         hardLeft = "HARD_LEFT",
         hardRight = "HARD_RIGHT",
         slightlyLeft = "SLIGHT_LEFT",
         slightlyRight = "SLIGHT_RIGHT",
         continueOn = "CONTINUE",
         unknown
    /// Initializes a new instance.
    /// - Parameters:
    ///   - decoder: Decoder
    /// - Throws: Error if operation fails
    public init(from decoder: Decoder) throws {
        guard let rawValue = try? decoder.singleValueContainer().decode(String.self) else {
            self = .unknown
            OTPLog.log(level: .warning, info: "Found unknown Direction")
            return
        }
        self = Direction(rawValue: rawValue) ?? .unknown
    }
}

enum VertexType: String, Codable, Equatable {
    case transit = "TRANSIT",
         normal = "NORMAL",
         bikeShare = "BIKESHARE",
		 vehicleRental = "VEHICLERENTAL",
		 carShare = "CARSHARE",
		 bikePark = "BIKEPARK",
         parkAndRide = "PARKANDRIDE",
         unknown
    
    /// Initializes a new instance.
    /// - Parameters:
    ///   - decoder: Decoder
    /// - Throws: Error if operation fails
    public init(from decoder: Decoder) throws {
        guard let rawValue = try? decoder.singleValueContainer().decode(String.self) else {
            self = .unknown
            OTPLog.log(level: .warning, info: "Found unknown VertexType")
            return
        }
        self = VertexType(rawValue: rawValue) ?? .unknown
    }
}

struct TNCData: Codable {
	let company: String?
	let currency: String?
	let travelDuration: Int?
	let maxCost: Int?
	let minCost: Int?
	let productId: String?
	let displayName: String?
	let estimateArrival: Int?
}

struct Step: Codable, Equatable {
    static func == (lhs: Step, rhs: Step) -> Bool {
        lhs.distance == rhs.distance &&
            lhs.relativeDirection == rhs.relativeDirection &&
            lhs.streetName == rhs.streetName &&
            lhs.absoluteDirection == rhs.absoluteDirection &&
            lhs.stayOn == rhs.stayOn &&
            lhs.area == rhs.area &&
            lhs.bogusName == rhs.bogusName &&
            lhs.lon == rhs.lon &&
            lhs.lat == rhs.lat
    }
    
    let distance: Double
    let relativeDirection: Direction
    let streetName: String
    let absoluteDirection: Direction?
    let stayOn: Bool
    let area: Bool
    let bogusName: Bool?
    let lon: Double
    let lat: Double
}

struct Geometry: Codable, Identifiable{
    let id: String
    let desc: String
    var geometry: LegGeometry?
}

struct LegGeometry: Codable, Equatable {
    let points: String
    let length: Int
}
