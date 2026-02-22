//
//  IBIConfig.swift
//

import Foundation
import UIKit

public struct ConfigOption: Codable {
	public var appVersion: Double
	public var latitude: Double
	public var longitude: Double
	public var revision: Int
	
 /// App version:  double, latitude:  double, longitude:  double, revision:  int
 /// Initializes a new instance.
 /// - Parameters:
 ///   - appVersion: Double
 ///   - latitude: Double
 ///   - longitude: Double
 ///   - revision: Int
	public init(appVersion: Double, latitude: Double, longitude: Double, revision: Int){
		self.appVersion = appVersion
		self.latitude = latitude
		self.longitude = longitude
		self.revision = revision
	}
}

public class IBIConfig {

 /// Shared.
 /// - Parameters:
 ///   - IBIConfig: Parameter description
	public static var shared: IBIConfig = {
		let mgr = IBIConfig()
		return mgr
	}()
	
 /// Load config.
 /// - Parameters:
 ///   - url: Parameter description
 ///   - v: Parameter description
 ///   - options: Parameter description
 ///   - deviceId: Parameter description
 ///   - completion: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void))
	public static func loadConfig(url: String, v: String, options: ConfigOption, deviceId: String,  completion:@escaping ((String?, String?)->Void)){
		do{
			let requestURL = url + "/v3/config"
			let configOptionData = try JSONEncoder().encode(options)
   /// Data: config option data, encoding: .utf8
   /// Initializes a new instance.
   /// - Parameters:
   ///   - data: configOptionData
   ///   - encoding: .utf8
			if let configRequestParams = String.init(data: configOptionData, encoding: .utf8)
			{
				let encryptedConfigRequestParams = IBISecurity.encrypt(configRequestParams)
				if encryptedConfigRequestParams.count == 0 {
					completion(nil, "can not receive proccessed request parameters")
					return
				}
				let task = IBIRequest()
				task.request(method: .post, path: requestURL, params: encryptedConfigRequestParams, headers: ["device_id":deviceId, "v": v, "device_os":"iOS_\(UIDevice.current.systemVersion)"], timeout:10) { data, error, response in
					if let data = data {
      /// Data: data, encoding: .utf8
      /// Initializes a new instance.
      /// - Parameters:
      ///   - data: data
      ///   - encoding: .utf8
						if let encryptedConfigResponse = String.init(data: data, encoding: .utf8) {
							let decryptedConfig = IBISecurity.decrypt(encryptedConfigResponse)
							completion(decryptedConfig, nil)
						}else {
							completion(nil, "can not convert the receive config for use")
						}
					}else{
						completion(nil, "no configuration from server")
					}
				}
			}else{
				completion(nil, "can not parse the request config options")
				return
			}
		}catch{
			completion(nil, "can not process load config, something went wrong. \(error)")
		}
	}
}
