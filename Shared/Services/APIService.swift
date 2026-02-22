//
//  APIService.swift
//

import Foundation
import Combine

/// Protocol for building URLRequest objects.
///
/// Implement this protocol to create custom request builders that can be used
/// with the APIService. This allows for flexible request construction while
/// maintaining a consistent interface.
///
/// Example:
/// ```swift
/// struct MyEndpoint: RequestBuilder {
///     func urlRequest() -> URLRequest {
///         var request = URLRequest(url: URL(string: "https://api.example.com")!)
///         request.httpMethod = "GET"
///         return request
///     }
/// }
/// ```
public protocol RequestBuilder {
    /// Creates and returns a configured URLRequest.
    ///
    /// - Returns: A fully configured URLRequest ready for execution
    func urlRequest() -> URLRequest
}

/// Protocol defining the API service interface for making network requests.
///
/// This protocol uses Combine publishers to provide a reactive approach to
/// network requests. All responses are automatically decoded to the specified
/// Decodable type.
public protocol APIServiceProtocol {
    /// Executes a network request and returns a Combine publisher.
    ///
    /// This method handles the complete request lifecycle including:
    /// - Request execution
    /// - Response validation
    /// - JSON decoding
    /// - Error handling
    ///
    /// - Parameter builder: A RequestBuilder that provides the URLRequest configuration
    /// - Returns: A publisher that emits the decoded response or an APIError
    func request<T: Decodable>(with builder: RequestBuilder) -> AnyPublisher<T, APIError>
}

/// Modern Combine-based API service for making network requests.
///
/// This service provides a reactive approach to networking using Combine publishers.
/// It automatically handles:
/// - HTTP status code validation (200-299 range)
/// - JSON decoding to specified types
/// - Internal server error detection
/// - Comprehensive error mapping
///
/// The service uses NetworkManager for URLSession configuration and provides
/// a loading state indicator through the `isLoading` published property.
///
/// Example:
/// ```swift
/// let service = APIService()
/// service.request(with: MyEndpoint())
///     .sink(receiveCompletion: { completion in
///         // Handle completion
///     }, receiveValue: { (response: MyResponse) in
///         // Handle response
///     })
/// ```
public class APIService: APIServiceProtocol {
    /// Published property indicating whether a request is currently in progress.
    ///
    /// Subscribe to this property to show/hide loading indicators in your UI.
    @Published public var isLoading = false

    /// Executes a network request and returns a Combine publisher with the decoded response.
    ///
    /// This method performs the following steps:
    /// 1. Creates a URLRequest using the provided builder
    /// 2. Executes the request using NetworkManager's URLSession
    /// 3. Validates the HTTP response status code (200-299)
    /// 4. Checks for internal server errors in the response
    /// 5. Decodes the JSON response to the specified type
    /// 6. Maps any errors to APIError types
    ///
    /// - Parameter builder: A RequestBuilder that provides the URLRequest configuration
    /// - Returns: A publisher that emits the decoded response of type T or an APIError
    ///
    /// Error Handling:
    /// - `.request(error:)`: Network-level errors (no connection, timeout, etc.)
    /// - `.httpError(statusCode)`: HTTP errors (status codes outside 200-299)
    /// - `.internalError(_)`: Server-side errors detected in response body
    /// - `.decodingError`: JSON decoding failures
    /// - `.unknown`: Unexpected errors
    ///
    /// Example:
    /// ```swift
    /// let service = APIService()
    /// service.request(with: StopEndpoint.stops(minLat: 0, maxLat: 1))
    ///     .sink(receiveCompletion: { completion in
    ///         switch completion {
    ///         case .finished:
    ///             print("Request completed")
    ///         case .failure(let error):
    ///             print("Request failed: \(error)")
    ///         }
    ///     }, receiveValue: { (stops: [Stop]) in
    ///         print("Received \(stops.count) stops")
    ///     })
    /// ```
    public func request<T>(with builder: RequestBuilder) -> AnyPublisher<T, APIError> where T: Decodable {
        
        let decoder = JSONDecoder()
		let request = builder.urlRequest()
        return NetworkManager.shared.session
            .dataTaskPublisher(for: request)
            .receive(on: DispatchQueue.main)
			.mapError { APIError.request(error: $0) }
            .flatMap { data, response -> AnyPublisher<T, APIError> in
                if let response = response as? HTTPURLResponse {
                    if (200...299).contains(response.statusCode) {
                        if let internalError = data.internalServerIssue {
                            return Fail(error: APIError.internalError(internalError))
                                .eraseToAnyPublisher()
                        }
                    return Just(data)
                        .decode(type: T.self, decoder: decoder)
                        .mapError {error in
							// Keep this to catch the json parser issue
							OTPLog.log(level: .error, info: "\(T.self), \(error)")
                            return .decodingError
                        }
                        .eraseToAnyPublisher()
                    } else {
                        return Fail(error: APIError.httpError(response.statusCode))
                            .eraseToAnyPublisher()
                    }
                }
                return Fail(error: APIError.unknown)
                        .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

extension Data {
    /// Attempts to extract internal server error information from the response data.
    ///
    /// This property checks if the response contains an "error" object in the JSON
    /// and attempts to decode it as an ApiInternalError. This allows the app to
    /// detect and handle server-side errors that return 200 status codes but
    /// contain error information in the response body.
    ///
    /// - Returns: An ApiInternalError if found in the response, nil otherwise
    ///
    /// The expected JSON structure:
    /// ```json
    /// {
    ///   "error": {
    ///     "message": "Error description",
    ///     "code": "ERROR_CODE"
    ///   }
    /// }
    /// ```
    var internalServerIssue: ApiInternalError? {
        do {
            if let json = try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] {
                if let error = json["error"] as? [String: Any]{
                    let errorData = try JSONSerialization.data(withJSONObject: error, options: .prettyPrinted)
                    let error: ApiInternalError = try JSONDecoder().decode(ApiInternalError.self, from: errorData)
                    OTPLog.log(level: .error, info: "\(error)")
                    return error
                }
            }
            return nil
        } catch _ as NSError {
            OTPLog.log(level: .info, info: "No internal issue")
            return nil
        }
    }
}
