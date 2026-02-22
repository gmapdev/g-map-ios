//
//  OTPPlanTrip-Extension.swift
//

import Foundation

extension OTPItinerary {
    public static func == (lhs: OTPItinerary, rhs: OTPItinerary) -> Bool {
        var legsSame = true
        if let llegs = lhs.legs, let rlegs = rhs.legs, llegs.count != rlegs.count {
            legsSame = false
        }else{
            if let llegs = lhs.legs, let rlegs = rhs.legs{
                for i in 0..<llegs.count {
                    if llegs[i] == rlegs[i] {}
                    else {
                        legsSame = false
                        break
                    }
                }
            }
        }
        return lhs.waitingTime == rhs.waitingTime &&
        lhs.startTime == rhs.startTime &&
        lhs.walkTime == rhs.walkTime &&
        lhs.endTime == rhs.endTime &&
        lhs.duration == rhs.duration &&
        legsSame
    }
    
    /// Cost description
    /// - Returns: (String, Double)
    /// Cost description.
    public func costDescription()->(String, Double) {
        var transitFare = 0.0
        var maxTNCFare = 0.0
        var drivingCost = 0.0
        var hasBikeshare = false
        
        let totalFaresTable = TripPlanningManager.shared.calculateLegCost(itinerary: self)
        if let adultFares = totalFaresTable[RiderCategoryType.adult.rawValue]{
            var adultTotalCost = 0.0
            for item in adultFares{
                if item.product.medium.name == .cash{
                    var price = 0.0
                    if let doublePrice = Double(item.product.price.amount){
                        price = doublePrice
                    }
                    adultTotalCost += price
                }
            }
            transitFare = adultTotalCost * 1000
        }

        if let legs = legs {
            for leg in legs{
                if leg.searchMode?.mode == Mode.car.rawValue {
                    if let distance = leg.distance {
                        drivingCost += distance * 0.000621371 * TripItineraryDefaultCost.drivingCentsPerMile.rawValue
                    }
                }
                if (leg.rentedBike ?? false) {
                    hasBikeshare = true
                }
            }
        }
        let bikeshareCost = hasBikeshare ? TripItineraryDefaultCost.bikeshareTripCostCents.rawValue : 0
        if drivingCost > 0  {
            drivingCost += TripItineraryDefaultCost.carParkingCostCents.rawValue
        }
        var total = bikeshareCost + drivingCost + transitFare + maxTNCFare * 100
        if total < 0 { total = 0 }
        let totalDescription = "$\(String(format:"%.2f", total/100))"
        return (totalDescription, total)
    }
}

extension OTPLeg {
    public static func == (lhs: OTPLeg, rhs: OTPLeg) -> Bool {
        var fareProductsSame = true
        if let lItems = lhs.fareProducts, let rItems = rhs.fareProducts, lItems.count != rItems.count {
            fareProductsSame = false
        }else{
            if let lelements = lhs.fareProducts, let relements = rhs.fareProducts{
                for i in 0..<lelements.count {
                    if lelements[i] == relements[i] {}
                    else {
                        fareProductsSame = false
                        break
                    }
                }
            }
        }
        
        var stepSame = true
        if let lItems = lhs.steps, let rItems = rhs.steps, lItems.count != rItems.count {
            stepSame = false
        }else{
            if let lelements = lhs.steps, let relements = rhs.steps{
                for i in 0..<lelements.count {
                    if lelements[i] == relements[i] {}
                    else {
                        stepSame = false
                        break
                    }
                }
            }
        }
        
        var intermediateStopsSame = true
        if let lItems = lhs.intermediateStops, let rItems = rhs.intermediateStops, lItems.count != rItems.count {
            intermediateStopsSame = false
        }else{
            if let lelements = lhs.intermediateStops, let relements = rhs.intermediateStops{
                for i in 0..<lelements.count {
                    if lelements[i] == relements[i] {}
                    else {
                        intermediateStopsSame = false
                        break
                    }
                }
            }
        }
        
        
        return lhs.endTime == rhs.endTime &&
        lhs.duration == rhs.duration &&
        lhs.departureDelay == rhs.departureDelay &&
        lhs.interlineWithPreviousLeg == rhs.interlineWithPreviousLeg &&
        lhs.searchMode?.mode == rhs.searchMode?.mode &&
        lhs.distance == rhs.distance &&
        lhs.startTime == rhs.startTime &&
        lhs.rentedBike == rhs.rentedBike &&
        lhs.transitLeg == rhs.transitLeg &&
        lhs.realTime == rhs.realTime &&
        lhs.arrivalDelay == rhs.arrivalDelay &&
        lhs.legGeometry == rhs.legGeometry &&
        lhs.pickupType == rhs.pickupType &&
        lhs.dropoffType == rhs.dropoffType &&
        lhs.agency == rhs.agency &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.route == rhs.route &&
        lhs.trip == rhs.trip &&
        fareProductsSame &&
        stepSame &&
        intermediateStopsSame
    }
}
extension OTPLocation {
    public static func == (lhs: OTPLocation, rhs: OTPLocation) -> Bool {
        return lhs.name == rhs.name &&
        lhs.lon == rhs.lon &&
        lhs.lat == rhs.lat &&
        lhs.vertexType == rhs.vertexType &&
        lhs.stop == rhs.stop &&
        lhs.rentalVehicle == rhs.rentalVehicle
    }
}
