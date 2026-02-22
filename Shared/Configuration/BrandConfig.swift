//
//  BrandConfig.swift
//

import Foundation
import MapKit

/// Used to manage and handle all the brand related configurations
public final class BrandConfig: ConfigInterface {
	
	// MARK: PRIVATE DEFINITION
	/// Config dictionary, which is used to hold all the brand configuration values
	public var configs: [String: Any] = [String: Any]()
	
	/// Config Lock is used to handle multithread access
	private var configLock: DispatchQueue = DispatchQueue(label: "com.ibigroup.brand.config.lock")
	
	/// Used to replace the variables for the other configuration.
	public func replacableVariables(value: String?) -> String?{
		let coordinate = LocationService.shared.defaultLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
		
		let replacable = ["$<base_url>":self.base_url,
						  "$<lang_code>":SettingsManager.shared.appLanguage.languageCode(),
						  "$<latitude>":"\(coordinate.latitude)",
						  "$<longitude>":"\(coordinate.longitude)",
						  "$<app_api_key>":"\(self.app_api_key)",
						  "$<timestamp>":"\(Date().timeIntervalSince1970)"
						 ]
		if let val = value, val.count > 0{
			var finalValue = val
			for key in replacable.keys {
				if let replaceValue = replacable[key] {
					finalValue = finalValue.replacingOccurrences(of: key, with: replaceValue)
				}
			}
			return finalValue
		}
		return value
	}
	
	/// Shared Instance - BrandConfig only contains one instance in the run time.
	public static let shared : BrandConfig = {
		let mgr = BrandConfig()
		mgr.loadConfig()
		
		return mgr
	}()
	
 /// Load config
 /// Loads config.
	public func loadConfig(){
		configLock.sync {
			do{
				let configDocURLPath = OTPUtils.docPath("brand_config.json")
    /// Contents of file: config doc u r l path.path(), encoding: .utf8
    /// Initializes a new instance.
    /// - Parameters:
    ///   - contentsOfFile: configDocURLPath.path(
				let jsonString = try String.init(contentsOfFile: configDocURLPath.path(), encoding: .utf8)
				if let decryptedString = IBISecurity.decrypt(jsonString),
				   let decryptedData = decryptedString.data(using: .utf8){
					if let configData = try JSONSerialization.jsonObject(with: decryptedData, options: []) as? [String: Any]{
						self.configs = configData
					}
				}
			}catch{
				OTPLog.log(level: .error, info: "Can not load configuration to disk, \(error.localizedDescription)", parameters: nil)
			}
		}
	}
	
	// MARK: PUBLIC DEFINITION
	
	/// This is used to update the brand config values
 /// Updates.
 /// - Parameters:
 ///   - configs: [String: Any]
	override public func update(configs: [String: Any]) {
		configLock.sync {
			for key in configs.keys {
				let value = configs[key]
                self.configs[key] = value
			}
		}
	}
	
	/// This is used to flush the configuration values of brand config to disk
 /// Flush.
	override public func flush() {
		configLock.sync {
			do{
				let configJSONData = try JSONSerialization.data(withJSONObject: self.configs, options: .fragmentsAllowed)
				let configDocURLPath = OTPUtils.docPath("brand_config.json")
				let jsonString = String(data: configJSONData, encoding: .utf8) ?? "Unknown"
				let encryptedData = IBISecurity.encrypt(jsonString)
				try encryptedData.write(toFile:configDocURLPath.path, atomically: true, encoding: .utf8)
			}catch{
				OTPLog.log(level: .error, info: "Can not flush branding configuration to disk, \(error.localizedDescription)", parameters: nil)
			}
		}
	}
	
