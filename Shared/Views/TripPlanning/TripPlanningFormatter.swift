//
//  TripPlanningFormatter.swift
//

import Foundation

enum weightOption: Double {
    case driveReluctance = 2.0
    case durationFactor = 0.25
    case fareFactor = 0.5
    case transferReluctance = 0.9
    case walkWaitReluctance = 0.1
}

protocol TripPlanningFormatterProtocol {
    /// Sort itineraries.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - by: Parameter description
    ///   - isDescend: Parameter description
    /// - Returns: [OTPItinerary]
    func sortItineraries(_ itineraries: [OTPItinerary], by sortOption: SortOption, isDescend: Bool) -> [OTPItinerary]
}

class TripPlanningFormatter: TripPlanningFormatterProtocol {
    /// Sort itineraries.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - by: Parameter description
    ///   - isDescend: Parameter description
    /// - Returns: [OTPItinerary]
    func sortItineraries(_ itineraries: [OTPItinerary], by sortOption: SortOption, isDescend: Bool = true) -> [OTPItinerary] {
        switch sortOption {
        case .duration:
            return itineraries.sorted { prv, nxt in
                let prvDuration = prv.duration ?? 0
                let nxtDuration = nxt.duration ?? 0
                return isDescend ? prvDuration < nxtDuration : prvDuration > nxtDuration
            }
        case .arrivalTime:
            return itineraries.sorted { prv, nxt in
                let prvEndTime = prv.endTime ?? 0
                let nxtEndTime = nxt.endTime ?? 0
                return isDescend ? prvEndTime < nxtEndTime : prvEndTime > nxtEndTime
            }
        case .departureTime:
            return itineraries.sorted { prv, nxt in
                let prvStartTime = prv.startTime ?? 0
                let nxtStartTime = nxt.startTime ?? 0
                return isDescend ? prvStartTime < nxtStartTime : prvStartTime > nxtStartTime
            }
        case .walkTime:
            return itineraries.sorted { prv, nxt in
                let prvWalkTime = prv.walkTime ?? 0
                let nxtWalkTime = nxt.walkTime ?? 0
                
                return isDescend ? prvWalkTime < nxtWalkTime : prvWalkTime > nxtWalkTime
            }
        case .bestOption:
            return itineraries.sorted { prv, nxt in
                let prvBest = TripPlanningManager.shared.calculateItineraryCost(prv)
                let nxtBest = TripPlanningManager.shared.calculateItineraryCost(nxt)
                return prvBest < nxtBest
            }
        default:
            return itineraries
        }
    }
        
}
