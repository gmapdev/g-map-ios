//
//  FeatureConfig.swift
//

import Foundation
import SwiftUI

public final class FeatureConfig: ConfigInterface, ObservableObject{
    
    // MARK: PRIVATE PROPERTY DEFINITION
    /// Config dictionary, which is used to hold all the feature configuration values
    private var configs: [String: Any] = [String: Any]()
    
    /* This is used to store all the mode in the otp codebase to use. it won't take care  which mode need to be used, it just cached all the defined and existed mode from
     all_mode_list in mode feature
     **/
    public var allModesList: [SearchMode] = []
    
    // after computing the all modes list, this is the mode list that we are going to use and listed in this variables
    private var usedModesList: [SearchMode] = []
    
    /// Config Lock is used to handle multithread access
    private var configLock: DispatchQueue = DispatchQueue(label: "com.ibigroup.feature.config.lock")
    
    // MARK: PUBLIC FUNCTION DEFINITION
    
    /// Shared Instance - FeatureConfig only contains one instance in the run time.
    public static let shared : FeatureConfig = {
        let mgr = FeatureConfig()
		mgr.loadConfig()
        return mgr
    }()
    
    
    /// This is used to update the feature config values
    /// Updates.
    /// - Parameters:
    ///   - configs: [String: Any]
    override public func update(configs: [String: Any]) {
        configLock.sync {
            for key in configs.keys {
                let value = configs[key] as? [String: Any]
                self.configs[key] = value
            }
        }
    }
	
 /// Load config
 /// Loads config.
	public func loadConfig(){
		configLock.sync {
			do{
				let configDocURLPath = OTPUtils.docPath("feature_cfg.json")
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

    
    /// This is used to flush the configuration values of feature config to disk
    /// Flush.
    override public func flush() {
        configLock.sync {
            do{
                let configJSONData = try JSONSerialization.data(withJSONObject: self.configs, options: .fragmentsAllowed)
                let configDocURLPath = OTPUtils.docPath("feature_cfg.json")
                let jsonString = String(data: configJSONData, encoding: .utf8) ?? "Unknown"
                let encryptedData = IBISecurity.encrypt(jsonString)
                try encryptedData.write(toFile: configDocURLPath.path, atomically: true, encoding: .utf8)
            }catch{
                OTPLog.log(level: .error, info: "Can not flush features configuration to disk, \(error.localizedDescription)")
            }
        }
    }
    
    /// Used to check whether the feature is enabled or not. At the same time returns the detail of the feature for later use
    /// Checks if enabled.
    /// - Parameters:
    ///   - feature: Feature
    ///   - detail: inout [String: Any]?
    /// - Returns: Bool
    static public func  isEnabled(_ feature: Feature, detail: inout [String: Any]?) -> Bool {
        if let features = shared.configs[feature.rawValue] as? [String: Any],
           let featureDetail = features["detail"] as? [String: Any],
           let enabled = featureDetail["is_enabled"] as? Bool{
            detail = featureDetail
            return enabled
        }
        detail = nil
        return false
    }
    
    
    /// Define the features that we can use in the app
    public enum Feature: String {
        case login = "Login"
        case menu = "Menu"
        case search = "Search"
        case modes = "Modes"
        case indoor_nav = "Indoor Navigation"
        case live_tracking = "Live Tracking"
    }
    
    /// Feature info.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: [String: Any]?
    public func featureInfo(_ featureName: Feature) -> [String: Any]? {
        return configs[featureName.rawValue] as? [String: Any]
    }
    
    
    /// Route_agency_name_mapping.
    /// - Parameters:
    ///   - [AgencyNameAliase]: Parameter description
    public var route_agency_name_mapping: [AgencyNameAliase] {
        get{
            var anas = [AgencyNameAliase]()
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let rmam = detail["route_mode_agencies_mapping"] as? String {
                    let components = rmam.components(separatedBy: ";")
                    for component in components {
                        let parts = component.components(separatedBy: ",")
                        if parts.count == 2 {
                            let name = parts[0]
                            let alias = parts[1]
                            anas.append( AgencyNameAliase(name: name, aliase: alias))
                        }
                    }
                }
                
            }
            return anas
        }
    }
    
    /// Route_mode_overrides.
    /// - Parameters:
    ///   - [RouteModeOverride]: Parameter description
    public var route_mode_overrides: [RouteModeOverride] {
        get{
            var rmos = [RouteModeOverride]()
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let rmo = detail["route_mode_overrides"] as? String {
                    let components = rmo.components(separatedBy: ";")
                    for component in components {
                        let parts = component.components(separatedBy: ",")
                        if parts.count == 2 {
                            let id = parts[0]
                            let alias = parts[1]
                            rmos.append(RouteModeOverride(id: id, aliase: alias))
                        }
                    }
                }
                
            }
            return rmos
        }
    }
    
    /// Default criterias.
    /// - Parameters:
    ///   - Criterias: Parameter description
    public var defaultCriterias: Criterias {
        get{
            var defVal = Criterias(maximumWalk: "1/10", walkSpeed: 2, optimize: "Speed")
            if let feature = featureInfo(.search),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let criteria = detail["default_criterias"] as? [String: Any] {
                    if let maxWalk = criteria["maximum_walk"] as? String {
                        defVal.maximumWalk = maxWalk
                    }
                    
                    if let walk_speed = criteria["walk_speed"] as? Int {
                        defVal.walkSpeed = walk_speed
                    }
                    
                    if let optimize = criteria["optimize"] as? String {
                        defVal.optimize = optimize
                    }
                    if let avoidWalking = criteria["avoid_walking"] as? Bool {
                        defVal.avoidWalking = avoidWalking
                    }
                    if let accessibleRouting = criteria["accessible_routing"] as? Bool{
                        defVal.accessibleRouting = accessibleRouting
                    }
                    if let allowBikeRental = criteria["allow_bike_rental"] as? Bool{
                        defVal.allowBikeRental = allowBikeRental
                    }
                }
                
            }
            return defVal
        }
    }
    
