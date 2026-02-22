//
//  AppConfig.swift
//

import Foundation
import UIKit

/// Manages application-level configuration and server synchronization.
///
/// This singleton class handles:
/// - Device identification and tracking
/// - Server configuration synchronization
/// - Configuration lifecycle management
/// - Integration with BrandConfig, FeatureConfig, and ThemeConfig
///
/// The configuration system follows a two-tier approach:
/// 1. **Local Configuration**: Bundled with the app, loaded on first launch
/// 2. **Server Configuration**: Fetched from remote server, overrides local settings
///
/// Configuration Flow:
/// 1. App launches → AppConfig.shared initializes
/// 2. Local configs loaded (BrandConfig, FeatureConfig, ThemeConfig)
/// 3. `requestAndLoadConfigFromServer()` fetches latest from server
/// 4. Server configs override local settings
/// 5. Map feeds and mode lists are updated
///
/// Example:
/// ```swift
/// // Initialize configuration system
/// AppConfig.shared.initialization()
///
/// // Fetch latest configuration from server
/// AppConfig.shared.requestAndLoadConfigFromServer { isUpdated in
///     if isUpdated {
///         print("Configuration updated from server")
///     }
/// }
/// ```
public class AppConfig {

	/// Keys for storing configuration-related data in UserDefaults.
	///
	/// These keys track device identity, configuration versions, and app lifecycle:
	/// - `device_id`: Unique identifier for this device installation
	/// - `current_server_config_revision`: Version of server config currently in use
	/// - `first_install_app_timestamp`: When the app was first installed
	/// - `customized_configuration_url`: Custom server URL if configured
	/// - `current_app_version`: Current app version string
	/// - `last_update_app_timestamp`: When the app was last updated
	/// - `current_app_build`: Current build number
	/// - `original_configuration_url`: Default server configuration URL
	public enum UserDefaultKey: String {
		case device_id = "device_id"
		case current_server_config_revision = "current_server_config_revision"
		case first_install_app_timestamp = "first_install_app_timestamp"
		case customized_configuration_url = "customized_configuration_url"
		case current_app_version = "current_app_version"
		case last_update_app_timestamp = "last_update_app_timestamp"
		case current_app_build = "current_app_build"
		case original_configuration_url = "original_configuration_url"
	}

	/// Shared singleton instance of AppConfig.
	///
	/// This instance is lazily initialized and automatically loads all
	/// configuration managers (BrandConfig, FeatureConfig, ThemeConfig)
	/// during initialization.
	///
	/// - Important: Always use this shared instance to ensure consistent
	///   configuration state across the app.
	public static let shared : AppConfig = {
		let mgr = AppConfig()
        let _ = BrandConfig.shared
        let _ = FeatureConfig.shared
        let _ = ThemeConfig.shared
		return mgr
	}()

	/// Indicates whether server configuration has been successfully fetched and applied.
	///
	/// This flag is set to `true` after a successful server configuration update.
	/// Use this to determine if the app is using server-provided settings or
	/// only local defaults.
    var serverConfigUpdated = false

	/// Retrieves or generates a unique device identifier.
	///
	/// The device ID is used for:
	/// - Analytics and tracking
	/// - Device-specific configuration
	/// - User session management
	///
	/// The ID is generated from:
	/// 1. Device's vendor identifier (UUID)
	/// 2. Current timestamp (fallback if UUID unavailable)
	/// 3. App identifier suffix
	///
	/// The generated ID is stored in PreferenceManager and persists across app launches.
	///
	/// - Returns: A unique device identifier string
	///
	/// Example format: `"550E8400-E29B-41D4-A716-446655440000-st"`
    func deviceId() -> String {
        if let deviceId: String = PreferenceManager.object(forKey: UserDefaultKey.device_id.rawValue) {
            return deviceId
        }
        
        let newDeviceId = (UIDevice.current.identifierForVendor?.uuidString ?? "\(Date().timeIntervalSince1970)") + "-" + BrandConfig.shared.app_identifier.replaceFirstOccurance(target: "sound-transit", replaceString: "st")
        PreferenceManager.set(newDeviceId, forKey: UserDefaultKey.device_id.rawValue)
        return newDeviceId
	}

