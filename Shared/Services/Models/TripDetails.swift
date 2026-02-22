//
//  TripDetails.swift
//

import Foundation

struct TripDetails: Codable {
    let id: String
    let routeId: String
    let serviceId, tripHeadsign, routeShortName, directionId, blockID, shapeID: String?
    let wheelchairAccessible, bikesAllowed: Int?
}

struct Agency: Codable, Equatable{
    let id, name: String
    let url: String?
    let timezone, lang, phone: String?
    let fareUrl: String?
}