	/// Application Identifier is the unique key to let service distinguish different apps
	public var app_identifier: String {
		get {
			let key = "app_identifier"
			guard let value = configs[key] as? String else {
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			return  value
		}
	}
	
	
	/// Get the configuration url to fetch and get all configurations
	public var config_url: String {
		
		get {
			let key = "config_url"
			
			// Decide whether we allow the customized configuration url or not
			if let customized_configuration_url: String = PreferenceManager.object(forKey: AppConfig.UserDefaultKey.customized_configuration_url.rawValue), customized_configuration_url.count > 0{
				return customized_configuration_url
			}
			
			guard let value = configs[key] as? String else {
				assertionFailure("config_url can not be empty")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			return  value
		}
		
		set {
			let key = "config_url"
			self.configs[key] = newValue
		}
	}
	
 /// Config_api_key.
 /// - Parameters:
 ///   - String: Parameter description
	public var config_api_key: String {
		get {
			let key = "config_api_key"
			guard let value = configs[key] as? String else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key).")
				return ""
			}
			return  value
		}
	}
	
 /// App_api_key.
 /// - Parameters:
 ///   - String: Parameter description
	public var app_api_key: String {
		get {
			let key = "app_api_key"
			guard let value = configs[key] as? String else {
				assertionFailure("app_api_key can not be empty")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			return  value
		}
	}
	
 /// Request_api_key.
 /// - Parameters:
 ///   - String: Parameter description
	public var request_api_key: String {
		get {
			let key = "request_api_key"
			guard let value = configs[key] as? String else {
				assertionFailure("request_api_key can not be empty")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			return  value
		}
	}
	
 /// Account_api_key.
 /// - Parameters:
 ///   - String: Parameter description
	public var account_api_key: String {
		get {
			let key = "account_api_key"
			guard let value = configs[key] as? String else {
				assertionFailure("account_api_key can not be empty")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			return  value
		}
	}
	

 /// Environment.
 /// - Parameters:
 ///   - String: Parameter description
	public var environment: String {
		get {
			let key = "environment"
			
			guard let value = configs[key] as? String else {
				OTPLog.log(level: .warning, info: "can not find value for key:\(key), using staging instead", parameters: nil)
				return "staging"
			}
			return  value
		}
	}
	
 /// Max_number_of_saved_trips.
 /// - Parameters:
 ///   - Int: Parameter description
	public var max_number_of_saved_trips:Int {
		get {
			let key = "max_number_of_saved_trips"
			guard let value = configs[key] as? String else {
				return 5
			}
			return  Int(value) ?? 5
		}
	}
	
 /// Default_location.
 /// - Parameters:
 ///   - CLLocationCoordinate2D: Parameter description
	public var default_location: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: latitude_of_map_center, longitude: longitude_of_map_center)
	}
	
 /// Latitude_of_map_center.
 /// - Parameters:
 ///   - Double: Parameter description
	public var latitude_of_map_center: Double {
		get {
			let key = "latitude_of_map_center"
			guard let value = configs[key] as? Double else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return 33.956695
			}
			return value
		}
	}
	
