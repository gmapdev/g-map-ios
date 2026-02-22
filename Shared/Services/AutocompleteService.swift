//
//  AutocompleteService.swift
//

import Combine
import UIKit

protocol AutocompleteService {
    var service: APIServiceProtocol { get }
    
    /// Locations.
    func locations(for text: String,
                   boundary: MapBoundary) -> AnyPublisher<Autocomplete, APIError>
	
 /// Reverse.
 /// - Parameters:
 ///   - latitude: Parameter description
 ///   - longitude: Parameter description
 /// - Returns: AnyPublisher<Autocomplete, APIError>
	func reverse(latitude: Double, longitude: Double)->AnyPublisher<Autocomplete, APIError>
    /// Reverse v2.
    /// - Parameters:
    ///   - latitude: Parameter description
    ///   - longitude: Parameter description
    /// - Returns: AnyPublisher<[AutocompleteV2], APIError>
    func reverseV2(latitude: Double, longitude: Double)->AnyPublisher<[AutocompleteV2], APIError>
}

extension AutocompleteService {
    func locations(for text: String,
                   boundary: MapBoundary) -> AnyPublisher<Autocomplete, APIError> {
        return service.request(with: AutocompleteEndpoint.locations(searchText: text.percentEncoded(),
                                                                    minCoordinate: boundary.rect.minCoordinate,
                                                                    maxCoordinate: boundary.rect.maxCoordinate).request)
            .eraseToAnyPublisher()
    }
	
 /// Reverse.
 /// - Parameters:
 ///   - latitude: Parameter description
 ///   - longitude: Parameter description
 /// - Returns: AnyPublisher<Autocomplete, APIError>
	func reverse(latitude: Double, longitude: Double)->AnyPublisher<Autocomplete, APIError>{
		return service.request(with: AutocompleteEndpoint.reverse(latitude: latitude, longitude: longitude).request).eraseToAnyPublisher()
	}
    
    /// Reverse v2.
    /// - Parameters:
    ///   - latitude: Parameter description
    ///   - longitude: Parameter description
    /// - Returns: AnyPublisher<[AutocompleteV2], APIError>
    func reverseV2(latitude: Double, longitude: Double)->AnyPublisher<[AutocompleteV2], APIError>{
        return service.request(with: AutocompleteEndpoint.reverse(latitude: latitude, longitude: longitude).request).eraseToAnyPublisher()
    }
}
