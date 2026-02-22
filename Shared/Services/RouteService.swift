//
//  RouteService.swift
//

import Combine
import UIKit

protocol RouteService {
    var service: APIServiceProtocol { get }
    
    // Will fetch the list of routes
    /// Routes.
    /// - Returns: AnyPublisher<[TransitRoute], APIError>
    func routes() -> AnyPublisher<[TransitRoute], APIError>
    
    // Will fetch route details
    /// Route details.
    /// - Parameters:
    ///   - routeId: ID of the route
    /// - Returns: AnyPublisher<TransitRoute, APIError>
    func routeDetails(for routeId: String) -> AnyPublisher<TransitRoute, APIError>
    
    // Will fetch route points to display on the map
    /// Route geometry.
    /// - Parameters:
    ///   - patternId: ID of the route pattern
    /// - Returns: AnyPublisher<LegGeometry, APIError>
    func routeGeometry(for patternId: String) -> AnyPublisher<LegGeometry, APIError>
}

extension RouteService {
    /// Routes
    /// - Returns: AnyPublisher<[TransitRoute], APIError>
    /// Routes.

    /// - Returns: AnyPublisher<[TransitRoute], APIError>
    func routes() -> AnyPublisher<[TransitRoute], APIError> {
        return service.request(with: RouteEndpoint.routes.request)
            .eraseToAnyPublisher()
    }
    
    /// Route details.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: AnyPublisher<TransitRoute, APIError>
    func routeDetails(for routeId: String) -> AnyPublisher<TransitRoute, APIError> {
        return service.request(with: RouteEndpoint.routeDetails(routeId).request)
            .eraseToAnyPublisher()
    }
    
    /// Route pattern.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: AnyPublisher<[Geometry], APIError>
    func routePattern(for routeId: String) -> AnyPublisher<[Geometry], APIError> {
        return service.request(with: RouteEndpoint.routePattern(routeId).request)
            .eraseToAnyPublisher()
    }
    
    /// Route geometry.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: AnyPublisher<LegGeometry, APIError>
    func routeGeometry(for patternId: String) -> AnyPublisher<LegGeometry, APIError> {
        return service.request(with: RouteEndpoint.routeGeometry(patternId).request)
            .eraseToAnyPublisher()
    }
    
    /// Route direction stops.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: AnyPublisher<[Stop], APIError>
    func routeDirectionStops(for patternId: String) -> AnyPublisher<[Stop], APIError> {
        return service.request(with: RouteEndpoint.directionStops(patternId).request)
            .eraseToAnyPublisher()
    }
    
}
