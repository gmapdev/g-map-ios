//
//  TripPlan+Extensions.swift
//

import SwiftUI
import MapKit

extension TimeInterval {
    /// Formatted date.
    /// - Parameters:
    ///   - format: Parameter description
    /// - Returns: String
    func formattedDate(format: String) -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateformat = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateformat.locale = Locale(identifier: language.languageCode())
        dateformat.timeZone = EnvironmentManager.shared.currentTimezone
        dateformat.dateFormat = format
        return dateformat.string(from: date)
    }
    
    /// Short date.
    /// - Parameters:
    ///   - String: Parameter description
    var shortDate: String {
        return self.formattedDate(format: "MMM dd, yyyy")
    }
    
    /// Format
    /// - Returns: String
    /// Formats.
    func format() -> String {
        var time: TimeInterval = self
        time = floor(time/60)

        let hours = Int(time)/60
        let minutes = Int(time)%60
        var totalTime = ""
        if hours > 0 {
            totalTime = "%1 hr".localized(hours)
        }
        if minutes > 0 {
            totalTime += (hours > 0 ? " " : "") + "%1 min".localized(minutes)
        }else {
            totalTime += (hours > 0 ? " " : "") + "%1 min".localized("0")
        }

        return totalTime
    }
    
    /// Format.
    /// - Parameters:
    ///   - units: Parameter description
    /// - Returns: String
    func format(units: NSCalendar.Unit) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = units
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? ""
    }
    
    /// Time
    /// - Returns: String
    /// Time.
    func time() -> String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }
    
    /// Milli seconds time.
    /// - Parameters:
    ///   - delay: Parameter description
    /// - Returns: String
    func milliSecondsTime(delay: Double = 0) -> String {
		let date = Date(timeIntervalSince1970: self/1000)
        let newDate = date.addingTimeInterval(-delay)
		let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
		dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
		dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: newDate)
    }
    
    /// Convert seconds to minutes and seconds
    /// - Returns: String
    /// Converts seconds to minutes and seconds.
    func convertSecondsToMinutesAndSeconds() -> String {
            let minutes = Int(self) / 60
            let remainingSeconds = Int(self) % 60
            return String(format: "%01d min %02d sec", minutes, remainingSeconds)
        }
    
	// MARK: - for converting time interval to Local Time zone. = Current Time
 /// Milli seconds time to local zone.
 /// - Parameters:
 ///   - delay: Double = 0
 /// - Returns: String
	func milliSecondsTimeToLocalZone(delay: Double = 0) -> String {
		let date = Date(timeIntervalSince1970: self/1000)
		let newDate = date.addingTimeInterval(-delay)
		let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
		dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
		dateFormatter.dateFormat = "h:mm a"
		return dateFormatter.string(from: newDate)
	}
    // MARK: - for converting time interval to Config's preset Timezone
    /// Milli seconds time to config time zone.
    /// - Parameters:
    ///   - delay: Double = 0
    /// - Returns: String
    func milliSecondsTimeToConfigTimeZone(delay: Double = 0) -> String {
        let date = Date(timeIntervalSince1970: self/1000)
        let newDate = date.addingTimeInterval(-delay)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: newDate)
    }
    
    /// Milli seconds date
    /// - Returns: String
    /// Milli seconds date.
    func milliSecondsDate() -> String {
        let date = Date(timeIntervalSince1970: self/1000)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
}

extension Direction {
    /// Image.
    /// - Parameters:
    ///   - String: Parameter description
    var image: String {
        switch self {
        case .depart: return "direction_straight_icon"
        case .left: return "direction_left_icon"
        case .right: return "direction_right_icon"
        case .north: return "direction_straight_icon"
        case .east: return "direction_right_icon"
        case .south: return "direction_down_icon"
        case .west: return "direction_left_icon"
        case .northEast: return "direction_right_slight_icon"
        case .northWest: return "direction_left_slight_icon"
        case .southWest: return "direction_left_hard_icon"
        case .southEast: return "direction_right_hard_icon"
        case .uturnRight: return "direction_turn_right_icon"
        case .uturnLeft: return "direction_turn_left_icon"
        case .hardLeft: return "direction_left_hard_icon"
        case .hardRight: return "direction_right_hard_icon"
        case .slightlyLeft: return "direction_left_slight_icon"
        case .slightlyRight: return "direction_right_slight_icon"
        case .continueOn: return "direction_straight_icon"
        case .unknown: return ""
        }
    }
}

extension LegGeometry {
    /// Coordinates.
    /// - Parameters:
    ///   - [CLLocationCoordinate2D]: Parameter description
    var coordinates: [CLLocationCoordinate2D] {
        let polyline = Polyline(encodedPolyline: points)
        return polyline.coordinates ?? []
    }
    
    /// Polyline.
    /// - Parameters:
    ///   - Polyline: Parameter description
    var polyline: Polyline {
        return Polyline(encodedPolyline: points)
    }
}
