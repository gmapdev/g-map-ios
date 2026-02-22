//
//  TripProvider.swift
//

import Foundation
import Combine
import SwiftUI

/// Represents a routing error returned from the trip planning API.
///
/// When trip planning fails or encounters issues, the server returns
/// error codes and affected input fields. This struct captures those
/// errors for display to the user.
///
/// Example:
/// ```swift
/// let error = RoutingErrorResponse(
///     code: "NO_TRANSIT_CONNECTION",
///     inputField: "toPlace"
/// )
/// ```
struct RoutingErrorResponse: Hashable {
    /// Error code identifying the type of routing error
    let code: String

    /// The input field that caused the error (e.g., "fromPlace", "toPlace")
    let inputField: String

    /// Implements Hashable for use in Sets and collections
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(inputField)
    }
}

/// GraphQL trip plan request structure.
///
/// Encapsulates the complete GraphQL query and variables needed for
/// trip planning requests to the OTP server.
struct RequestTripPlan: Codable {
    /// The GraphQL query string
    let query: String?

    /// Variables for the GraphQL query
    var variables: PlanTripVariables
}

/// Variables for GraphQL trip planning requests.
///
/// Contains all parameters needed to plan a trip including:
/// - Origin and destination
/// - Date and time preferences
/// - Mode selections
/// - Accessibility requirements
/// - Walking preferences
/// - Route restrictions
///
/// Example:
/// ```swift
/// let variables = PlanTripVariables(
///     arriveBy: false,
///     banned: ["agency:route1": "ROUTE"],
///     date: "2024-01-15",
///     fromPlace: "47.6062,-122.3321",
///     mobilityProfile: nil,
///     modes: [SelectedMode(mode: "BUS")],
///     numItineraries: 3,
///     time: "09:00:00",
///     toPlace: "47.6205,-122.3493",
///     wheelchair: false,
///     walkReluctance: 2,
///     walkSpeed: 1.34
/// )
/// ```
struct PlanTripVariables: Codable {
    /// Whether to arrive by the specified time (true) or depart at it (false)
    let arriveBy: Bool

    /// Dictionary of banned routes/agencies (key: route ID, value: ban type)
    let banned: [String: String]?

    /// Trip date in YYYY-MM-DD format
    let date, fromPlace: String

    /// Mobility profile ID for accessibility routing
    let mobilityProfile: String?

    /// Selected transportation modes for the trip
    let modes: [SelectedMode]

    /// Number of itinerary alternatives to return
    let numItineraries: Int

    /// Trip time in HH:mm:ss format
    let time, toPlace: String

    /// Whether to require wheelchair-accessible routes
    let wheelchair: Bool?

    /// Walking reluctance factor (higher = prefer transit over walking)
    let walkReluctance: Int?

    /// Walking speed in meters per second
    let walkSpeed: Double?
}

/// Provides trip planning functionality via GraphQL API.
///
/// TripProvider handles:
/// - GraphQL trip plan requests
/// - Response parsing and error handling
/// - Routing error extraction
/// - Itinerary data transformation
///
/// This provider communicates with the OTP (OpenTripPlanner) GraphQL API
/// to retrieve trip planning results based on user preferences.
///
/// Example:
/// ```swift
/// let provider = TripProvider()
/// provider.retrieveTripPlanUsingGraphQL(
///     fromPlaceEncoded: "47.6062,-122.3321",
///     toPlaceEncoded: "47.6205,-122.3493",
///     date: "2024-01-15",
///     time: "09:00:00",
///     wheelchair: false,
///     bannedRouteObject: nil,
///     arBy: false,
///     walkReluctanceValue: 2,
///     walkSpeed: 1.34,
///     requestParams: "",
///     modeType: [SelectedMode(mode: "BUS")],
///     mobilityProfile: nil
/// ) { trip, errors, statusCode, response in
///     if let trip = trip {
///         print("Found \(trip.itineraries?.count ?? 0) itineraries")
///     }
/// }
/// ```
class TripProvider: BaseProvider {

    /// Collection of routing errors from the most recent request
    var errorMessage: [RoutingErrorResponse] = []