	/// Initializes the configuration system.
	///
	/// This method is called during app startup to ensure all configuration
	/// managers are properly initialized. Currently a placeholder for future
	/// initialization logic.
	///
	/// - Note: Configuration managers (BrandConfig, FeatureConfig, ThemeConfig)
	///   are automatically initialized when AppConfig.shared is first accessed.
	public func initialization() {}

	/// Fetches the latest configuration from the server and updates local settings.
	///
	/// This method performs the following steps:
	/// 1. Requests configuration from the server via APIManager
	/// 2. Parses the response for brandInfo, theme, and feature configurations
	/// 3. Updates each configuration manager with server values
	/// 4. Persists updated configurations to disk
	/// 5. Triggers map feed updates (stops, parking, shared vehicles)
	/// 6. Fetches mode list if configured
	///
	/// Configuration Structure:
	/// ```json
	/// {
	///   "data": {
	///     "brandInfo": { ... },
	///     "theme": { ... },
	///     "feature": { ... }
	///   }
	/// }
	/// ```
	///
	/// - Parameter completion: Called when configuration update completes
	///   - Parameter isUpdated: `true` if configuration was successfully updated,
	///     `false` if using local configuration due to error
	///
	/// - Important: This method should be called early in the app lifecycle,
	///   typically in AppDelegate or SceneDelegate, to ensure the app uses
	///   the latest server configuration.
	///
	/// Example:
	/// ```swift
	/// AppConfig.shared.requestAndLoadConfigFromServer { isUpdated in
	///     if isUpdated {
	///         print("Using server configuration")
	///         // Refresh UI with new theme/features
	///     } else {
	///         print("Using local configuration")
	///     }
	/// }
	/// ```
	public func requestAndLoadConfigFromServer(completion:((_ isUpdated: Bool)->Void)? = nil){
		
		APIManager.shared.loadAppConfiguration { (configs, error) in
			var isUpdatedConfig = false
			if let errorMessage = error {
				OTPLog.log(info:"Server configuration loading failed, use local configuration instead, \(errorMessage)")
				completion?(isUpdatedConfig)
				return
			}else{
				// Update the local configuration.
				if let configs = configs?["data"] as? [String: Any] {
					isUpdatedConfig = true
					if let brandInfoCfg = configs["brandInfo"] as? [String: Any] {
						BrandConfig.shared.update(configs: brandInfoCfg)
						BrandConfig.shared.flush()
					}else{
						OTPLog.log(level: .warning, info: "Server brand info configuration missing")
					}
					
					if let themeCfg = configs["theme"] as? [String: Any] {
						ThemeConfig.shared.update(configs: themeCfg)
						ThemeConfig.shared.flush()
					}else{
						OTPLog.log(level: .warning, info: "Server theme info configuration missing")
					}
					
					if let featureCfg = configs["feature"] as? [String: Any] {
						FeatureConfig.shared.update(configs: featureCfg)
						FeatureConfig.shared.flush()
					}else{
						OTPLog.log(level: .warning, info: "Server feature info configuration missing")
					}
					
				}else{
					var messageFromResponse = ""
					if let serverMessage = configs?["message"] as? String {
						messageFromResponse = serverMessage
					}
					OTPLog.log(level: .warning, info: "Server returns empty config response. \(messageFromResponse)")
				}
                self.serverConfigUpdated = true
                if !MapManager.shared.loadStopsFirstTime {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        MapManager.shared.updateSharedVehiclesFeeds()
                        MapManager.shared.updateParkingAndRidesFeeds()
                        MapManager.shared.updateTransitStopFeeds()
                        MapManager.shared.loadStopsFirstTime = true
                    }
                }
			}
            // directly make request to prepare the all most list from configuration.
            if FeatureConfig.shared.all_mode_list_url.count > 0 {
                APIManager.shared.loadAllModeList(url: FeatureConfig.shared.all_mode_list_url){ modes in
                    FeatureConfig.shared.allModesList = modes
                    FeatureConfig.shared.computeUsedModes()
                    completion?(isUpdatedConfig)
                }
            }else{
                completion?(isUpdatedConfig)
            }
		}
	}
	
}
