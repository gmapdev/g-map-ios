//
//  APIAccessProvider.swift
//

import Foundation
import UIKit
import Combine

public enum APIAccessError: Error {
	case decodingError
	case requestError
	case unknown
}

struct APIResponseError: Codable {
	var result: String
	var message: String
	var code: Int
	var detail: String?
}

struct APIAccessResponse<T> {
	let value: T?
	let rawData: Data?
	let response: URLResponse
	var success: Bool = true
}

struct APIAccessProvider {
	
 /// Base u r l.
 /// - Parameters:
 ///   - String: Parameter description
	public var baseURL: String {
		get {
			return BrandConfig.shared.base_url
		}
	}
	
 /// Service u r l.
 /// - Parameters:
 ///   - String: Parameter description
	public var serviceURL: String {
		get {
			return BrandConfig.shared.service_url
		}
	}
		
	public var session: URLSession
	private var configuration: URLSessionConfiguration
	
 /// Add global header.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: URLRequest
	public func addGlobalHeader(_ request: URLRequest) -> URLRequest {
		var newRequest = request
		var headers = [
			"x-api-key":"p5jFsR3x2t3cluSjqSsLZ6r8qdPzm2sq31EvWyyY"
		]
        
        let accountAPIKey = BrandConfig.shared.account_api_key
            headers = [
                "x-api-key": accountAPIKey
            ]
    
        if let loginInfo = AppSession.shared.loginInfo, loginInfo.emailIsVerified {
			headers["Authorization"] = "Bearer " + loginInfo.token
		}
		
		for key in headers.keys {
			newRequest.addValue(headers[key] ?? "", forHTTPHeaderField: key)
		}
		
		return newRequest
	}
	
 /// Initializes a new instance.
	public init() {
		configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = NetworkConstants.requestTimeout
		configuration.timeoutIntervalForResource = NetworkConstants.resourceTimeout
		configuration.waitsForConnectivity = true
		configuration.httpMaximumConnectionsPerHost = NetworkConstants.httpMaximumConnections
		configuration.requestCachePolicy = .reloadIgnoringCacheData
		configuration.urlCache = .none
		session = URLSession(configuration: configuration)
	}

 /// Run for plain text.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: AnyPublisher<APIAccessResponse<String>, Error>
	func runForPlainText(_ request: URLRequest) -> AnyPublisher<APIAccessResponse<String>, Error> {
		let finalRequest = self.addGlobalHeader(request)
		return session
			.dataTaskPublisher(for: finalRequest)
			.print("APIAccessProvider for plain text")
			.timeout(.seconds(60), scheduler: DispatchQueue.main, options: nil, customError: nil)
			.receive(on: DispatchQueue.main)
			.tryMap { result -> APIAccessResponse<String> in
				var statusCode = 200
				if let httpResponse = result.response as? HTTPURLResponse {
					statusCode = httpResponse.statusCode
				}
				let success = statusCodeValidation(code: statusCode)
    /// Data: result.data, encoding: .utf8
    /// Initializes a new instance.
    /// - Parameters:
    ///   - data: result.data
    ///   - encoding: .utf8
				let responseValue =  String.init(data: result.data, encoding: .utf8)
				return APIAccessResponse(value: responseValue, rawData: result.data, response: result.response, success: success)
			}
			.mapError { error in
				return APIAccessError.unknown
			}
			.eraseToAnyPublisher()
	}

	
 /// Run.
 /// - Parameters:
 ///   - request: URLRequest
 /// - Returns: AnyPublisher<APIAccessResponse<T>, Error>
	func run<T: Decodable>(_ request: URLRequest) -> AnyPublisher<APIAccessResponse<T>, Error> {
		let finalRequest = self.addGlobalHeader(request)
		return session
			.dataTaskPublisher(for: finalRequest)
			.print("APIAccessProvider")
			.receive(on: DispatchQueue.main)
			.tryMap { result -> APIAccessResponse<T> in
				var responseValue:T? = nil

                var statusCode = 200
                if let httpResponse = result.response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                var success = statusCodeValidation(code: statusCode)
                
                do{
                    responseValue = try JSONDecoder().decode(T.self, from: result.data)
                }catch{
                    OTPLog.log(level: .error, info: "convert json object failed, \(error)")
                    success = false
                }

				return APIAccessResponse(value: responseValue, rawData: result.data, response: result.response, success: success)
			}
			.mapError { error in
				return APIAccessError.unknown
			}
			.eraseToAnyPublisher()
	}
    
    /// This function is used to validate wheather a request is success or not.
    /// Status code validation.
    /// - Parameters:
    ///   - code: Int
    /// - Returns: Bool
    private func statusCodeValidation(code: Int) -> Bool {
        if code >= 200 && code < 400 {
            return true
        }
        return false
    }
    
}
