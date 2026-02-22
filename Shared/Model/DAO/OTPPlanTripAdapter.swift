//
//  OTPPlanTripAdapter.swift
//

import Foundation


public class PlanTripAdapter {
	
 /// Shared.
 /// - Parameters:
 ///   - PlanTripAdapter: Parameter description
	public static var shared: PlanTripAdapter = {
		let mgr = PlanTripAdapter()
		return mgr
	}()

    /// Special convert.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: [String: Any]
    public func specialConvert(itinerary: OTPItinerary) -> [String: Any]{
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(itinerary)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            if var jsonObject = jsonObject {
                let legs = jsonObject["legs"] as? [[String: Any]]
                if var legs = legs {
                    for i in 0..<legs.count {
                        if let route = legs[i]["route"] as? [String: Any] {
                            let jsonData = try JSONSerialization.data(withJSONObject: route, options: [])
                            if let jsonString = String(data: jsonData, encoding: .utf8) {
                                legs[i]["route"] = jsonString
                            }
                        }else if let route = legs[i]["route"] as? String {
                            legs[i]["route"] = route
                        }
                    }
                    jsonObject["legs"] = legs
                    return jsonObject
                }
            }
        } catch {
            OTPLog.log(level: .error, info: "Error converting to JSON: \(error)")
        }
        return [:]
    }
    
    /// Convert511 routes to o t p intinaray.
    /// - Parameters:
    ///   - routes: Parameter description
    /// - Returns: [OTPItinerary]
    public func convert511RoutesToOTPIntinaray(routes: [RouteCandidateItem]) -> [OTPItinerary]{
        var otpItineraries = [OTPItinerary]()
        for route in routes {
            
            var otpItineray = OTPItinerary()
            otpItineray.id = UUID().uuidString
            otpItineray.isSelected = false
            otpItineray.duration = Int(route.travelTimeMins ?? 0)
            otpItineray.endTime = Int(Date().timeIntervalSince1970)
            otpItineray.waitingTime = 0
            otpItineray.startTime = Int(Date().timeIntervalSince1970)
            otpItineray.walkTime = 0
            
            var otpLegs = [OTPLeg]()
            if let polylines = route.polylines {
                for i in 0..<polylines.count {
                    let polyline = polylines[i]
                    var otpLeg = OTPLeg()
                    otpLeg.startTime = Int(Date().timeIntervalSince1970)
                    otpLeg.endTime = Int(Date().timeIntervalSince1970 + 3600)
                    otpLeg.departureDelay = 0
                    otpLeg.duration = 3600
                    otpLeg.interlineWithPreviousLeg = false
                    otpLeg.mode = "CAR"
                    otpLeg.distance = route.lengthKM
                    otpLeg.transitLeg = false
                    otpLeg.realTime = false
                    otpLeg.arrivalDelay = 0
                    otpLeg.rentedBike = false
                    otpLeg.fareProducts = []
                    otpLeg.legGeometry = OTPLegGeometry(points: polyline, length: 0)
                    otpLeg.steps = []
                    otpLeg.from = OTPLocation(name:route.start_address,lon: route.start_lon, lat: route.start_lat)
                    otpLeg.pickupType = OTPDropoffTypeEnum.none
                    otpLeg.to = OTPLocation(name:route.end_address,lon: route.end_lon, lat: route.end_lat)
                    otpLeg.dropoffType = OTPDropoffTypeEnum.none
                    otpLeg.agency = nil
                    otpLeg.headsign = nil
                    otpLeg.intermediateStops = []
                    otpLeg.trip = OTPTrip(gtfsID: "gtfs_\(otpItineray.id)_\(i)",tripHeadsign: nil)
                    
                    let otpRoute = OTPRoute(gtfsID: otpItineray.id, type: 0, color: "#000000", shortName: route.end_address, longName: route.end_address, textColor: "#000000")
                    otpLeg.route = otpRoute
                    otpLegs.append(otpLeg)
                }
            }
            otpItineray.legs = otpLegs
            otpItineraries.append(otpItineray)
        }// for route in routes
        return otpItineraries
    }
    
    /// Convert to route.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: TransitRoute?
    public func convertToRoute(leg: OTPLeg?) -> TransitRoute?{
        
        guard let leg = leg else {
            assertionFailure("Leg Not Found..!")
            return nil
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(leg)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            if let jsonObject = jsonObject {
                if let legAgency = jsonObject["agency"] as? [String : Any],
                    let legMode = jsonObject["mode"] as? String,
                   let route = jsonObject["route"] as? [String : Any]{
                    
                    let id = route["gtfsId"] as? String
                    let shortName = route["shortName"] as? String
                    let longName = route["longName"] as? String
                    let type = route["type"] as? Int
                    let color = route["color"] as? String
                    let patternId = route["id"] as? String
                    let textColor = route["textColor"] as? String
                    
                    let agencyId = legAgency["id"] as? String ?? ""
                    let agencyName = legAgency["Name"] as? String ?? ""

                    let agencyInfo = Agency(id: agencyId,
                                            name: agencyName,
                                            url: legAgency["url"] as? String,
                                            timezone: legAgency["timezone"] as? String,
                                            lang: legAgency["lang"] as? String,
                                            phone:legAgency["phone"] as? String,
                                            fareUrl:legAgency["fareUrl"] as? String)
                    
                    let routeBikesAllowed = route["routeBikesAllowed"] as? String
                    let bikesAllowed = route["bikesAllowed"] as? String
                    let eligibilityRestricted = route["eligibilityRestricted"] as? Int
                    let url = jsonObject["url"] as? String
                    let desc = jsonObject["desc"] as? String
                    let sortOrderSet = jsonObject["sortOrderSet"] as? Bool
                    
                    let mode = Mode(rawValue: legMode)
                    
                    let routeInfo = TransitRoute(id: id ?? "",
                                          agency: agencyInfo,
                                          shortName: shortName,
                                          longName: longName,
                                          type: type,
                                          color: color,
                                          textColor: textColor,
                                          eligibilityRestricted: eligibilityRestricted,
                                          routeBikesAllowed: routeBikesAllowed,
                                          bikesAllowed: bikesAllowed,
                                          sortOrderSet: sortOrderSet,
                                          agencyName: agencyName,
                                          agencyId: agencyId ,
                                          url: url,
                                          mode: mode,
                                          desc: desc,
                                          patternId: patternId,
                                          patterns: nil) // needs to fix patterns
                    
                    return routeInfo
                    
                }
            }
        } catch {
            OTPLog.log(level: .error, info: "Error converting to JSON: \(error)")
        }
        
        return nil
    }
}
