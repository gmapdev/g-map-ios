//
//  Date+Extensions.swift
//

import Foundation

extension Date {
    /// Date param.
    /// - Parameters:
    ///   - String: Parameter description
    var dateParam: String {
        let formatter = DateFormatter()
        formatter.timeZone = EnvironmentManager.shared.currentTimezone
        formatter.dateFormat = "MMM d, yyyy"
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        return formatter.string(from: self)
    }
    
    /// Date param.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    func dateParam(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = EnvironmentManager.shared.currentTimezone
        formatter.dateFormat = format
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        return formatter.string(from: self)
    }
    
    /// Time param.
    /// - Parameters:
    ///   - String: Parameter description
    var timeParam: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = EnvironmentManager.shared.currentTimezone
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        return formatter.string(from: self)
    }
    
    /// Time
    /// - Returns: String
    /// Time.
    func time() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "hh:mm a"
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        return dateFormatter.string(from: self)
    }
    
    /// Time for stop viewer
    /// - Returns: String
    /// Time for stop viewer.
    func timeForStopViewer() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "hh:mm a"
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        return dateFormatter.string(from: self)
    }
    
    /// Today midnight.
    /// - Parameters:
    ///   - Date: Parameter description
    static var todayMidnight: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    /// Midnight.
    /// - Parameters:
    ///   - Date: Parameter description
    var midnight: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Display date.
    /// - Parameters:
    ///   - type: Parameter description
    /// - Returns: String
    func displayDate(type: TripTimeSettingsItem) -> String {
        if isToday {
            return "Today".localized()
        } else if isYesterday {
            return "Yesterday".localized()
        } else if isTomorrow {
            return "Tomorrow".localized()
        } else {
            return self.dateParam
        }
    }
    
    /// Display time.
    /// - Parameters:
    ///   - type: Parameter description
    /// - Returns: String
    func displayTime(type: TripTimeSettingsItem) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "MMM dd, yyyy"
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        var date = ""
                if self.isToday{
                    date = "Today".localized()
                }else if self.isTomorrow{
                    date = "Tomorrow".localized()
                }else if self.isYesterday{
                    date = "Yesterday".localized()
                }else{
                    let diff = Date().distance(to: self);
                    if(diff/3600/24 <= 7){
                        let f = DateFormatter()
                        date = f.weekdaySymbols[Calendar.current.component(.weekday, from: self) - 1]
                    }
                    else{
                        date = dateFormatter.string(from: self)
                    }
                }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.locale = Locale(identifier: language.languageCode())

        let time = timeFormatter.string(from: self)
        
        switch type {
        case .arriveBy: return "Arrival: %1 %2".localized(date, time)
        case .departAt: return "Departure: %1 %2".localized(date, time)
        case .leaveNow: return "Leave now".localized()
        }
    }
    
    /// Display time v2.
    /// - Parameters:
    ///   - type: Parameter description
    /// - Returns: String
    func displayTimeV2(type: TripTimeSettingsItem) -> String {
        let language = SettingsManager.shared.appLanguage
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.locale = Locale(identifier: language.languageCode())

        let time = timeFormatter.string(from: self)
        return time
    }
    
    /// Is today.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Is yesterday.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Is tomorrow.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
}
