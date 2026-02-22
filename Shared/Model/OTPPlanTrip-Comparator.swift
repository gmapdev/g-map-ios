//
//  OTPPlanTrip-Comparator.swift
//

import Foundation

class OTPComparator {
	
 /// Shared.
 /// - Parameters:
 ///   - OTPComparator: Parameter description
	public static var shared: OTPComparator = {
		let mgr = OTPComparator()
		return mgr
	}()
	
 /// Itinerary comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Bool
    func itineraryComparator(_ a: OTPItinerary, _ b: OTPItinerary) -> Bool {
        let option = TripPlanningManager.shared.pubSortOption
        let desc = TripPlanningManager.shared.pubIsDescend

        @inline(__always)
        func ordered<T: Comparable>(_ x: T, _ y: T) -> Bool? {
            if x == y { return nil }
            return desc ? (x < y) : (x > y)
        }

        switch option {
        case .duration:
            if let r = ordered(a.duration ?? Int.max, b.duration ?? Int.max) { return r }

        case .arrivalTime:
            if let r = ordered(a.endTime ?? Int.max, b.endTime ?? Int.max) { return r }

        case .departureTime:
            if let r = ordered(a.startTime ?? Int.max, b.startTime ?? Int.max) { return r }

        case .walkTime:
            let aw = TripPlanningManager.shared.getPureWalkTime(itinerary: a)
            let bw = TripPlanningManager.shared.getPureWalkTime(itinerary: b)
            if let r = ordered(aw, bw) { return r }

        case .cost:
            let (_, ac) = TripPlanningManager.shared.getItineraryCost(itinerary: a)
            let (_, bc) = TripPlanningManager.shared.getItineraryCost(itinerary: b)
            if let r = ordered(ac, bc) { return r }

        case .bestOption:
            let ascore = TripPlanningManager.shared.calculateItineraryCost(a)
            let bscore = TripPlanningManager.shared.calculateItineraryCost(b)
            if ascore != bscore { return ascore < bscore }
        }

        if a.startTime != b.startTime { return (a.startTime ?? Int.max) < (b.startTime ?? Int.max) }
        if a.endTime != b.endTime { return (a.endTime ?? Int.max) < (b.endTime ?? Int.max) }
        if a.duration != b.duration { return (a.duration ?? Int.max) < (b.duration ?? Int.max) }
        if a.walkTime != b.walkTime { return (a.walkTime ?? Int.max) < (b.walkTime ?? Int.max) }
        return a.id < b.id
    }

	
 /// Group sort comparator.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - value: Parameter description
 /// - Returns: Bool
    func groupSortComparator(_ pre: (key: String, value: [GroupEntry]),
                             _ nxt: (key: String, value: [GroupEntry])) -> Bool {

        let pModesCount = pre.key.components(separatedBy: "+").count
        let nModesCount = nxt.key.components(separatedBy: "+").count

        if pModesCount == 1 && nModesCount == 1 { return pre.key < nxt.key }
        if pModesCount == 1 { return false }
        if nModesCount == 1 { return true }

        guard let pFirst = pre.value.first?.itineraries.first else { return false }
        guard let nFirst = nxt.value.first?.itineraries.first else { return true }

        if itineraryComparator(pFirst, nFirst) { return true }
        if itineraryComparator(nFirst, pFirst) { return false }
        return pre.key < nxt.key
    }

}
