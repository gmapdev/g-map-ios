//
//  AppEnvironmets.swift
//

import Combine
import SwiftUI
import UIKit

class SearchSettings: ObservableObject {
    @Published var from: Autocomplete.Feature? = nil
    @Published var to: Autocomplete.Feature? = nil
    @Published var date: Date = Date()
    @Published var time: Date = Date()
    @Published var pubsSelectedTimeSetting: TripTimeSettingsItem = .leaveNow
    @Published var pubIsProcessing: Bool = false
    
    @Published var pubTripTimeSettingsSelectableItem: [TripTimeSettingsItem] = [.leaveNow, .arriveBy, .departAt]
    
    /// Shared.
    /// - Parameters:
    ///   - SearchSettings: Parameter description
    public static var shared: SearchSettings = {
        let viewModel = SearchSettings()
        return viewModel
    }()
    
    /// Update date picker state
    func updateDatePickerState() {
        MapFromToViewModel.shared.showCalenderView = false
    }
    
    /// Update time picker state
    func updateTimePickerState() {
        MapFromToViewModel.shared.showTimeView = false
    }
}

class EnvironmentManager: ObservableObject {
    
    @Published var pubLastUpdated = Date().timeIntervalSince1970
    
    /// Current timezone.
    /// - Parameters:
    ///   - TimeZone: Parameter description
    public var currentTimezone: TimeZone {
        get{
            return TimeZone(identifier: BrandConfig.shared.timezone) ?? TimeZone.current
        }
        set{}
    }
    public var currentLocale: Locale = Locale.current
    
    public var accessibilityEnabled: Bool = UIAccessibility.isVoiceOverRunning
        //EnableAccessibilityView
    
    /// Shared.
    /// - Parameters:
    ///   - EnvironmentManager: Parameter description
    public static var shared: EnvironmentManager = {
        let viewModel = EnvironmentManager()
        return viewModel
    }()
    
    /// Refresh timezone if needed
    /// - Returns: Bool
    /// Refreshes timezone if needed.
    private func refreshTimezoneIfNeeded() -> Bool {
        var newTimezone = TimeZone(identifier: BrandConfig.shared.timezone) ?? TimeZone.current
        if newTimezone != currentTimezone {
            currentTimezone = newTimezone
            return true
        }
        return false
    }
    
    /// Refresh locale if needed
    /// - Returns: Bool
    /// Refreshes locale if needed.
    private func refreshLocaleIfNeeded() -> Bool {
        let newLocale = Locale.current
        if newLocale != currentLocale {
            currentLocale = newLocale
            return true
        }
        return false
    }
    
    /// Refresh accessibility enabled if needed
    /// - Returns: Bool
    /// Refreshes accessibility enabled if needed.
    private func refreshAccessibilityEnabledIfNeeded() -> Bool {
        let newAccessibilityEnabled = UIAccessibility.isVoiceOverRunning
        if newAccessibilityEnabled != accessibilityEnabled{
            accessibilityEnabled = newAccessibilityEnabled
            return true
        }
        return false
    }
    
    /// Refresh
    /// Refreshes.
    func refresh(){
        var envChanged = false
        envChanged = envChanged || refreshLocaleIfNeeded()
        envChanged = envChanged || refreshAccessibilityEnabledIfNeeded()
        
        if envChanged {
            DispatchQueue.main.async {
                self.pubLastUpdated = Date().timeIntervalSince1970
            }
        }
    }
    
    
    
    
}
