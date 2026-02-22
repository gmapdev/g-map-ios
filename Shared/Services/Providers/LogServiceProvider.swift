//
//  LogServiceProvider.swift
//

import Foundation
import Combine
import SwiftUI

struct LogExceptionItem: Encodable {
    let status: String
    let apiEndPoint: String
    let backEndServer: String
    let platform: String
    let appVersion: String
    let userEmail: String
    let deviceId: String
    let queryParams: String
    let queryResponse: String
}

enum LogEndPoint{
    case exception
    case system
    /// Url
    /// - Returns: APIEndPoint
    /// Url.

    /// - Returns: APIEndPoint
    func url() -> APIEndPoint {
        switch self{
        case .exception: return APIEndPoint(method:"POST", endpoint:"/mobile_exception_report/v2/submit")
        case .system: return APIEndPoint(method:"POST", endpoint:"/mobile_report_log/v2/submit")
        }
    }
}

class LogServiceProvider: BaseProvider {
    
    /// Report exception.
    /// - Parameters:
    ///   - status: Parameter description
    ///   - apiEndPoint: Parameter description
    ///   - backEndServer: Parameter description
    ///   - platform: Parameter description
    ///   - appVersion: Parameter description
    ///   - userEmail: Parameter description
    ///   - deviceId: Parameter description
    ///   - queryParams: Parameter description
    ///   - queryResponse: Parameter description
    func reportException(status: String, apiEndPoint: String, backEndServer: String, platform: String, appVersion: String, userEmail: String, deviceId: String, queryParams: String, queryResponse: String) {
        if !Env.shared.isNetworkConnected {
            return
        }
        
        let requestURL = BrandConfig.shared.logging_url + "/ext_api/otp-\(BrandConfig.shared.app_identifier)" + LogEndPoint.exception.url().endpoint + "?api_key=\(BrandConfig.shared.app_api_key)"
        let api = OTPAPIRequest()
        let headers = [
            "device_id": deviceId,
            "device_os":"ios"
        ]
        
        let logExceptionItem = LogExceptionItem(status: status, apiEndPoint: apiEndPoint, backEndServer: backEndServer, platform: platform, appVersion: appVersion, userEmail: userEmail, deviceId: deviceId, queryParams: queryParams, queryResponse: queryResponse)
        var jsonKeyPair: [String: Any] = [:]
        do {
            jsonKeyPair = try DataHelper.convertToDictionary(object: logExceptionItem)
        } catch {
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
        
        api.request(method: .post, path: requestURL, params: jsonKeyPair, headers: headers, format: .JSON) { data, error, response in
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the reportException response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for reportException is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for reportException is failed, invalid error json data")
                    return
                }
                return
            }
        }
    }
}