 /// Longitude_of_map_center.
 /// - Parameters:
 ///   - Double: Parameter description
	public var longitude_of_map_center: Double {
		get {
			let key = "longitude_of_map_center"
			guard let value = configs[key] as? Double else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return -83.98901
			}
			return value
		}
	}
	
 /// Zoom_level.
 /// - Parameters:
 ///   - Double: Parameter description
	public var zoom_level: Double {
		get {
			let key = "zoom_level"
			guard let value = configs[key] as? Double else {
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return 12.0
			}
			return value
		}
	}
	
 /// Map_style.
 /// - Parameters:
 ///   - String: Parameter description
	public var map_style: String {
		get {
			let key = "map_style"
			guard let value = configs[key] as? String else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return "streets"
			}
			return value
		}
	}
	
 /// Timezone.
 /// - Parameters:
 ///   - String: Parameter description
	public var timezone: String {
		get {
			let key = "timezone"
			guard let value = configs[key] as? String else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return "America/Toronto"
			}
			return value
		}
	}
	
 /// Enable_mode_filter.
 /// - Parameters:
 ///   - Bool: Parameter description
	public var enable_mode_filter: Bool {
		get {
			let key = "enable_mode_filter"
			guard let value = configs[key] as? String else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return false
			}
			return value.lowercased() == "true"
		}
	}
	
 /// Enable_route_filter.
 /// - Parameters:
 ///   - Bool: Parameter description
	public var enable_route_filter: Bool {
		get {
			let key = "enable_route_filter"
			guard let value = configs[key] as? String else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return false
			}
			return value.lowercased() == "true"
		}
	}
	
 /// Navigation_bar_height.
 /// - Parameters:
 ///   - Double: Parameter description
	public var navigation_bar_height: Double {
		get {
			let key = "navigation_bar_height"
			guard let value = configs[key] as? Double else {
				assertionFailure("Can not find \(key) for the app")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
				return 50.0
			}
			return value
		}
	}
	
    /// Boundary.
    /// - Parameters:
    ///   - MapBoundary: Parameter description
    public var boundary: MapBoundary {
        get {
            let key = "boundary"
            let defBoundary = MapBoundary(rect: MapBoundary.Rect(minCoordinate: Coordinate(latitude: 32.066, longitude: -86.0856),
                                                                 maxCoordinate: Coordinate(latitude: 35.7251, longitude: -81.9499)))
            guard let value = configs[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return defBoundary
            }
            
            let minMaxLatLon = value.components(separatedBy: ";")
            let min = minMaxLatLon[0].components(separatedBy: ",")
            let max = minMaxLatLon[1].components(separatedBy: ",")
            if !(min.count == 2) && !(max.count == 2) {
                return defBoundary
            }
            let minLat = Double(min[0]) ?? 0
            let minLon = Double(min[1]) ?? 0
            let maxLat = Double(max[0]) ?? 0
            let maxLon = Double(max[1]) ?? 0
            
            return MapBoundary(rect:MapBoundary.Rect(minCoordinate: Coordinate(latitude: minLat, longitude: minLon),
                                                     maxCoordinate: Coordinate(latitude: maxLat, longitude: maxLon)))
        }
    }
	
	
	
	
 /// Logging_url.
 /// - Parameters:
 ///   - String: Parameter description
	public var logging_url: String {
		get {
			let key = "logging_url"
			guard let value = configs[key] as? [String: Any] else {
				assertionFailure("Can not get logging_url for the url request")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			if let final_url = value[self.environment] as? String {
				return "\(final_url)"
			}
			
			OTPLog.log(level: .warning, info: "can not find logging_url for :\(self.environment), use staging url instead", parameters: nil)
			if let staging_url = value["staging"] as? String {
				return "\(staging_url)"
			}
			
			OTPLog.log(level: .error, info: "logging_url - staging url can not be found, use empty", parameters: nil)
			assertionFailure("Can not find the logging_url configuration for \(environment)")
			return ""
		}
	}

 /// Base_url.
 /// - Parameters:
 ///   - String: Parameter description
	public var base_url: String {
		get {
			let key = "base_url"
			guard let value = configs[key] as? [String: Any] else {
				assertionFailure("Can not get base_url for the url request")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			if let final_url = value[self.environment] as? String {
				return "\(final_url)"
			}
			
			OTPLog.log(level: .warning, info: "can not find url for :\(self.environment), use staging url instead", parameters: nil)
			if let staging_url = value["staging"] as? String {
				return "\(staging_url)"
			}
			
			OTPLog.log(level: .error, info: "staging url can not be found, use empty", parameters: nil)
			assertionFailure("Can not find the base_url configuration for \(environment)")
			return ""
		}
	}
    /// Graph q l_base_url.
    /// - Parameters:
    ///   - String: Parameter description
    public var graphQL_base_url: String {
        get {
            let key = "graphql_base_url"
            guard let value = configs[key] as? [String: Any] else {
                assertionFailure("Can not get base_url for the url request")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
                return ""
            }
            if let final_url = value[self.environment] as? String {
                return "\(final_url)"
            }
            
            OTPLog.log(level: .warning, info: "can not find url for :\(self.environment), use staging url instead", parameters: nil)
            if let staging_url = value["staging"] as? String {
                return "\(staging_url)"
            }
            
            OTPLog.log(level: .error, info: "staging url can not be found, use empty", parameters: nil)
            assertionFailure("Can not find the base_url configuration for \(environment)")
            return ""
        }
    }

 /// Autocomplete_url.
 /// - Parameters:
 ///   - String: Parameter description
	public var autocomplete_url: String {
		get {
			let key = "autocomplete_url"
			guard let value = configs[key] as? [String: Any] else {
				assertionFailure("Can not get autocomplete_url for the url request")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			if let final_url = value[self.environment] as? String {
				return "\(final_url)"
			}
			
			OTPLog.log(level: .warning, info: "can not find url for :\(self.environment), use staging url instead", parameters: nil)
			if let staging_url = value["staging"] as? String {
				return "\(staging_url)"
			}
			
			OTPLog.log(level: .error, info: "staging url can not be found, use empty", parameters: nil)
			assertionFailure("Can not find the autocomplete_url configuration for \(environment)")
			return ""
		}
	}
	
 /// Flurry_key.
 /// - Parameters:
 ///   - String: Parameter description
	public var flurry_key: String {
		get {
			let key = "flurry_key"
			guard let entry = configs[key] as? [String : Any], let value = entry["iOS"] as? String else {
				OTPLog.log(level: .warning, info: "can not find value for key:\(key). flurry can not be recorded", parameters: nil)
				return ""
			}
			return  value
		}
	}
	
 /// Service_url.
 /// - Parameters:
 ///   - String: Parameter description
	public var service_url: String {
		get {
			let key = "service_url"
			guard let value = configs[key] as? [String: Any] else {
				assertionFailure("Can not get service_url for the url request")
				OTPLog.log(level: .warning, info: "can not find value for key:\(key)", parameters: nil)
				return ""
			}
			if let final_url = value[self.environment] as? String {
				return "\(final_url)/\(app_identifier)"
			}
			
			OTPLog.log(level: .warning, info: "can not find url for :\(self.environment), use staging url instead", parameters: nil)
			if let staging_url = value["staging"] as? String {
				return "\(staging_url)/\(app_identifier)"
			}
			
			OTPLog.log(level: .error, info: "staging url can not be found, use empty", parameters: nil)
			assertionFailure("Can not find the service_url configuration for \(environment)")
			return ""
		}
	}
    
    /// Auth0_domain.
    /// - Parameters:
    ///   - String: Parameter description
    public var auth0_domain: String {
        get {
            let key = "auth0_domain"
            guard let value = configs[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "PST"
            }
            return value
        }
    }
    
    /// Auth0_client_id.
    /// - Parameters:
    ///   - String: Parameter description
    public var auth0_client_id: String {
        get {
            let key = "auth0_client_id"
            guard let value = configs[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "PST"
            }
            return value
        }
    }
    
    /// Auth0_client_secret.
    /// - Parameters:
    ///   - String: Parameter description
    public var auth0_client_secret: String {
        get {
            let key = "auth0_client_secret"
            guard let value = configs[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "PST"
            }
            return value
        }
    }
    
    /// Enable_log_view.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var enable_log_view: Bool {
        get {
            let key = "enable_log_view"
            guard let value = configs[key] as? Bool else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key).")
                return false
            }
            return  value
        }
    }
    
    /// Enable_background_location_update.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var enable_background_location_update: Bool {
        get {
            let key = "enable_background_location_update"
            guard let value = configs[key] as? Bool else {
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return false
            }
            return value
        }
    }
    
    /// Realtime_businfo_refresh_interval.
    /// - Parameters:
    ///   - Double: Parameter description
    public var realtime_businfo_refresh_interval: Double {
        get {
            let key = "realtime_businfo_refresh_interval"
            guard let value = configs[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 30
            }
            return value
        }
    }
    
    /// Ios_haptic_feedback_type.
    /// - Parameters:
    ///   - UINotificationFeedbackGenerator.FeedbackType: Parameter description
    public var ios_haptic_feedback_type: UINotificationFeedbackGenerator.FeedbackType {
        get {
            let key = "ios_haptic_feedback_type"
            var hapticFeedbackType : UINotificationFeedbackGenerator.FeedbackType = .success
            let value = configs[key] as? String ?? "sucess"
            
            switch value {
                case "sucess":
                hapticFeedbackType = .success
            case "warning":
                hapticFeedbackType = .warning
            case "error":
                hapticFeedbackType = .error
            default:
                break
            }
            return hapticFeedbackType
        }
    }

}
