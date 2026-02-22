//
//  APIError.swift
//

import Foundation

/// Represents an internal server error returned in the API response.
///
/// When the server encounters an error, it may return a 200 status code
/// but include error details in the response body. This struct captures
/// those error details.
///
/// Example JSON:
/// ```json
/// {
///   "error": {
///     "id": 404,
///     "msg": "Route not found",
///     "message": "The requested route does not exist",
///     "noPath": true
///   }
/// }
/// ```
public struct ApiInternalError: Codable {
    /// Numeric error code
    let id: Int

    /// Short error message
    let msg: String

    /// Detailed error message
    let message: String

    /// Whether no path was found (for routing errors)
    let noPath: Bool
}

public extension ApiInternalError {
    /// Returns a formatted debug message combining error ID and message.
    ///
    /// - Returns: Debug-friendly error string
    ///
    /// Example: "Error: 404. The requested route does not exist"
    var debugMessage: String {
        return "Error: \(id). \(message)"
    }
}

/// Represents all possible API error types.
///
/// This enum provides comprehensive error handling for network requests,
/// covering:
/// - JSON decoding failures
/// - HTTP status code errors
/// - Server-side errors
/// - Network connectivity issues
/// - Unknown errors
///
/// Each error type includes contextual information to help with debugging
/// and user-facing error messages.
///
/// Example:
/// ```swift
/// service.request(with: endpoint)
///     .sink(receiveCompletion: { completion in
///         if case .failure(let error) = completion {
///             switch error {
///             case .httpError(let code):
///                 print("HTTP error: \(code)")
///             case .decodingError:
///                 print("Failed to decode response")
///             case .request(let error):
///                 print("Network error: \(error)")
///             default:
///                 print("Unknown error")
///             }
///         }
///     }, receiveValue: { response in
///         // Handle response
///     })
/// ```
public enum APIError: Error {
    /// JSON decoding failed (response structure doesn't match expected model)
    case decodingError

    /// HTTP error with status code (e.g., 400, 401, 403, 404, 500)
    case httpError(Int)

    /// Server returned an internal error in the response body
    case internalError(ApiInternalError)

    /// Unknown or unexpected error
    case unknown

    /// Network-level error (no connection, timeout, etc.)
	case request(error: Error)
}

public extension APIError {
    /// Returns a user-friendly error message for display in the UI.
    ///
    /// This property provides localized, human-readable error messages
    /// appropriate for showing to end users. For debugging, use the
    /// error's description or debugDescription instead.
    ///
    /// Error Messages:
    /// - `.decodingError`: "Cannot decode data from server!"
    /// - `.httpError(400)`: "Input properly"
    /// - `.httpError(401)`: "Incorrect input"
    /// - `.httpError(403)`: "Not Authorized Access"
    /// - `.internalError(404)`: "" (empty, handled specially)
    /// - `.request(error)`: The underlying error's localized description
    /// - `.unknown`: "Unknown"
    ///
    /// Example:
    /// ```swift
    /// if case .failure(let error) = completion {
    ///     AlertManager.shared.presentAlert(message: error.displayMessage)
    /// }
    /// ```
    var displayMessage: String {
        switch self {
        case .decodingError: return "Cannot decode data from server!"
        case .httpError(let code):
            switch(code) {
            case 400: return "Input properly"
            case 401: return "Incorrect input"
            case 403: return "Not Authorized Access"
            default: return "Unknown"
            }
        case .internalError(let error):
            if error.id == 404 {
				OTPLog.log(level: .error, info: "error: ----> 404 resource not found.")
                return ""
            }
            return "\(error.id): " + error.msg
        case .unknown: return "Unknown"
		case .request(let error):
			return error.localizedDescription
        }
    }
}