    /// All_mode_list_url.
    /// - Parameters:
    ///   - String: Parameter description
    public var all_mode_list_url: String {
        get{
            var url = ""
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let mode_list_link = detail["all_mode_list"] as? String {
                    url = mode_list_link
                }
                
            }
            return url
        }
    }
    
    /// Route_mode_combinations_url.
    /// - Parameters:
    ///   - String: Parameter description
    public var route_mode_combinations_url: String {
        get{
            var url = ""
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let mode_combination_url = detail["route_mode_combinations_url"] as? String {
                    url = mode_combination_url
                }
                
            }
            return url
        }
    }
    
    public var agencies_logo_base_url: String {
        get{
            var url = ""
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let agencies_logo_base_url = detail["agencies_logo_base_url"] as? String {
                    url = agencies_logo_base_url
                }
                
            }
            return url
        }
    }
    
    public var sorted_route_order_url: String {
        get{
            var url = ""
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let sorted_route_order_url = detail["sorted_route_order_url"] as? String {
                    url = sorted_route_order_url
                }
                
            }
            return url
        }
    }
    
    /// Search_error_list_mapping.
    /// - Parameters:
    ///   - String: Parameter description
    public var search_error_list_mapping: String {
        get{
            var url = ""
            if let feature = featureInfo(.search),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let mode_combination_url = detail["search_error_list_mapping"] as? String {
                    url = mode_combination_url
                }
            }
            return url
        }
    }
    
    /// Banned_route_list.
    /// - Parameters:
    ///   - String: Parameter description
    public var banned_route_list: String {
        get{
            var url = ""
            if let feature = featureInfo(.search),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let mode_combination_url = detail["banned_route_list"] as? String {
                    url = mode_combination_url
                }
            }
            return url
        }
    }
    
    /// Login_page_title.
    /// - Parameters:
    ///   - String: Parameter description
    public var login_page_title: String {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               let title = detail["title"] as? String,
               is_enabled {
                return title
            }
            return ""
        }
    }
    
    /// Login_logo_height.
    /// - Parameters:
    ///   - Double: Parameter description
    public var login_logo_height: Double {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               let logo_height_val = detail["logo_height"] as? Double,
               is_enabled {
                return logo_height_val
            }
            return 90
        }
    }
    
    /// Login_logo_width.
    /// - Parameters:
    ///   - Double: Parameter description
    public var login_logo_width: Double {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               let logo_width_val = detail["logo_width"] as? Double,
               is_enabled {
                return logo_width_val
            }
            return 90
        }
    }
    
    /// Available_notification_methods.
    /// - Parameters:
    ///   - String: Parameter description
    public var available_notification_methods: String {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let available_notification_methods = detail["available_notification_methods"] as? String {
                return available_notification_methods
            }
            return "Email,SMS"
        }
    }
    /// Url_terms_of_service.
    /// - Parameters:
    ///   - String: Parameter description
    public var url_terms_of_service: String {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let available_notification_methods = detail["url_terms_of_service"] as? String {
                return available_notification_methods
            }
            return "https://soundrideguide.com/#/terms-of-service"
        }
    }
    /// Url_terms_of_storage.
    /// - Parameters:
    ///   - String: Parameter description
    public var url_terms_of_storage: String {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let available_notification_methods = detail["url_terms_of_storage"] as? String {
                return available_notification_methods
            }
            return "https://soundrideguide.com/#/terms-of-storage"
        }
    }
    
    /// Help_url.
    /// - Parameters:
    ///   - String: Parameter description
    public var help_url: String {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let available_notification_methods = detail["help_url"] as? String {
                return available_notification_methods
            }
            return "https://www.soundtransit.org/help-contacts"
        }
    }

    
    /// Priorities_route_agency_order.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var priorities_route_agency_order: Bool {
        get{
            if let feature = featureInfo(.modes),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               let priorities_route_agency_order = detail["priorities_route_agency_order"] as? String,
               is_enabled {
                return priorities_route_agency_order.lowercased() == "true"
            }
            return true
        }
    }
    
    /// Available criterias.
    /// - Parameters:
    ///   - CriteriasData: Parameter description
    public var availableCriterias: CriteriasData {
        get{
            var availVals = CriteriasData(maximumWalk: ["1/10"], walkSpeed: [[2 : 0.89]], optimize: ["Speed"])
            if let feature = featureInfo(.search),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let criteria = detail["available_criterias"] as? [String: Any] {
                    if let maxWalk = criteria["maximum_walk"] as? String {
                        availVals.maximumWalk = maxWalk.components(separatedBy: ",")
                    }
                    var speedDict: [[Int : Double]] = [[:]]
                    if let walk_speed = criteria["walk_speed"] as? String {
                        let speeds = walk_speed.components(separatedBy: ",")
                        for item in speeds{
                            let speedParts = item.components(separatedBy: ":")
                            
                            var dict: [Int : Double] = [:]
                            let intValue = Int(speedParts[0]) ?? 0
                            let doubleValue = Double(speedParts[1]) ?? 0.0
                            dict[intValue] = doubleValue
                            
                            speedDict.append(dict)
                        }
                        availVals.walkSpeed = speedDict
                    }
                    
                    if let optimize = criteria["optimize"] as? String {
                        availVals.optimize = optimize.components(separatedBy: ",")
                    }
                }
            }
            return availVals
        }
        set{
            availableCriterias = newValue
        }
    }
	
 /// Enable_report_tracking_gps.
 /// - Parameters:
 ///   - Bool: Parameter description
	public var enable_report_tracking_gps: Bool {
		if let feature = featureInfo(.search),
		   let detail = feature["detail"] as? [String : Any],
		   let is_enabled = detail["is_enabled"] as? Bool,
		   let enable_report_tracking_gps = detail["enable_report_tracking_gps"] as? Bool,
		   is_enabled && enable_report_tracking_gps {
			return true
		}
		return false
	}
    
    public var isIndoorNavEnable : Bool{
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            return is_enabled
        }
        return false
    }
    
    public var jibestream_endpoint_url: String {
        let key = "jibestream_endpoint_url"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let _ = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "jibestream_endpoint_url"
            }
            return value
        }
        return "jibestream_endpoint_url"
    }
    
    public var jibestream_client_id: String {
        let key = "jibestream_client_id"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let _ = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "jibestream_endpoint_url"
            }
            return value
        }
        return "jibestream_endpoint_url"
    }
    
    public var jibestream_client_secret: String {
        let key = "jibestream_client_secret"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let _ = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "jibestream_endpoint_url"
            }
            return value
        }
        return "jibestream_endpoint_url"
    }
    
    public var jibesream_customer_id: Int {
        let key = "jibesream_customer_id"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 0
            }
            return value
        }
        return 0
    }
    
    public var extends_sdk_url: String {
        let key = "extends_sdk_url"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let _ = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "jibestream_endpoint_url"
            }
            return value
        }
        return "jibestream_endpoint_url"
    }
    
    public var extends_sdk_key_ios: String {
        let key = "extends_sdk_key_ios"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let _ = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? String else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return "jibestream_endpoint_url"
            }
            return value
        }
        return "jibestream_endpoint_url"
    }
    
    /// Indoor_nav_deviation_distance_mm.
    /// - Parameters:
    ///   - Int: Parameter description
    public var indoor_nav_deviation_distance_mm: Int {
        let key = "indoor_nav_deviation_distance_mm"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 1000
            }
            return value
        }
        return 1000
    }
    
    /// Indoor_nav_deviation_popup_count_max_number.
    /// - Parameters:
    ///   - Int: Parameter description
    public var indoor_nav_deviation_popup_count_max_number: Int {
        let key = "indoor_nav_deviation_popup_count_max_number"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3
            }
            return value
        }
        return 3
    }
    
    /// Indoor_nav_deviation_popup_wait_time_seconds.
    /// - Parameters:
    ///   - Double: Parameter description
    public var indoor_nav_deviation_popup_wait_time_seconds: Double {
        let key = "indoor_nav_deviation_popup_wait_time_seconds"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 10
            }
            return value
        }
        return 10
    }
    /// Indoor_nav_deviation_popup_wait_time_accumulate.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var indoor_nav_deviation_popup_wait_time_accumulate: Bool {
        let key = "indoor_nav_deviation_popup_wait_time_accumulate"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Bool else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return true
            }
            return value
        }
        return true
    }
    /// Indoor_entrance_exit_popup_distance_mm.
    /// - Parameters:
    ///   - Int: Parameter description
    public var indoor_entrance_exit_popup_distance_mm: Int {
        let key = "indoor_entrance_exit_popup_distance_mm"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3048
            }
            return value
        }
        return 3048
    }
    
    /// Indoor_entrance_exit_checking_interval_secs.
    /// - Parameters:
    ///   - Int: Parameter description
    public var indoor_entrance_exit_checking_interval_secs: Int {
        let key = "indoor_entrance_exit_checking_interval_secs"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3048
            }
            return value
        }
        return 3048
    }
    
    /// Indoor_ui_should_display_distance.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var indoor_ui_should_display_distance: Bool {
        let key = "indoor_ui_should_display_distance"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Bool else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return true
            }
            return value
        }
        return true
    }
    
    /// Indoor_checking_active_route_entrance.
    /// - Parameters:
    ///   - Bool: Parameter description
    public var indoor_checking_active_route_entrance: Bool {
        let key = "indoor_checking_active_route_entrance"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Bool else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return true
            }
            return value
        }
        return true
    }
    
    /// Indoor_entrance_exit_list_url.
    /// - Parameters:
    ///   - String: Parameter description
    public var indoor_entrance_exit_list_url: String {
        get{
            let key = "indoor_entrance_exit_list_url"
            var url = ""
            if let feature = featureInfo(.indoor_nav),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let indoor_entrance_exit_list_url = detail[key] as? String {
                    url = indoor_entrance_exit_list_url
                }
            }
            return url
        }
    }
    
    /// Indoor_main_entrance_list.
    public var indoor_main_entrance_list: String {
        get{
            let key = "indoor_main_entrance_list"
            var url = ""
            if let feature = featureInfo(.indoor_nav),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let indoor_entrance_exit_list_url = detail[key] as? String {
                    url = indoor_entrance_exit_list_url
                }
            }
            return url
        }
    }
    
    /// Indoor_triggerable_locations.
    public var indoor_triggerable_locations: String {
        get{
            let key = "indoor_triggerable_locations"
            var url = ""
            if let feature = featureInfo(.indoor_nav),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                if let indoor_entrance_exit_list_url = detail[key] as? String {
                    url = indoor_entrance_exit_list_url
                }
            }
            return url
        }
    }
    
    public var isLiveTrackingEnable : Bool{
        if let feature = featureInfo(.live_tracking),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            return is_enabled
        }
        return false
    }
    
    /// Live_tracking_deviation_waittime_seconds.
    /// - Parameters:
    ///   - Double: Parameter description
    public var live_tracking_deviation_waittime_seconds: Double {
        let key = "live_tracking_deviation_waittime_seconds"
        if let feature = featureInfo(.live_tracking),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 30
            }
            return value
        }
        return 30
    }
    
    /// Live_tracking_repeat_instruction_waittime_seconds.
    /// - Parameters:
    ///   - Double: Parameter description
    public var live_tracking_repeat_instruction_waittime_seconds: Double {
        let key = "live_tracking_repeat_instruction_waittime_seconds"
        if let feature = featureInfo(.live_tracking),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 30
            }
            return value
        }
        return 30
    }
    
    /// Current_location_should_update_in_seconds.
    /// - Parameters:
    ///   - Int: Parameter description
    public var current_location_should_update_in_seconds: Int {
        let key = "current_location_should_update_in_seconds"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3048
            }
            return value
        }
        return 3048
    }
    /// Current_instruction_should_update_in_seconds.
    /// - Parameters:
    ///   - Int: Parameter description
    public var current_instruction_should_update_in_seconds: Int {
        let key = "current_instruction_should_update_in_seconds"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3048
            }
            return value
        }
        return 3048
    }
    /// Snap_to_wayfind_path_threshold_in_meter.
    /// - Parameters:
    ///   - Int: Parameter description
    public var snap_to_wayfind_path_threshold_in_meter: Int {
        let key = "snap_to_wayfind_path_threshold_in_meter"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Int else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 3048
            }
            return value
        }
        return 3048
    }
    
    /// Current location_upcoming_point_threshold_feet.
    /// - Parameters:
    ///   - Double: Parameter description
    public var currentLocation_upcoming_point_threshold_feet: Double {
        let key = "currentLocation_upcoming_point_threshold_feet"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 5
            }
            return value
        }
        return 5
    }
    /// Main_entrance_detection_radius_meters.
    /// - Parameters:
    ///   - Double: Parameter description
    public var main_entrance_detection_radius_meters: Double {
        let key = "main_entrance_detection_radius_meters"
        if let feature = featureInfo(.indoor_nav),
           let detail = feature["detail"] as? [String : Any],
           let is_enabled = detail["is_enabled"] as? Bool {
            
            guard let value = detail[key] as? Double else {
                assertionFailure("Can not find \(key) for the app")
                OTPLog.log(level: .warning, info: "can not find value for key:\(key)")
                return 5
            }
            return value
        }
        return 5
    }
    
    /// Menu.
    /// - Parameters:
    ///   - [MenuOption]: Parameter description
    public var menu: [MenuOption]{
        get{
            var menuOptions = [MenuOption]()
            if let feature = featureInfo(.menu),
               let detail = feature["detail"] as? [String : Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled
            {
                if let items = detail["items"] as? [String : Any]{
                    let keys = items.keys
                    for key in keys{
                        if let menuItems = items[key] as? [String : Any]{
                            var option = MenuOption(title: nil, icon: nil, type: nil, url: nil, order: nil)
                            if let title = menuItems["title"] as? String{
                                option.title = title
                            }
                            if let icon = menuItems["icon"] as? String{
                                option.icon = icon
                            }
                            if let type = menuItems["type"] as? String{
                                option.type = type
                            }
                            if let url = menuItems["url"] as? String{
                                option.url = url
                            }
                            if let isVisible = menuItems["isVisible"] as? Bool{
                                option.isVisible = isVisible
                            }
                            if let order = menuItems["order"] as? Int{
                                option.order = order
                            }
                            menuOptions.append(option)
                        }
                    }
                }
            }
            return menuOptions.sorted(by: {$0.order ?? 0 < $1.order ?? 0})
        }
    }
    
    /// Find mode detail.
    /// - Parameters:
    ///   - modeName: Parameter description
    /// - Returns: SearchMode?
    public func findModeDetail(modeName: String) -> SearchMode?{
        for mode in self.allModesList {
            if mode.mode == modeName {
                return mode
            }
        }
        return nil
    }
    
    /// Compute used modes
    /// Computes used modes.
    func computeUsedModes(){
        var availableModes = [SearchMode]()
        if let feature = featureInfo(.search),
           let detail = feature["detail"] as? [String: Any],
           let is_enabled = detail["is_enabled"] as? Bool,
           is_enabled {
            if let selectable_modes = detail["selectable_modes"] as? String {
                let modes = selectable_modes.components(separatedBy: ";")
                for mode in modes {
                    let modeParts = mode.components(separatedBy: ":")
                    if modeParts.count == 1 { // Mode itself
                        if let modeDetail = findModeDetail(modeName: modeParts[0]) {
                            availableModes.append(modeDetail)
                        }else{
                            OTPLog.log(level:.error, info: "can not find mode information \(modeParts[0])")
                        }
                    }
                    else if modeParts.count == 2 { // Mode and it submode
                        
                        // find parent
                        var parentMode:SearchMode?
                        if let modeDetail = findModeDetail(modeName: modeParts[0]) {
                            parentMode = modeDetail
                        }else{
                            OTPLog.log(level:.error, info: "can not find mode information \(modeParts[0])")
                        }
                        
                        // find child and add to parent
                        let subModes = modeParts[1].components(separatedBy: ",")
                        if subModes.count > 0 {
                            parentMode?.selectedSubModes = [SearchMode]()
                            for subMode in subModes {
                                if let subModeDetail = findModeDetail(modeName: subMode) {
                                    parentMode?.selectedSubModes?.append(subModeDetail)
                                }else{
                                    OTPLog.log(level:.error, info: "can not find mode information \(modeParts[0])'s submode: \(subMode)")
                                }
                            }
                        }
                        
                        if let mode = parentMode {
                            availableModes.append(mode)
                        }
                    }
                }
            }
        }
        self.usedModesList = availableModes
        
        DispatchQueue.main.async { [self] in
            // MARK: - added these two conditions to stop refreshing the filters while doing BG/FG.
            if !TripPlanningManager.shared.pubHasFiltersChanged && usedModesList != TripPlanningManager.shared.pubModeFilterCollection {
                TripPlanningManager.shared.pubModeFilterCollection = usedModesList.filter({$0.mode == Mode.transit.rawValue})
            }
            if usedModesList.count > 0 && !TripPlanningManager.shared.pubHasFiltersChanged {
                if usedModesList.count > 0 {
                    TripPlanningManager.shared.pubSubModeFilterCollection.removeAll()
                    if let transitMode = usedModesList.first(where: {$0.mode == Mode.transit.rawValue}) {
                        let subModes = transitMode.selectedSubModes ?? []
                        TripPlanningManager.shared.pubSubModeFilterCollection.append(contentsOf: subModes)
                    }
                    if let transitMode = usedModesList.first(where: {$0.mode == Mode.rent.rawValue}) {
                        let subModes = transitMode.selectedSubModes ?? []
                        TripPlanningManager.shared.pubSubModeFilterCollection.append(contentsOf: subModes)
                    }
                } else {
                    TripPlanningManager.shared.pubSubModeFilterCollection = []
                }
            }
            
            let (modeCollection, subModeCollection, isAvoidWalkingSelected, isAccessibleRoutingSelected, pickerItem, isAllowBikeRentalSelected, isAllowScooterRentalSelected) = Helper.shared.getUserPreferredSettings()
            if let modeCollection = modeCollection, !modeCollection.isEmpty {
                TripPlanningManager.shared.pubModeFilterCollection = modeCollection
            }
            if let subModeCollection = subModeCollection, !subModeCollection.isEmpty {
                TripPlanningManager.shared.pubSubModeFilterCollection = subModeCollection
            }
            TripSettingsViewModel.shared.isAvoidWalkingSelected = isAvoidWalkingSelected
            SearchManager.shared.userCriterias.avoidWalking = isAvoidWalkingSelected
            TripSettingsViewModel.shared.isAccessibleRoutingSelected = isAccessibleRoutingSelected
            SearchManager.shared.userCriterias.accessibleRouting = isAccessibleRoutingSelected
            TripSettingsViewModel.shared.pubWalkSpeed = pickerItem
            TripSettingsViewModel.shared.isAllowBikeRentalSelected = isAllowBikeRentalSelected
            SearchManager.shared.userCriterias.allowBikeRental = isAllowBikeRentalSelected
            TripSettingsViewModel.shared.isAllowScooterRentalSelected = isAllowScooterRentalSelected
            SearchManager.shared.userCriterias.allowScooterRental = isAllowScooterRentalSelected
            SearchManager.shared.userCriterias.walkSpeed = Int(pickerItem.defaultValue) ?? 3
            let walkSpeedValue = pickerItem.defaultValue
            if walkSpeedValue != String(FeatureConfig.shared.defaultCriterias.walkSpeed) {
                PickerListViewModel.shared.isWlakSpeedChanged = true
            }
            TripPlanningManager.shared.updateSubFilter()
        }
    }
    
    /// Search modes.
    /// - Parameters:
    ///   - [SearchMode]: Parameter description
    public var searchModes: [SearchMode] {
        get{
            // use variable to hold it, this way to increase the search speed. and page render.
            return self.usedModesList
        }
    }
    
    /// This is used to enable the start route button if we want to have it.
    /// This is first introduced in ITS4US
    public var enable_start_route: Bool {
        get{
            if let feature = featureInfo(.search),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                return detail["enable_start_route"] as? Bool ?? false
            }
            return false
        }
    }
    
    /// This is used to enable the questionairs page when user create account or in the profile page.
    public var enable_mobile_questionairs: Bool {
        get{
            if let feature = featureInfo(.login),
               let detail = feature["detail"] as? [String: Any],
               let is_enabled = detail["is_enabled"] as? Bool,
               is_enabled {
                return detail["enable_mobile_questionairs"] as? Bool ?? false
            }
            return false
        }
    }
}
