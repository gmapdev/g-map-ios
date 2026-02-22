//
//  TripsService.swift
//

import Combine
import UIKit

protocol TripsService {
    var service: APIServiceProtocol { get }
    
    /// Trip details.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<TripDetails, APIError>
    func tripDetails(tripId:String) -> AnyPublisher<TripDetails, APIError>
    /// Stops.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<[Stop], APIError>
    func stops(tripId:String) -> AnyPublisher<[Stop], APIError>
    /// Stop times.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<[StopTime], APIError>
    /// Stops times.
    func stopTimes(tripId:String) -> AnyPublisher<[StopTime], APIError>
}

extension TripsService {
    /// Trip details.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<TripDetails, APIError>
    func tripDetails(tripId:String) -> AnyPublisher<TripDetails, APIError> {
        return service.request(with: TripsEndpoint.tripDetails(tripId).request)
            .eraseToAnyPublisher()
    }
    
    /// Stops.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<[Stop], APIError>
    func stops(tripId:String) -> AnyPublisher<[Stop], APIError> {
        return service.request(with: TripsEndpoint.stops(tripId).request)
            .eraseToAnyPublisher()
    }
    
    /// Stop times.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// - Returns: AnyPublisher<[StopTime], APIError>
    func stopTimes(tripId:String) -> AnyPublisher<[StopTime], APIError> {
        return service.request(with: TripsEndpoint.stopTimes(tripId).request)
            .eraseToAnyPublisher()
    }
}

