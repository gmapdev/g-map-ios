//
//  TravelIQEnum.swift
//

import Foundation

/// List all the errors that will or may happens during the runtime
internal enum TravelIQError: Error {
	
	/// Error List
	case noAPIKey
    
    /// Can not parse URL
    case notValidURL
    
    /// Url response is empty
    case responseIsEmpty
    
    /// If the server request failed. we can use this one
    case requestFailed
    
    /// Unknown response type of the request
    case unknownResponseType
    
    /// URL Session is not created.
    case urlSessionIsNotInitialized
	
	/// Get the localized message
	var localizedMessage: String {
		switch (self) {
			case .noAPIKey:
				return "APIKey can not be empty"
            case .notValidURL:
                return "URL is not valid"
            case .responseIsEmpty:
                return "Response data is empty"
            case .requestFailed:
                return "Server request failed"
            case .unknownResponseType:
                return "Unknown response and status code"
            case .urlSessionIsNotInitialized:
                /// Initializes a new instance.
                return "Session manager is not initialzied"
		}
	}
}
