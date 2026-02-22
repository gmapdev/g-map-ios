//
//  NetworkConstants.swift
//

import Foundation

public struct NetworkConstants {
    public static var requestTimeout: TimeInterval = 60
    public static var resourceTimeout: TimeInterval = 120
    public static var httpMaximumConnections: Int = 5
}

struct RequestParams {
    static let authorization = "Authorization"
    static let apiKey = "api_key"
    
    static let headersJSON = ["Accept": "application/json",
                              "Content-Type": "application/x-www-form-urlencoded",
							  "x-api-key": BrandConfig.shared.request_api_key]
}
