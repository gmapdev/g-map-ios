//
//  APIRequest.swift
//

import Foundation

public struct APIRequest: RequestBuilder {
    public let method: APIMethod
    public let path: String
    public let parameters: [String: String]?
    public let headers: [String: String]?
    public let baseURLString: String
    
    /// Initializes a new instance.
    public init(path: String,
                method: APIMethod = .get,
                parameters: [String: String]? = nil,
                headers: [String: String]? = nil,
                baseURLString: String = "") {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.baseURLString = baseURLString
    }
    
    /// Url request
    /// - Returns: URLRequest
    /// Url request.
    public func urlRequest() -> URLRequest {
        var request: URLRequest
		let urlString = (baseURLString + path).queryString(parameters ?? [:])
        let url = urlString.url
        request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        return request
    }
}
