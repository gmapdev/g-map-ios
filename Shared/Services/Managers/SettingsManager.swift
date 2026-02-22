//
//  SettingsManager.swift
//

import Foundation
import SwiftUI

/// Used to define the type of the settings item
enum SettingsType: String {
	case toggle = "toggle"
	case button = "button"
	case languagePicker = "languagePicker"
}

enum SettingsKey: String, CaseIterable{
	case appLanguage = "Settings - App Language"
 /// To string
 /// - Returns: String
 /// To string.

 /// - Returns: String
	func toString() -> String {
		switch self {
			case .appLanguage: return "App Language"
		}
	}
	
 /// To description
 /// - Returns: String
 /// To description.
	func toDescription() -> String{
		switch self {
			case .appLanguage: return ""
		}
	}
}

enum AppLanguageType : String {
	
	case english = "english"
    case spanish = "spanish"
    case korean = "korean"
    case vietnamese = "vietnamese"
    case chinese = "chinese"
    case russian = "russian"
    case tagalog = "tagalog"
	
 /// Language code
 /// - Returns: String
 /// Language code.
	public func languageCode() -> String {
		var languageCode = ""
		switch self {
		case .english:
			languageCode = "en"
        case .spanish:
            languageCode = "es"
        case .korean:
            languageCode = "ko"
        case .vietnamese:
            languageCode = "vi"
        case .chinese:
            languageCode = "zh"
        case .russian:
            languageCode = "ru"
        case .tagalog:
            languageCode = "tl"
        }
		return languageCode
	}
	
 /// Description
 /// - Returns: String
 /// Description.
	public func description()->String{
		var description = ""
		switch self {
		case .english:
			description = "English"
        case .spanish:
            description = "Spanish"
        case .korean:
            description = "Korean"
        case .vietnamese:
            description = "Vietnamese"
        case .chinese:
            description = "Chinese"
        case .russian:
            description = "Russian"
        case .tagalog:
            description = "Tagalog"
		}
		return description
	}
}


/// The struct which is used
struct SettingsItem: Identifiable {
	
	var key: String
	var id: String = UUID().uuidString
	var name: String
	var des: String = ""
	var type: SettingsType
	var iconName: String
	var isOn: Bool //shared with optionPicker:default:false(not using)
	
	// MARK: OptionPicker
	var optionPickerSelection : Int = 0
	
	// MARK: Toggle,Button
 /// Initializes a new instance.
 /// - Parameters:
 ///   - key: String
 ///   - name: String
 ///   - des: String
 ///   - type: SettingsType
 ///   - iconName: String
 ///   - isOn: Bool
	init(key: String, name:String,des: String, type: SettingsType,iconName: String, isOn: Bool) {
		self.key = key
		self.name = name
		self.des = des
		self.type = type
		self.iconName = iconName
		self.isOn = isOn
	}
	
	// MARK: OptionPicker
 /// Initializes a new instance.
 /// - Parameters:
 ///   - key: String
 ///   - name: String
 ///   - des: String
 ///   - type: SettingsType
 ///   - iconName: String
 ///   - selection: Int
	init(key: String, name:String,des: String, type: SettingsType,iconName: String, selection:Int) {
		self.key = key
		self.name = name
		self.des = des
		self.type = type
		self.iconName = iconName
		self.isOn = false
		self.optionPickerSelection = selection
	}
}

class SettingsManager: ObservableObject {
	
	@Published var pubSettings = [SettingsItem]()
	
	@Published var pubLastUpdatedTimestamp = Date().timeIntervalSince1970
	
	@Published var pubIsPresentAppLanguageView: Bool = false
	
	@Published var pubAppLanguageSelection : Int = 0
	
	
	/// List all possible and available language here
    var languages : [AppLanguageType] = [.english, .spanish, .korean, .vietnamese, .chinese]
	
 /// Shared.
 /// - Parameters:
 ///   - SettingsManager: Parameter description
	public static var shared: SettingsManager = {
		let mgr = SettingsManager()
		return mgr
	}()
	
 /// Initializes a new instance.
	init() {
		
	}
	
 /// Settings button triggered.
 /// - Parameters:
 ///   - key: Parameter description
	public func settingsButtonTriggered(key: SettingsKey){
		if key == .appLanguage {
			DispatchQueue.main.async {
				withAnimation {
					SettingsManager.shared.pubIsPresentAppLanguageView = true
				}
			}
		}
	}
	
 /// Update
 /// Updates.
	public func update() {
		var settingsItems = [SettingsItem]()
	
		self.pubAppLanguageSelection = 0
		if let foundIndex = self.languages.firstIndex(of: SettingsManager.shared.appLanguage) {
			self.pubAppLanguageSelection = foundIndex
		}
		
		settingsItems.append(SettingsItem(key: SettingsKey.appLanguage.rawValue,name: SettingsKey.appLanguage.toString(), des:"", type: .languagePicker, iconName: "ic_language", selection: self.pubAppLanguageSelection))
		
		DispatchQueue.main.async {
			self.pubSettings.removeAll()
			self.pubSettings += settingsItems
		}
	}
	
 /// Save all settings status
 /// Saves all settings status.
	public func saveAllSettingsStatus() {
		let settingsCopy = self.pubSettings
		for i in 0..<settingsCopy.count {
			let setting = settingsCopy[i]
			PreferenceManager.set(setting.isOn, forKey: setting.key)
		}
	}
	
 /// App language.
 /// - Parameters:
 ///   - AppLanguageType: Parameter description
	public var appLanguage: AppLanguageType {
		
		get {
            guard let selectedValue:String = Locale.current.languageCode else {
                return .english
			}
			
			var appLanguage = "en-CA"
			if Locale.preferredLanguages.count > 0 {
				appLanguage = Locale.preferredLanguages[0]
                if appLanguage.lowercased().contains("es") {
                    return .spanish
                } else if appLanguage.lowercased().contains("ko") {
                    return .korean
                } else if appLanguage.lowercased().contains("vi") {
                    return .vietnamese
                } else if appLanguage.lowercased().contains("zh") {
                    return .chinese
                } else if appLanguage.lowercased().contains("ru") {
                    return .russian
                } else if appLanguage.lowercased().contains("tl") {
                    return .tagalog
                } else if appLanguage.lowercased().contains("fil") {
                    return .tagalog  
                }
                else {
                    return .english
                }
			}
			
			let language = AppLanguageType(rawValue: selectedValue) ?? .english
			return language
		}
			
		set(newValue) {
			PreferenceManager.set(newValue.rawValue, forKey: AppSession.UserDefaultKey.app_language.rawValue)
		}
	}
}
