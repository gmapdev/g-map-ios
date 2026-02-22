//
//  TripFilterActionsView.swift
//

import SwiftUI

struct TripFilterActionsView: View {
    @State var dayString: String = "Today"
    @State var timeString: String = "Leave now"
    @Binding var date: Date
    @ObservedObject var settings = SearchSettings.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    var timeSettingsAction: (()->Void)? = nil
    @State var isSettingsExpanded : Bool = false
    @State var isLeaveNowExpanded : Bool = false
    let timeDateFormatter: DateFormatter = {
        let timeDateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        timeDateFormatter.locale = Locale(identifier: language.languageCode())
        timeDateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        timeDateFormatter.dateFormat = "hh:mm a"
        return timeDateFormatter
    }()
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                timeButtonAODA
            } else {
                timeButton
            }
        }
    }
    
    /// Time button.
    /// - Parameters:
    ///   - some: Parameter description
    private var timeButton: some View {
        VStack(alignment: .leading){
            Button(action: {
                timeSettingsAction?()
                self.isSettingsExpanded = false
                self.isLeaveNowExpanded.toggle()
            }) {
                HStack{
                    Image("clock_icon")
                        .renderingMode(.template)
                        .resizable()
                        .font(.system(size: 13, weight: .light))
                        .frame(width: 25, height: 25)
                        .foregroundColor(.gray)
                    Spacer()
                    TextLabel(tripPlanManager.pubSelectedDate.displayTime(type: settings.pubsSelectedTimeSetting), .bold, .caption)
                        .foregroundColor(.black)
                    Spacer()
                    Spacer().frame(width: 25, height: 25)
                }
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 1)
                )
            }
        }
    }
    
    /// Time button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var timeButtonAODA: some View {
        VStack(alignment: .leading){
            Button(action: {
                timeSettingsAction?()
                self.isSettingsExpanded = false
                self.isLeaveNowExpanded.toggle()
            }) {
                HStack{
                    Spacer()
                    TextLabel(tripPlanManager.pubSelectedDate.displayTime(type: settings.pubsSelectedTimeSetting), .bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(10)
                .roundedBorder(10, 5)
            }
        }
    }
    
    /// Is same.
    /// - Parameters:
    ///   - date1: Parameter description
    ///   - date2: Parameter description
    /// - Returns: Bool
    private func isSame(date1: Date, date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
}


