//
//  PushServiceProvider.swift
//

import Foundation
import Combine
import SwiftUI

class PushServiceProvider: BaseProvider {
	
 /// Subscribe remote notification.
 /// - Parameters:
 ///   - deviceToken: Parameter description
 ///   - completion: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)?)
	func subscribeRemoteNotification(deviceToken: Data, completion:((String, String?)->Void)?){
		let apiAccessProvider = APIAccessProvider()
		let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
		let serviceAppKey = BrandConfig.shared.app_api_key
		let serviceAppId = BrandConfig.shared.app_identifier
        let reqURL = "\(apiAccessProvider.serviceURL)/device/register?api_key=\(serviceAppKey)"
		let location = LocationService.shared.getCurrentLocation()
		let latitude = location.coordinate.latitude
		let longitude = location.coordinate.longitude
		let language = SettingsManager.shared.appLanguage
		let deviceID = AppConfig.shared.deviceId()
        let device_name = UIDevice.current.name
		let configAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
		let configBuild =  Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
		let localTimezoneID = TimeZone.current.identifier
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		let clientInfo = "\(UIDevice.current.model)|\(configAppVersion)|\(configBuild)|\(serviceAppId)|Carrier|\(identifier)"
        let params = ["lat":latitude,"lng":longitude, "os_version": UIDevice.current.systemVersion, "device_info":deviceTokenString, "device_name": device_name, "device_id":deviceID, "platform":"IOS", "region_id": serviceAppId, "client_version":clientInfo,"timezone":localTimezoneID, "locale":language.languageCode(), "user_name":AppSession.shared.loginInfo?.email ?? ""] as [String: Any]
		
		let requestURL = reqURL
		let requestMethod = "POST"
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpBody = DataHelper.convertToData(object: params)
			request.setValue("application/json", forHTTPHeaderField: "content-type")
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<String>, Error> = apiAccessProvider.runForPlainText(request)
			publisher.sink(receiveCompletion: { result in
				switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "failed to subscribe push notification: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
					if result.success {
						if let response = result.value {
							completion?(response, nil)
						}else{
							completion?("", "failed to parse the returned push subscription information")
						}
					}else{
						completion?("", "failed to subscription")
					}
			}
			.store(in: &anyCancellables)
		}
	}
}
	
