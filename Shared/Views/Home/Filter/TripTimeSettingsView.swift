//
//  TripTimeSettingsView.swift
//

import SwiftUI

enum TripTimeSettingsItem: String {
    case leaveNow = "Leave now"
    case departAt = "Depart at"
    case arriveBy = "Arrive by"
}

struct TripTimeSettingsView: View {
    @ObservedObject var settings = SearchSettings.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var mapFromToModel = MapFromToViewModel.shared
    var dateSelected: ((Date) -> Void)? = nil
    @State var currentDate:Date
    @State var selectedTimeSetting: TripTimeSettingsItem
    @State private var contentSize = CGSize.zero
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            contentViewAODA
        } else {
            contentView
        }
    }
    
    /// Content view.
    /// - Parameters:
    ///   - some: Parameter description
    private var contentView: some View {
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.6))
            .zIndex(9998)
            VStack{
                VStack {
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Leave now".localized(), showDatePicker: false, state: .leaveNow)
                    
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Depart at".localized(), showDatePicker: true, state: .departAt)
                    
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Arrive by".localized(), showDatePicker: true, state: .arriveBy)
                    
                    HStack{
                        cancelButton
                        Spacer()
                        saveButton
                    }
                    .padding(10)
                }
                .overlay(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            contentSize = geo.size
                        }
                    }
                )
            }
            .background(Color.white)
            .foregroundColor(Color.primary)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
            .zIndex(9999)
        }
    }
    
    /// Content view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var contentViewAODA: some View {
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.6))
            .zIndex(9998)
            ScrollView {
                VStack {
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Leave now".localized(), showDatePicker: false, state: .leaveNow)
                    
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Depart at".localized(), showDatePicker: true, state: .departAt)
                    
                    TimeSettingItemView(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$currentDate, title: "Arrive by".localized(), showDatePicker: true, state: .arriveBy)
                    
                    HStack{
                        cancelButton
                        Spacer()
                        saveButton
                    }
                    .padding(10)
                }
                .overlay(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            contentSize = geo.size
                        }
                    }
                )
            }
            .frame(maxHeight: contentSize.height)
            .background(Color.white)
            .foregroundColor(Color.primary)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
            .zIndex(9999)
        }
    }
  
    /// Save button.
    /// - Parameters:
    ///   - some: Parameter description
    private var saveButton: some View{
        Button(action: {
            var newDate = currentDate
            /// New p d t date.
            /// - Parameters:
            ///   - Date?: Parameter description
            var newPDTDate: Date? {
                get {
                    let calender = Calendar.current
                    var dateComponents = calender.dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second], from: currentDate)
                    dateComponents.timeZone = EnvironmentManager.shared.currentTimezone
                    return calender.date(from: dateComponents)
                }
            }
            if let PDTdate = newPDTDate{
                newDate = PDTdate
            }
            
            mapFromToModel.pubDate = newDate
            tripPlanManager.pubSelectedDate = newDate
            settings.date = newDate
            settings.time = newDate
            mapFromToModel.updateStates(updated: self.selectedTimeSetting)
            dateSelected?(newDate)
        }, label: {
            HStack{
                Spacer()
                TextLabel("Save".localized(), .semibold, .body)
                    .foregroundColor(.main)
                Spacer()
            }
            .padding(.bottom, 10)
        })
    }
    
    /// Cancel button.
    /// - Parameters:
    ///   - some: Parameter description
    private var cancelButton: some View{
        Button(action: {
            mapFromToModel.pubIsTimeSettingsExpanded.toggle()
        }, label: {
            HStack{
                Spacer()
                TextLabel("Cancel".localized(), .semibold, .body)
                    .foregroundColor(.main)
                Spacer()
            }
            .padding(.bottom, 10)
        })
    }
}

struct TimeSettingItemView: View{
    @Binding var selectedTimeSetting: TripTimeSettingsItem
    @Binding var currentDate:Date
    @State var isSelected:Bool = false
    @State var title:String
    @State var showDatePicker: Bool
    
    var state: TripTimeSettingsItem
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack{
            Button(action: {
                withAnimation {
                    self.selectedTimeSetting = self.state
                }
            }, label: {
                HStack{
                    Image(systemName: checkState() ? "checkmark" : "circle")
                        .renderingMode(.template)
                        .resizable()
                        .font(.system(size: 13, weight: .semibold))
                        .padding(8)
                        .frame(width: 30, height: 30)
                        .foregroundColor(checkState() ? Color.white : Color.clear)
                        .background(checkState() ? Color.main : Color.gray)
                        .clipShape(Circle())
                    
                    TextLabel("\(title)")
                        .foregroundColor(.black)
                        .font(.body)
                    Spacer()
                }
                .padding(.top, state == .leaveNow ? 20 : 0)
                .padding(.leading)
            })
            
            if showDatePicker && checkState(){
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    datePickerViewAODA
                } else {
                    datePickerView
                }
            }
            
            Divider().padding(.vertical, 10)
        }
    }
    
    /// Date picker view.
    /// - Parameters:
    ///   - some: Parameter description
    private var datePickerView: some View {
        HStack(alignment: .center){
            DatePicker("", selection: $currentDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
            Spacer()
        }
    }
    
    /// Date picker view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var datePickerViewAODA: some View {
        HStack(alignment: .center){
            DatePicker("", selection: $currentDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
            Spacer()
        }
    }
    
    /// Check state
    /// - Returns: Bool
    /// Checks state.
    func checkState() -> Bool {

        if self.state == self.selectedTimeSetting{
            return true
        }

        return false
    }
}

struct TimeSettingItemViewV2: View{
    @Binding var selectedTimeSetting: TripTimeSettingsItem
    @Binding var currentDate:Date
    @State var isSelected:Bool = false
    @State var title:String
    
    var state: TripTimeSettingsItem
    var onTap: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        VStack{
            Button(action: {
                withAnimation {
                    onTap?()
                    self.selectedTimeSetting = self.state
                }
            }, label: {
                HStack{
                    TextLabel("\(title)", checkState() ? .bold : .regular)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(15)
                .background(checkState() ? Color.java_main.opacity(0.4) : Color.white)
                
            })
        }
    }
    
    /// Date picker view.
    /// - Parameters:
    ///   - some: Parameter description
    private var datePickerView: some View {
        HStack(alignment: .center){
            DatePicker("", selection: $currentDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
            Spacer()
        }
    }
    
    /// Date picker view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var datePickerViewAODA: some View {
        HStack(alignment: .center){
            DatePicker("", selection: $currentDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
            Spacer()
        }
    }
    
    /// Check state
    /// - Returns: Bool
    /// Checks state.
    func checkState() -> Bool {

        if self.state == self.selectedTimeSetting{
            return true
        }

        return false
    }
}
