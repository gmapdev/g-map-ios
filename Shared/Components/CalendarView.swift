//
//  CalendarView.swift
//

import SwiftUI
import Combine

struct CalendarView: View {
    @State var date: Date
    let components: DatePickerComponents
    var dateSelected: ((Date) -> Void)? = nil

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let dateBinding = Binding(
             get: { date },
             set: {
                date = $0
                dateSelected?(date)
              }
        )
        return
            VStack {
                DatePicker(selection: dateBinding, displayedComponents: components) {
                    TextLabel("Select a date".localized())
                }
                .labelsHidden()
                .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                .foregroundColor(.blue)
            }
    }
}
