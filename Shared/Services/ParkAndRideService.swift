//
//  ParkAndRideService.swift
//

import Combine
import UIKit

protocol ParkAndRideService {
    var service: APIServiceProtocol { get }
    
    /// Park and ride.
    /// - Parameters:
    ///   - maxTransitDistance: Parameter description
    /// - Returns: AnyPublisher<[ParkRide], APIError>
    func parkAndRide(maxTransitDistance: Double) -> AnyPublisher<[ParkRide], APIError>
}

extension ParkAndRideService {
 /// Park and ride.
 /// - Parameters:
 ///   - maxTransitDistance: Parameter description
 /// - Returns: AnyPublisher<[ParkRide], APIError>
	func parkAndRide(maxTransitDistance: Double) -> AnyPublisher<[ParkRide], APIError> {
        return service.request(with: ParkRideLocationsEndpoint.parkAndRides(maxTransitDistance: maxTransitDistance).request)
            .eraseToAnyPublisher()
    }
}


