//
//  ThemeConfig.swift
//

import Foundation
import SwiftUI
import UIKit

public enum ThemeSkinType: String {
    case lightModeSkin = "Light"
    case darkModeSkin = "Dark"
    case template = "Template"
}

public class ThemeConfig: ConfigInterface {
	
	private var configs: [String: Any] = [:]
 /// Label: "com.ibigroup.theme.lock"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - label: "com.ibigroup.theme.lock"
	private var configLock = DispatchQueue.init(label: "com.ibigroup.theme.lock")
	
 /// Shared.
 /// - Parameters:
 ///   - ThemeConfig: Parameter description
	public static var shared: ThemeConfig = {
		let mgr = ThemeConfig()
		mgr.loadConfig()
		return mgr
	}()
	
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
	
 /// Update.
 /// - Parameters:
 ///   - configs: Parameter description
 /// Updates.
	override public func update(configs: [String: Any]){
		configLock.sync {
			self.configs = configs
		}
	}
 /// Flush
 /// Flush.
	override public func flush() {
		configLock.sync {
			do{
				let configJSONData = try JSONSerialization.data(withJSONObject: self.configs, options: .fragmentsAllowed)
				let configDocURLPath = OTPUtils.docPath("theme_cfg.json")
				let jsonString = String(data: configJSONData, encoding: .utf8) ?? "Unknown"
				let encryptedData = IBISecurity.encrypt(jsonString)
				try encryptedData.write(toFile: configDocURLPath.path, atomically: true, encoding: .utf8)
			}catch{
				OTPLog.log(level: .error, info: "Can not flush themes configuration to disk, \(error.localizedDescription)")
			}
		}
	}
	
	/// Define the primary color. normally, this is the color in the navigation background, menu background and so on
	public var primary_color: Color {
		return colorForKey("primary_color", defaultColor:  "#ff7900")
	}
	
 /// Primary_uicolor.
 /// - Parameters:
 ///   - UIColor: Parameter description
	public var primary_uicolor: UIColor {
		return uiColorForKey("primary_color", defaultColor:  "#ff7900")
	}
    
    /// Plan_trip_button_in_search_font_color.
    /// - Parameters:
    ///   - Color: Parameter description
    public var plan_trip_button_in_search_font_color: Color {
        return colorForKey("plan_trip_button_in_search_font", defaultColor:  "#FFFFFF")
    }
    
    /// Plan_trip_button_in_search_bg_color.
    /// - Parameters:
    ///   - Color: Parameter description
    public var plan_trip_button_in_search_bg_color: Color {
        return colorForKey("plan_trip_button_in_search_bg", defaultColor:  "#008000")
    }
    
	
	/// This is a helper function to retrieve the color key to a Color value.
 /// Color for key.
 /// - Parameters:
 ///   - key: String
 ///   - defaultColor: String
 /// - Returns: Color
	private func colorForKey(_ key: String, defaultColor: String) -> Color {
        if let hex = getHexCode(key){
            /// Hex: hex
            return Color.init(hex: hex)
        }
  /// Hex: default color
  /// Initializes a new instance.
  /// - Parameters:
  ///   - hex: defaultColor
		return Color.init(hex: defaultColor)
	}
    
    
    /// Get hex code.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String?
    private func getHexCode(_ key: String) -> String?{
        var currentThemeCode  = "Light"
        
        if UITraitCollection.current.userInterfaceStyle == .light {
            currentThemeCode =  ThemeSkinType.lightModeSkin.rawValue
        }else{
            currentThemeCode = ThemeSkinType.darkModeSkin.rawValue
        }
        
        if let theme = self.configs["Template"] as? [String : Any]{
            if let appTheme = theme[currentThemeCode] as? [String: Any], let colorTheme = appTheme["color"] as? [String: Any]{
                let color = colorTheme[key+"_color"] as? String
                return color
            }
        }
        return nil
    }
	
	/// This is a helper function to retrieve the color key to a Color value.
 /// Ui color for key.
 /// - Parameters:
 ///   - key: String
 ///   - defaultColor: String
 /// - Returns: UIColor
	private func uiColorForKey(_ key: String, defaultColor: String) -> UIColor {
		return UIColor.black
	}
}
