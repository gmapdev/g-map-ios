//
//  TripPlanCalendarView.swift
//

import SwiftUI

struct TripPlanCalendarView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            DatePicker(selection: $tripPlanManager.pubSelectedDate, displayedComponents: [.hourAndMinute, .date]) {
                TextLabel("Select a date".localized())
            }
            .labelsHidden()
            .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
            .foregroundColor(.blue)
        }
    }
}

struct TripPlanCalendarView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        TripPlanCalendarView()
    }
}
