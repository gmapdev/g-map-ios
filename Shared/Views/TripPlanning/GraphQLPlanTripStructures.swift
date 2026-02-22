//
//  GraphQLPlanTripStructures.swift
//

import Foundation
import MapKit
import SwiftUI

// MARK: Fare Calculation Structures

enum FareMedium: String{
    case cash = "cash"
    case orca = "electronic"
    case orca_lift = "orca_lift"
    case regular = "regular"
    case senior = "senior"
    case special = "special"
    case youth = "youth"
    case unknown = "unknown"
   
    /// Lable
    /// - Returns: String
    /// Lable.
    func lable() -> String {
        switch (self) {
        case .cash: return "Cash"
        case .orca: return "ORCA"
        case .orca_lift: return "ORCA LIFT"
        case .regular: return "regular"
        case .senior: return "senior"
        case .special: return "special"
        case .youth: return "youth"
        case .unknown: return"unknown"
        }
    }
    
}

enum RiderCategoryType: String{
    case adult = "regular"
    case youth = "youth"
    case senior = "senior"
    case special = "special"
    case cash = "cash"
    case orca = "electronic"
    case orca_lift = "orca_lift"
    case unknown = "unknown"
    
    /// Lable
    /// - Returns: String
    /// Lable.
    func lable() -> String {
        switch (self){
        case .adult : return "Adult"
        case .youth : return "Youth"
        case .senior: return "Senior"
        case .special: return  "special"
        case .cash: return "cash"
        case .orca: return "orca"
        case .orca_lift: return "orca_lift"
        case .unknown: return  "unknown"
        }
    }
}

struct FareProduct: Hashable{
    let id: String
    var product: Product
}

struct Product : Hashable{
    let id: String
    let medium: Medium
    let name: String   
    let riderCategory: RiderCategory
    let price: Price
    let modeName : String
    var transferredAmount: Double?
}

struct Medium : Hashable{
    let id: String
    let name: FareMedium
}

struct RiderCategory : Hashable{
    let id: String
    let name: RiderCategoryType
}

struct Price : Hashable{
    let amount: String
    let currency: Currency
}

struct Currency : Hashable{
    let code: String
    let digits: Int
}

// MARK: PlanTrip Structures

struct GraphQLTripPlanItem: Identifiable, Equatable {
	
	static func == (lhs: GraphQLTripPlanItem, rhs: GraphQLTripPlanItem) -> Bool {
		return lhs.id == rhs.id && lhs.itinerary == rhs.itinerary && lhs.isSelected == rhs.isSelected && lhs.isOtherGroup == rhs.isOtherGroup
	}
	
    var id: UUID = UUID()
    let itinerary: OTPItinerary
    var isSelected: Bool
    var isOtherGroup: Bool
}

public struct GraphQLTripLeg: Identifiable, Hashable  {
	
    public let id = UUID()
    public let leg: OTPLeg?
    
    /// Hash.
    /// - Parameters:
    ///   - into: Parameter description
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
	
	public static func == (lhs: GraphQLTripLeg, rhs: GraphQLTripLeg) -> Bool {
		return lhs.id == rhs.id && lhs.leg == rhs.leg
	}
}

public struct GraphQLRouteSegment {
    var routeType: String
    var routeColor: UIColor
    var coorindates: [CLLocationCoordinate2D]
}

struct GraphQLTripDirection: Identifiable  {
    let id = UUID()
    let step: OTPStep?
    let text: String = ""
}

struct GraphQLPlanTripPlotItems {
    let segments: [GraphQLRouteSegment]
    let origin: CLLocationCoordinate2D?
    let destination: CLLocationCoordinate2D?
    let specialRoutePoint: [GraphQLRouteSpecialPoint]?
}

public struct GraphQLRouteSpecialPoint {
    var coordinate: CLLocationCoordinate2D
    var color: UIColor?
    var info: String
}
