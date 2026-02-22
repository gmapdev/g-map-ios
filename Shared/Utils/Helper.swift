//
//  Helper.swift
//

import Foundation
import UIKit
import SwiftUI

/// Utility class providing common helper functions used throughout the app.
///
/// Helper provides a collection of utility methods for:
/// - Color conversion and manipulation
/// - UI layout calculations
/// - Agency name mapping
/// - View height calculations
///
/// This singleton class is used across the app for consistent utility
/// function access.
///
/// Example:
/// ```swift
/// let hexColor = Helper.shared.hexStringFromColor(color: .blue)
/// let height = Helper.shared.getDefaultMapViewHeight()
/// ```
class Helper: ObservableObject {

    /// Shared singleton instance of Helper.
    ///
    /// Use this instance throughout the app for utility functions.
    static var shared: Helper = {
        let instance = Helper()
        return instance
    }()

    /// Converts a UIColor to its hexadecimal string representation.
    ///
    /// This method extracts RGB components from a UIColor and formats them
    /// as a hex string (e.g., "#FF0000" for red).
    ///
    /// - Parameter color: The UIColor to convert
    /// - Returns: Hex string representation (e.g., "#FF0000"), or empty string if conversion fails
    ///
    /// Example:
    /// ```swift
    /// let hex = Helper.shared.hexStringFromColor(color: .red)
    /// // Returns: "#FF0000"
    /// ```
    public func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        if let components = components{
            for i in 0..<components.count{
                if i == 0{
                    r = components[i]
                }else if i == 1{
                    g = components[i]
                }else{
                    b = components[i]
                }
            }
            /// Format: "#%02l x%02l x%02l x", lroundf( float(r * 255)), lroundf( float(g * 255)), lroundf( float(b * 255))
            /// Initializes a new instance.
            /// - Parameters:
            ///   - format: "#%02lX%02lX%02lX"
            let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
            OTPLog.log(level: .info, info: hexString)
            return hexString
        }else{
            return ""
        }

    }

    /// Calculates the default view height for bottom slide bar positions.
    ///
    /// This method determines the appropriate height for views based on their
    /// position in the bottom slide bar (top, middle, or bottom).
    ///
    /// - Parameter heightPosition: The position of the view in the slide bar
    /// - Returns: The calculated height in points
    ///
    /// Height Calculations:
    /// - `.top`: 1/6 of available space
    /// - `.middle`: 1/2 of available space
    /// - `.bottom`: 85% of available space
    ///
    /// Example:
    /// ```swift
    /// let height = Helper.shared.getDeafultViewHeight(heightPosition: .middle)
    /// ```
    public func getDeafultViewHeight(heightPosition: BottomSlideBarPosition)-> CGFloat{
        let yVal = Helper.shared.getDefaultMapViewHeight() - ScreenSize.safeTop()
        switch heightPosition{
        case .top: return yVal / 6
        case .middle: return yVal / 2
        case .bottom:
            return yVal * (1 - 0.15)
        }
    }

    /// Maps an agency name to its configured alias.
    ///
    /// Some transit agencies have long or complex names that need to be
    /// shortened or simplified for display. This method looks up the
    /// configured alias from FeatureConfig.
    ///
    /// - Parameter agencyName: The original agency name
    /// - Returns: The alias if configured, otherwise the original name
    ///
    /// Example:
    /// ```swift
    /// let displayName = Helper.shared.mapAgencyNameAliase(agencyName: "Metropolitan Transit Authority")
    /// // Returns: "MTA" (if configured)
    /// ```
    public func mapAgencyNameAliase(agencyName: String) -> String {
        let nameAliases = FeatureConfig.shared.route_agency_name_mapping
        for aliase in nameAliases{
            if agencyName == aliase.name{
                return aliase.aliase
            }
        }
        return agencyName
    }

    /// Calculates the default height for the map view.
    ///
    /// The map view height varies based on the app state:
    /// - **Live Route Active (Preview Mode)**: 40% of screen height minus safe area
    /// - **Live Route Active (Navigation Mode)**: Full screen height
    /// - **Normal Mode**: Full screen minus bottom tab bar and safe area
    ///
    /// - Returns: The calculated map view height in points
    ///
    /// Example:
    /// ```swift
    /// let mapHeight = Helper.shared.getDefaultMapViewHeight()
    /// ```
    public func getDefaultMapViewHeight() -> CGFloat{
        if LiveRouteManager.shared.pubIsRouteActivated {
			if LiveRouteManager.shared.pubIsPreviewMode {
				return UIScreen.main.bounds.size.height * 0.4 - ScreenSize.safeTop() - 70
			}
            return UIScreen.main.bounds.size.height
        }else{
            let bottomSpace = 80 + ScreenSize.safeBottom()
            return UIScreen.main.bounds.size.height - bottomSpace
        }
    }

    /// Determines the best contrasting color (black or white) for a given background color.
    ///
    /// This method calculates the relative luminance of the background color
    /// and returns either black or white text color for optimal readability.
    ///
    /// Uses the WCAG relative luminance formula:
    /// L = 0.2126 * R + 0.7152 * G + 0.0722 * B
    ///
    /// - Parameter hexColor: Hex color string (e.g., "#FF0000")
    /// - Returns: `.black` for light backgrounds, `.white` for dark backgrounds
    ///
    /// Example:
    /// ```swift
    /// let textColor = Helper.shared.getContrastColor(hexColor: "#FF0000")
    /// // Returns: .white (red is dark enough for white text)
    /// ```
    public func getContrastColor(hexColor: String) -> Color{
        // Consolidate non-hex color and hex color
        var replacedHexColor = hexColor.replacingOccurrences(of: "#", with: "")
        if replacedHexColor.count < 6 {
            return Color.gray
        }else if replacedHexColor.count == 6{
            replacedHexColor = replacedHexColor + "FF"
        }
        let defaultColor = UIColor(hex: "#\(replacedHexColor)")
        var red:CGFloat = 0, green:CGFloat = 0, blue:CGFloat = 0, alpha: CGFloat = 0
        if let success = defaultColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha), success {
            red = red * 255
            green = green * 255
            blue = blue * 255
            let yiq = ((red * 299) + (green * 587) + (blue * 114))/1000
            return yiq >= 128 ? Color.black : Color.white
        }
        return Color.gray
    }
    
    /// Format readable mins.
    /// - Parameters:
    ///   - mins: Parameter description
    /// - Returns: String
    public func formatReadableMins(mins: Int) -> String {
        if mins == 1 { return "%1 min".localized("1") }
        if mins > 1 && mins < 60{
            return "%1 min".localized(mins)
        }
        if mins >= 60 {
            let hrs = mins/60
            let mins = mins%60
            var hrsSuffix = "hour".localized()
            var minsSuffix = "min".localized()
            if hrs == 1 { hrsSuffix = "hour".localized() }
            if mins == 1 { minsSuffix = "min".localized()}
            if mins == 0 {
                return "\(hrs) \(hrsSuffix)"
            }
            return "\(hrs) \(hrsSuffix) \(mins) \(minsSuffix)"
        }
        return "%1 min".localized(mins)
    }
    
    /// Create date.
    /// - Parameters:
    ///   - year: Parameter description
    ///   - month: Parameter description
    ///   - day: Parameter description
    ///   - HH: Parameter description
    ///   - mm: Parameter description
    ///   - ss: Parameter description
    /// - Returns: Date
    public func createDate(year: Int = 1990, month: Int = 1, day: Int = 1, HH: Int = 0, mm: Int = 0, ss: Int = 0) -> Date{
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = HH
        dateComponents.minute = mm
        dateComponents.second = ss
        let userCalendar = Calendar(identifier: .gregorian)
        let date = userCalendar.date(from: dateComponents)
        return date ?? Date()
    }
    
    /// Extract y m d.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: (Int, Int, Int)
    public func extractYMD(from: String)->(Int, Int, Int){
        let dateComps = from.split(separator: " ")
        if dateComps.count>=1 {
            let comps = dateComps[0].split(separator: "-")
            if comps.count > 2 {
                let year = Int(comps[0]) ?? 1990
                let month = Int(comps[1]) ?? 1
                let day = Int(comps[2]) ?? 1
                return (year, month, day)
            }
        }
        return (1990, 1, 1)
    }
    
    /// Regex matches.
    /// - Parameters:
    ///   - for: Parameter description
    ///   - in: Parameter description
    /// - Returns: [String]
    public func regexMatches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            OTPLog.log(level: .error, info: "invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Extract substring.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - regex: Parameter description
    /// - Returns: String?
    func extractSubstring(_ input: String, regex: String) -> String? {
        let regexPattern = regex
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
            
            if let match = matches.first, match.numberOfRanges == 2 {
                let range = match.range(at: 1)
                if let swiftUISubstringRange = Range(range, in: input) {
                    return String(input[swiftUISubstringRange])
                }
            }
        } catch {
            OTPLog.log(level: .error, info: "Error creating regular expression: \(error)")
        }

        return nil
    }
    
    /// Is valid email.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Validate phone number.
    /// - Parameters:
    ///   - _: Parameter description
    /// Validates phone number.
    func validatePhoneNumber(_ phoneNumber: String) {
        let number = self.unmaskPhoneNumber(phoneNumber)
        if number.contains("+1") && number.count == 12 {
            ProfileManager.shared.pubValidPhoneNumberLimit = true
        }else{
            ProfileManager.shared.pubValidPhoneNumberLimit = false
        }
    }
    
    /// Format phone number.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    public func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if cleanedPhoneNumber.count > 11 {
            return cleanedPhoneNumber
        }
        
        let isInternational = cleanedPhoneNumber.hasPrefix("1")
        let mask = isInternational ? "# (###) ###-####" : "(###) ###-####"
        
        var result = ""
        var index = cleanedPhoneNumber.startIndex
        
        for character in mask where index < cleanedPhoneNumber.endIndex {
            if character == "#" {
                result.append(cleanedPhoneNumber[index])
                index = cleanedPhoneNumber.index(after: index)
            } else {
                result.append(character)
            }
        }
        
        return result
    }
    
    /// Unmask phone number.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    func unmaskPhoneNumber(_ maskedPhoneNumber: String) -> String {
        let unmaskedPhoneNumber = maskedPhoneNumber.filter { $0.isNumber }
        
        if unmaskedPhoneNumber.count == 10 && !unmaskedPhoneNumber.hasPrefix("1"){
            return "+1\(unmaskedPhoneNumber)"
        }else if unmaskedPhoneNumber.count == 10 && unmaskedPhoneNumber.hasPrefix("1"){
            return "+\(unmaskedPhoneNumber)"
        }else if unmaskedPhoneNumber.count > 10 && unmaskedPhoneNumber.hasPrefix("1") {
            return "+\(unmaskedPhoneNumber)"
        }else if unmaskedPhoneNumber.count > 10 && unmaskedPhoneNumber.hasPrefix("+") {
            return unmaskedPhoneNumber
        }
        
        return unmaskedPhoneNumber
    }
    
    /// Get user preferred settings
    /// - Returns: ([SearchMode]?, [SearchMode]?, Bool, Bool, TripSearchSettingsItem, Bool, Bool)
    /// Retrieves user preferred settings.
    func getUserPreferredSettings() -> ([SearchMode]?, [SearchMode]?, Bool, Bool, TripSearchSettingsItem, Bool, Bool) {
        var pickerItem: TripSearchSettingsItem = TripSearchSettingsItem.item(for: .walkSpeed)
        let isAvoidWalkingSelected = UserDefaults.standard.bool(forKey: "isAvoidWalkingSelected")
        let isAccessibleRoutingSelected = UserDefaults.standard.bool(forKey: "isAccessibleRoutingSelected")
        let isAllowBikeRentalSelected = UserDefaults.standard.bool(forKey: "isAllowBikeRentalSelected", defaultValue: true)
        let isAllowScooterRentalSelected = UserDefaults.standard.bool(forKey: "isAllowScooterRentalSelected", defaultValue: true)
        if let pickerJSONData = UserDefaults.standard.data(forKey: "pickerListItem") {
            let decoder = JSONDecoder()
            do {
                let collectionData = try decoder.decode(TripSearchSettingsItem.self, from: pickerJSONData)
                pickerItem = collectionData
            } catch {
                OTPLog.log(level: .error, info: "Error decoding user data: \(error.localizedDescription)")
            }
        }
        
        var modeFilterCollectionData: [SearchMode] = []
        if let modeFilterCollection = UserDefaults.standard.data(forKey: "pubModeFilterCollection") {
            let decoder = JSONDecoder()
            do {
                let collectionData = try decoder.decode([SearchMode].self, from: modeFilterCollection)
                modeFilterCollectionData = collectionData
            } catch {
                OTPLog.log(level: .error, info: "Error decoding user data: \(error.localizedDescription)")
            }
        }
        
        var subModeFilterCollectionData: [SearchMode] = []
        if let subModeFilterCollection = UserDefaults.standard.data(forKey: "pubSubModeFilterCollection") {
            let decoder = JSONDecoder()
            do {
                let collectionData = try decoder.decode([SearchMode].self, from: subModeFilterCollection)
                subModeFilterCollectionData = collectionData
            } catch {
                OTPLog.log(level: .error, info: "Error decoding user data: \(error.localizedDescription)")
            }
        }
        
        return (modeFilterCollectionData, subModeFilterCollectionData, isAvoidWalkingSelected, isAccessibleRoutingSelected, pickerItem, isAllowBikeRentalSelected, isAllowScooterRentalSelected)
    }
    
    /// Save user preferred settings
    /// Saves user preferred settings.
    func saveUserPreferredSettings(){
        let encoder = JSONEncoder()
        do {
            let modeFilterCollectionJSON = try encoder.encode(TripPlanningManager.shared.pubModeFilterCollection)
            let subModeFilterCollectionJSON = try encoder.encode(TripPlanningManager.shared.pubSubModeFilterCollection)
            let itemJsonData = try encoder.encode(PickerListViewModel.shared.item)
            UserDefaults.standard.set(itemJsonData, forKey: "pickerListItem")
            UserDefaults.standard.set(modeFilterCollectionJSON, forKey: "pubModeFilterCollection")
            UserDefaults.standard.set(subModeFilterCollectionJSON, forKey: "pubSubModeFilterCollection")
            UserDefaults.standard.set(TripSettingsViewModel.shared.isAvoidWalkingSelected, forKey: "isAvoidWalkingSelected")
            UserDefaults.standard.set(TripSettingsViewModel.shared.isAccessibleRoutingSelected, forKey: "isAccessibleRoutingSelected")
            UserDefaults.standard.set(TripSettingsViewModel.shared.isAllowBikeRentalSelected, forKey: "isAllowBikeRentalSelected")
            UserDefaults.standard.set(TripSettingsViewModel.shared.isAllowScooterRentalSelected, forKey: "isAllowScooterRentalSelected")
            UserDefaults.standard.synchronize()
        } catch {
            OTPLog.log(level: .error, info: "Error encoding user data: \(error.localizedDescription)")
        }
    }
    
    /// Get language code
    /// - Returns: String
    /// Retrieves language code.
    func getLanguageCode() -> String{
        let appLanguage = SettingsManager.shared.appLanguage
        switch appLanguage {
        case .english:
            return "en-US"
        case .spanish:
            return "es"
        case .korean:
            return "ko"
        case .vietnamese:
            return "vi"
        case .chinese:
            return "zh"
        case .russian:
            return "ru"
        case .tagalog:
            return "tl"
        }
    }
    
    /// Remove duplicates.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: [String]
    func removeDuplicates(from array: [String]) -> [String] {
        var uniqueArray = [String]()
        var seen = Set<String>()
        
        for string in array {
            if !seen.contains(string) {
                uniqueArray.append(string)
                seen.insert(string)
            }
        }
        
        return uniqueArray
    }
    
    /// Removes t duplicates.
    /// - Parameters:
    ///   - array: [T]
    /// - Returns: [T]
    func removeTDuplicates<T: Equatable>(from array: [T]) -> [T] {
        var uniqueArray = [T]()
        for element in array {
            if !uniqueArray.contains(element) {
                uniqueArray.append(element)
            }
        }
        return uniqueArray
    }
    
    /// Get formatted place text.
    /// - Parameters:
    ///   - feature: Parameter description
    /// - Returns: (String, [String])
    func getFormattedPlaceText(feature: Autocomplete.Feature) -> (String, [String]) {
        let secondaryLabels = feature.properties.secondaryLabels ?? []
        if let geo = feature.geometry {
            if geo.type == "custom" || geo.type == "dining" || geo.type == "home" || geo.type == "work" {
                return (feature.properties.label, secondaryLabels)
            }
        }
        var placeText = ""
        let properties = feature.properties
        if let layer = properties.layer, layer == AutoCompleteItemType.stopLocation.rawValue {
            placeText = properties.label
        } else {
            placeText = properties.name
        }
        if let street = properties.street {
            if !placeText.contains(street) {
                placeText.append(placeText.isEmpty ? street : ", " + street)
            }
        }
        if let neighbourhood = properties.neighbourhood { placeText.append(placeText.isEmpty ? neighbourhood : ", " + neighbourhood) }
        if let locality = properties.locality { placeText.append(placeText.isEmpty ? locality : ", " + locality) }
        if let regionA = properties.region_a { placeText.append(placeText.isEmpty ? regionA : ", " + regionA) }
        if placeText.isEmpty {
            placeText = feature.properties.label
        }
        
        return (placeText, secondaryLabels)
    }
    
    /// Remove parentheses and content.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: String
    func removeParenthesesAndContent(from input: String) -> String {
        let pattern = "\\*\\([^)]*\\)\\*"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }
        let range = NSRange(location: 0, length: input.utf16.count)
        let modifiedString = regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")

        if input.contains("*(") {
            OTPLog.log(level: .info, info: "input: \(input)")
            OTPLog.log(level: .info, info: "modifiedString: \(modifiedString)")
        }
        return modifiedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Difference in minutes.
    /// - Parameters:
    ///   - from: Parameter description
    ///   - to: Parameter description
    /// - Returns: Int
    func differenceInMinutes(from startDate: Date, to endDate: Date) -> Int {
        let difference = Calendar.current.dateComponents([.minute], from: startDate, to: endDate)
        return difference.minute ?? 0
    }
    
    /// Day name.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: String
    func dayName(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PDT")
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.dateFormat = "EEEE" // Format for full day name
        return dateFormatter.string(from: date)
    }
    
    /// Date in p d t.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: String
    func dateInPDT(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PDT")
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        let convertedDate = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "h:mm a"
        let convertedTime = dateFormatter.string(from: date)
        return convertedDate + " at ".localized() + convertedTime.uppercased()
    }
    
    /// Time in p d t.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: String
    func timeInPDT(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "PDT")
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.dateFormat = "h:mm a"
        return  dateFormatter.string(from: date).uppercased()
    }

    
    /// Format to local time zone date.
    /// - Parameters:
    ///   - date: Parameter description
    ///   - isTimezone: Parameter description
    /// - Returns: String
    func formatToLocalTimeZoneDate(date : Date, isTimezone: Bool = false) -> String{

        let dateformatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateformatter.locale = Locale(identifier: language.languageCode())
        if isTimezone {
            dateformatter.timeZone = EnvironmentManager.shared.currentTimezone
        }
        dateformatter.dateFormat = "yyyy-MM-dd"
        let date = dateformatter.string(from: date)
        
        return date
    }
    
    /// Format to local time zone time.
    /// - Parameters:
    ///   - time: Parameter description
    ///   - isTimezone: Parameter description
    /// - Returns: String
    func formatToLocalTimeZoneTime(time : Date, isTimezone: Bool = false) -> String{

        let timeformatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        timeformatter.locale = Locale(identifier: language.languageCode())
        timeformatter.dateFormat = "HH:mm"
        if isTimezone {
            timeformatter.timeZone = EnvironmentManager.shared.currentTimezone
        }
        let time = timeformatter.string(from: time)
        
        return time
    }
    
    /// Format time intervalto full date.
    /// - Parameters:
    ///   - timeInterval: Parameter description
    /// - Returns: String
    func formatTimeIntervaltoFullDate(timeInterval: Int?) -> String {
        var dateString = "N/A"
        if let timeIn = timeInterval{
            let timeIntervalAsDouble = TimeInterval(timeIn) / 1000.0
            let date = Date(timeIntervalSince1970: timeIntervalAsDouble)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM d, yyyy" // Format: Tuesday, October 1, 2024
            dateString = dateFormatter.string(from: date)
            
        }
            return dateString
    }
    /// Format time intervalto short date.
    /// - Parameters:
    ///   - timeInterval: Parameter description
    /// - Returns: String
    /// Formats time intervalto short date.
    func formatTimeIntervaltoShortDate(timeInterval: Int?) -> String {
        var dateString = "N/A"
        if let timeIn = timeInterval{
            let timeIntervalAsDouble = TimeInterval(timeIn) / 1000.0
            let date = Date(timeIntervalSince1970: timeIntervalAsDouble)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MM/dd/yyyy" // Format: Tuesday, 10/01/2024
            dateString = dateFormatter.string(from: date)
            
        }
            return dateString
    }
    /// Format local time zone dateto day date.
    /// - Parameters:
    ///   - date: Parameter description
    /// - Returns: String
    /// Formats local time zone dateto day date.
    func formatLocalTimeZoneDatetoDayDate(date: Date) -> String {
            
        let dateformatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateformatter.locale = Locale(identifier: language.languageCode())
        dateformatter.timeZone = EnvironmentManager.shared.currentTimezone
        
        dateformatter.dateFormat = "EEEE, MM/dd/yyyy" // Format: Tuesday, 10/01/2024
        let date = dateformatter.string(from: date)
        
        return date
    }
    
    /// Is in polygon.
    /// - Parameters:
    ///   - polygon: Parameter description
    ///   - location: Parameter description
    /// - Returns: Bool
    public func isInPolygon(polygon: [CLLocationCoordinate2D], location: CLLocation) -> Bool {
        guard polygon.count >= 3 else {
            return false
        }

        var isInside = false
        let pointLatitude = location.coordinate.latitude
        let pointLongitude = location.coordinate.longitude

        // Loop through each edge of the polygon
        for i in 0..<polygon.count {
            let vertex1 = polygon[i]
            let vertex2 = polygon[(i + 1) % polygon.count] // Wrap around to the first vertex at the end

            let v1Lat = vertex1.latitude
            let v1Lon = vertex1.longitude
            let v2Lat = vertex2.latitude
            let v2Lon = vertex2.longitude

            // Check if the point is within the Y range of the polygon edge
            if (v1Lat > pointLatitude) != (v2Lat > pointLatitude) {
                // Find the intersection point of the edge with the horizontal ray
                let intersectLon = v1Lon + (pointLatitude - v1Lat) * (v2Lon - v1Lon) / (v2Lat - v1Lat)

                // If the intersection is to the right of the point, flip the inside flag
                if pointLongitude < intersectLon {
                    isInside = !isInside
                }
            }
        }

        return isInside
    }
    
    /// Colour with hex string.
    /// - Parameters:
    ///   - hexString: Parameter description
    /// - Returns: UIColor
    func colourWithHexString(hexString: String) -> UIColor {
        var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    /// Formatted distance description.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - withLabel: Parameter description
    /// - Returns: String
    public func formattedDistanceDescription(_ distance: Double?, withLabel: Bool = false) -> String {
        guard let distanceInMeters = distance else {
            return ""
        }
        let distanceInFeet = distanceInMeters * 3.28084
        
        if distanceInFeet < 528 {
            return withLabel ? "Distance: \(String(format: "%.0f", distanceInFeet)) feet" : "\(String(format: "%.0f", distanceInFeet)) feet"
        } else {
            let miles = distanceInFeet / 5280.0
            return withLabel ? "Distance: \(String(format: "%.1f", miles)) miles" : "\(String(format: "%.1f", miles)) miles"
        }
    }
    
    func findSmallestElement(in array: [Int]) -> Int {
        guard var smallest = array.first else {
            return 0
        }

        for element in array {
            if element < smallest {
                smallest = element
            }
        }

        return smallest
    }

}