    /// Retrieves trip plans from the GraphQL API.
    ///
    /// This method constructs a GraphQL request with the specified parameters,
    /// sends it to the OTP server, and parses the response into trip itineraries.
    ///
    /// The method handles:
    /// - Request construction and encoding
    /// - Network communication
    /// - Response parsing
    /// - Error extraction and mapping
    /// - Itinerary data transformation
    ///
    /// - Parameters:
    ///   - fromPlaceEncoded: Origin coordinates (format: "lat,lon")
    ///   - toPlaceEncoded: Destination coordinates (format: "lat,lon")
    ///   - date: Trip date (YYYY-MM-DD)
    ///   - time: Trip time (HH:mm:ss)
    ///   - wheelchair: Whether wheelchair accessibility is required
    ///   - bannedRouteObject: Routes to exclude from planning
    ///   - arBy: Whether to arrive by (true) or depart at (false) the specified time
    ///   - walkReluctanceValue: Walking reluctance factor (1-10)
    ///   - walkSpeed: Walking speed in meters per second
    ///   - requestParams: Additional request parameters (currently unused)
    ///   - modeType: Selected transportation modes
    ///   - mobilityProfile: Mobility profile ID for accessibility routing
    ///   - completion: Callback with results (trip, errors, status code, raw response)
    ///
    /// Completion Handler Parameters:
    /// - `OTPPlanTrip?`: Parsed trip plan with itineraries, or nil if no results
    /// - `[RoutingErrorResponse]`: Array of routing errors encountered
    /// - `Int`: HTTP status code (0 for success, 500 for errors)
    /// - `[String: Any]`: Raw JSON response from server
    ///
    /// Example:
    /// ```swift
    /// provider.retrieveTripPlanUsingGraphQL(...) { trip, errors, status, response in
    ///     if !errors.isEmpty {
    ///         print("Routing errors: \(errors)")
    ///     }
    ///     if let trip = trip, let itineraries = trip.itineraries {
    ///         print("Found \(itineraries.count) trip options")
    ///     }
    /// }
    /// ```
    func retrieveTripPlanUsingGraphQL(fromPlaceEncoded: String, toPlaceEncoded: String, date: String, time: String, wheelchair: Bool, bannedRouteObject: [String: String]?, arBy: Bool, walkReluctanceValue: Int, walkSpeed: Double, requestParams:String, modeType: [SelectedMode], mobilityProfile: String?, completion: @escaping ((OTPPlanTrip?, [RoutingErrorResponse], Int, [String: Any])->Void)){
        errorMessage.removeAll()
        
        
        // MARK: - Request Using APIManager insted of Apollo
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.tripPlan
        
        
        //MARK: - for requesting GraphQL Query from our APIManager, we need to pass Query and variable in key-value pair as paramaters
        let requestTripPlan = RequestTripPlan(query: requestQuery,
                                              variables: PlanTripVariables(arriveBy: arBy,
                                                                   banned: bannedRouteObject,
                                                                   date: date,
                                                                   fromPlace: fromPlaceEncoded,
                                                                   mobilityProfile: mobilityProfile != nil ? mobilityProfile : nil,
                                                                   modes: modeType,
                                                                   numItineraries: 3,
                                                                   time: time,
                                                                   toPlace: toPlaceEncoded,
                                                                   wheelchair: nil,         // passed nil to match with GMap/ITS Web.
                                                                   walkReluctance: nil,     // passed nil to match with GMap/ITS Web.
                                                                   walkSpeed: nil) )        // passed nil to match with GMap/ITS Web.
        var jsonKeyPair : [String : Any]?
        do{
            let jsonData = try JSONEncoder().encode(requestTripPlan)
            if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                jsonKeyPair = jsonKey
            }
        }catch{
            OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestTripPlan)")
        }
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON, timeout: 30.0) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the Trip list response")
                completion(nil, [], 500, [:])
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for trip list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for trip list is failed, invalid error json data")
                    completion(nil, [], 500, [:])
                    return
                }
                completion(nil, [], 500, [:])
                return
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let plan = data["plan"] as? [String : Any]{
                            if let planData = try? JSONSerialization.data(withJSONObject:plan){
                                var trip = try JSONDecoder().decode(OTPPlanTrip.self, from: planData)
                                if let itineraries = trip.itineraries, itineraries.count > 0 {
                                    for i in 0..<itineraries.count {
                                        trip.itineraries?[i].otp2QueryParam = requestTripPlan.variables
                                    }
                                    
                                    if let routingErrors = trip.routingErrors {
                                        for routingError in routingErrors {
                                            if let routingErrorValues = routingError.value as? [String: Any] {
                                                let code = routingErrorValues["code"] as? String
                                                let inputField = routingErrorValues["inputField"] as? String
                                                let error = RoutingErrorResponse(code: code ?? "", inputField: inputField ?? "")
                                                self.errorMessage.append(error)
                                            }
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        completion(trip, self.errorMessage, 0, jsonData)
                                    }
                                    return
                                }
                                else {
                                    DispatchQueue.main.async {
                                        if let routingErrors = trip.routingErrors {
                                            for routingError in routingErrors {
                                                if let routingErrorValues = routingError.value as? [String: Any] {
                                                    let code = routingErrorValues["code"] as? String
                                                    let inputField = routingErrorValues["inputField"] as? String
                                                    let error = RoutingErrorResponse(code: code ?? "", inputField: inputField ?? "")
                                                    self.errorMessage.append(error)
                                                }
                                            }
                                        }
                                        completion(nil, self.errorMessage, 0, jsonData)
                                        return
                                    }
                                }
                            }
                        } else {
                            completion(nil, [], 500, [:])
                        }
                    } else {
                        completion(nil, [], 500, [:])
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the search modes, \(error.localizedDescription)")
                completion(nil, [], 500, [:])
            }
        }
    }
    
}
    
