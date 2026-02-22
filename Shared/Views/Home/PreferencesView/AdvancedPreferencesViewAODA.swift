//
//  AdvancedPreferencesViewAODA.swift
//

import SwiftUI

struct AdvancedPreferencesAODAView: View {
    
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    @ObservedObject var mapFromToModel = MapFromToViewModel.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var tripFiltersModel = TripFiltersModel()
    @ObservedObject var searchSettings = SearchSettings.shared
    @ObservedObject var tripSettingsViewModel = TripSettingsViewModel.shared
    
    
    @State private var leaveTimeViewButtonRotationAngle = 0.0
    @State private var lastUpdated = Date.now
    
    var dateSelected: ((Date) -> Void)? = nil
    
    @State var selectedTimeSetting: TripTimeSettingsItem
    @State var showLeaveTimeOptionsView: Bool = false // show different leave time options [Leave now, Arrive by and Depart after]
    
    @State private var isAccessibleTripSwitchOn = false // switch value holder for Accessible trip
    @State private var isAvoidWalkingSwitchOn = false // switch value holder for Avoid walking
    @State private var refreshMainModeView = false // To Force referesh
    
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            VStack(spacing: 0){
                headerViewAODA
                ScrollView {
                    contentAODAView
                    Spacer()
                }
                planTripButtonAODA
                Spacer()
                    .frame(height: ScreenSize.safeBottom())
            }
            if mapFromToModel.pubShowCloseAlert {
                CustomAlertView(titleMessage: "You have unsaved changes", primaryButton: "Keep editing", secondaryButton: "Discard changes", primaryAction: {
                    mapFromToModel.pubShowCloseAlert.toggle()
                }, secondaryAction: {
                    // Re-storing the user selection on discard.
                    tripPlanManager.pubModeFilterCollection = mapFromToModel.pubTempTopModes
                    tripPlanManager.pubSubModeFilterCollection = mapFromToModel.pubTempSubModes
                    searchSettings.date = mapFromToModel.pubTempDate
                    searchSettings.time = mapFromToModel.pubTempTime
                    mapFromToModel.pubShowCloseAlert.toggle()
                    mapFromToModel.pubShowAdvancedPreferences.toggle()
                })
                .accessibility(addTraits: [.isModal])
            }
            
            if mapFromToModel.pubShowAccessibleTripMessage {
                CustomMessageView(titleMessage: "Selecting Accessible Routing will prioritize journeys with wheelchair boarding and provide Accessibility rating for each leg of the journey.", boldMessage: "Accessible Routing".localized(), primaryAction: {
                    mapFromToModel.pubShowAccessibleTripMessage.toggle()
                })
                .accessibility(addTraits: [.isModal])
            }
            
            if mapFromToModel.pubShowAdditionalModesMessage {
                CustomMessageView(titleMessage: "Selecting Additional Modes will include/exclude services within mode categories. Toggle on/off modes of travel you'd like to include for your trip.", boldMessage: "Additional Modes".localized(), primaryAction: {
                    mapFromToModel.pubShowAdditionalModesMessage.toggle()
                })
                .accessibility(addTraits: [.isModal])
            }
        }
        .ignoresSafeArea()
        .background(Color.white)
        .onAppear {
            mapFromToModel.pubTempTopModes = tripPlanManager.pubModeFilterCollection
            mapFromToModel.pubTempSubModes = tripPlanManager.pubSubModeFilterCollection
            mapFromToModel.pubTempDate = searchSettings.date
            mapFromToModel.pubTempTime = searchSettings.time
            isAccessibleTripSwitchOn = tripSettingsViewModel.isAccessibleRoutingSelected
            isAvoidWalkingSwitchOn = tripSettingsViewModel.isAvoidWalkingSelected
            UIAccessibility.post(notification: .announcement, argument: "Advanced preferences page opened".localized())
        }
    }
    
    var headerViewAODA: some View {
        VStack(spacing: 0){
            Spacer().frame(height: ScreenSize.safeTop())
            HStack {
                TextLabel("Advanced Preferences".localized(), .bold, .title2)
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(action: {
                    mapFromToModel.pubShowCloseAlert.toggle()
                }, label: {
                    HStack {
                        Image(systemName: "xmark")
                            .renderingMode(.template)
                            .resizable()
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .frame(width: accessibilityManager.getFontSize() - 15, height: accessibilityManager.getFontSize() - 15)
                    }
                    .frame(width: accessibilityManager.getFontSize(), height: accessibilityManager.getFontSize())
                    .background(Color.white.opacity(0.6))
                })
                .addAccessibility(text: AvailableAccessibilityItem.closeButton.rawValue.localized())
                .accessibilityRemoveTraits(.isButton)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.main)
    }
    
    var contentAODAView: some View {
        ZStack {
            VStack(spacing: 0){
                Spacer().frame(height: selectedTimeSetting != .leaveNow ? (contentSize.height * 3 ) + 10 : 80)
                Spacer().frame(height: 10)
                HStack {
                    TextLabel("Trip Options".localized(), .bold)
                    Spacer()
                }
                .padding(.bottom, 10)
                HStack {
                    TextLabel("Avoid Walking".localized())
                    Spacer()
                    Toggle(isOn: $isAvoidWalkingSwitchOn, label: {})
                        .tint(Color.java_main)
                }
                Spacer().frame(height: 15)
                HStack {
                    TextLabel("Accessible Routing".localized())
                    Button(action: {
                        mapFromToModel.pubShowAccessibleTripMessage.toggle()
                    }, label: {
                        Image(systemName: "info.circle")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2)
                            .foregroundStyle(Color.gray_subtitle_color)
                    })
                    Spacer()
                    Toggle(isOn: $isAccessibleTripSwitchOn, label: {})
                        .tint(Color.java_main)
                }
                Spacer().frame(height: 15)
                HStack {
                    VStack(alignment: .leading){
                        TextLabel("Walk Speed".localized())
                        Spacer().frame(height: 10)
                        WalkSpeedOptionsView()
                    }
                    Spacer()
                }
                
                Spacer().frame(height: 25)
                HStack {
                    TextLabel("Mode Options".localized(), .bold)
                        .lineLimit(nil)
                    Button(action: {
                        mapFromToModel.pubShowAdditionalModesMessage.toggle()
                    }, label: {
                        Image(systemName: "info.circle")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2)
                            .foregroundStyle(Color.gray_subtitle_color)
                    })
                    Spacer()
                }
                Spacer().frame(height: 10)
                HorizontalLine(color: Color.black)
                
                modeOptionsAODAView
                
                Spacer()
            }
            VStack {
                HStack {
                    TextLabel(selectedTimeSetting.rawValue.localized())
                    Spacer()
                    Image(systemName: "chevron.down")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2.2 - 8)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.java_main)
                        .rotationEffect(.degrees(leaveTimeViewButtonRotationAngle))
                }
                .padding(15)
                .border(showLeaveTimeOptionsView ? Color.java_main : Color.black, width: showLeaveTimeOptionsView ? 2 : 1)
                .background(Color.white)
                .onTapGesture {
                    updateLeaveTimeViewStatus()
                }
                Spacer().frame(height: 10)
                VStack(spacing: 0){
                    ZStack {
                        if selectedTimeSetting != .leaveNow {
                            VStack(spacing: 0){
                                ZStack {
                                    VStack {
                                        VStack {
                                            Button(action: {
                                                mapFromToModel.showTimeView = false
                                                mapFromToModel.showCalenderView.toggle()
                                            }, label: {
                                                HStack {
                                                    TextLabel(searchSettings.date.displayDate(type: selectedTimeSetting))
                                                        .foregroundStyle(Color.black)
                                                    Spacer()
                                                    Image(systemName: "calendar")
                                                        .renderingMode(.template)
                                                        .resizable()
                                                        .foregroundStyle(Color.java_main)
                                                        .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2)
                                                        .font(.system(size: 15, weight: .bold))
                                                }
                                                .padding()
                                                .border(mapFromToModel.showCalenderView ? Color.java_main : Color.black, width: mapFromToModel.showCalenderView ? 2 : 1)
                                            })
                                            .overlay(
                                                GeometryReader { geo in
                                                    Color.clear.onAppear {
                                                        contentSize = geo.size
                                                    }
                                                }
                                            )
                                            .CustomContextPopover(isPresented: $mapFromToModel.showCalenderView, arrowDirection: .up, content: {
                                                DatePicker("", selection: $searchSettings.date, displayedComponents: [.date])
                                                    .datePickerStyle(.graphical)
                                                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                                                    .background(Color.white)
                                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                            })
                                            Spacer().frame(height: 10)
                                            Button(action: {
                                                mapFromToModel.showCalenderView = false
                                                mapFromToModel.showTimeView.toggle()
                                            }, label: {
                                                HStack {
                                                    TextLabel(searchSettings.time.displayTimeV2(type: selectedTimeSetting))
                                                        .foregroundStyle(Color.black)
                                                    Spacer()
                                                    Image(systemName: "clock")
                                                        .renderingMode(.template)
                                                        .resizable()
                                                        .foregroundStyle(Color.java_main)
                                                        .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2)
                                                        .font(.system(size: 15, weight: .bold))
                                                }
                                                .padding()
                                                .border(mapFromToModel.showTimeView ? Color.java_main : Color.black, width: mapFromToModel.showTimeView ? 2 : 1)
                                            })
                                            .CustomContextPopover(isPresented: $mapFromToModel.showTimeView, arrowDirection: .up, content: {
                                                DatePicker("", selection: $searchSettings.time, displayedComponents: [.hourAndMinute])
                                                    .datePickerStyle(.wheel)
                                                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                                                    .background(Color.white)
                                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                            })
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        VStack {
                            if showLeaveTimeOptionsView {
                                VStack(spacing: 0){
                                    TimeSettingItemViewV2(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$searchSettings.date, title: TripTimeSettingsItem.leaveNow.rawValue.localized(), state: .leaveNow, onTap: {
                                        updateLeaveTimeViewStatus()
                                    })
                                    .addAccessibility(text: "%1 %2 button, double tap to %3".localized((self.selectedTimeSetting == TripTimeSettingsItem.leaveNow ? "selected" : ""), TripTimeSettingsItem.leaveNow.rawValue, (self.selectedTimeSetting == TripTimeSettingsItem.leaveNow ? "de select" : "select")))
                                    Divider()
                                    TimeSettingItemViewV2(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$searchSettings.date, title: TripTimeSettingsItem.departAt.rawValue.localized(), state: .departAt, onTap: {
                                        updateLeaveTimeViewStatus()
                                    })
                                    .addAccessibility(text: "%1 %2 button, double tap to %3".localized((self.selectedTimeSetting == TripTimeSettingsItem.departAt ? "selected" : ""), TripTimeSettingsItem.departAt.rawValue, (self.selectedTimeSetting == TripTimeSettingsItem.departAt ? "de select" : "select")))
                                    Divider()
                                    TimeSettingItemViewV2(selectedTimeSetting: self.$selectedTimeSetting, currentDate: self.$searchSettings.date, title: TripTimeSettingsItem.arriveBy.rawValue.localized(), state: .arriveBy, onTap: {
                                        updateLeaveTimeViewStatus()
                                    })
                                    .addAccessibility(text: "%1 %2 button, double tap to %3".localized((self.selectedTimeSetting == TripTimeSettingsItem.arriveBy ? "selected" : ""), TripTimeSettingsItem.arriveBy.rawValue, (self.selectedTimeSetting == TripTimeSettingsItem.arriveBy ? "de select" : "select")))
                                    
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .shadow(radius: 5)
                            }
                            Spacer()
                        }
                        
                    }
                }
            }
        }
        .padding()
    }
    
    var modeOptionsAODAView: some View {
        let topItems = tripFiltersModel.topItems
        return VStack(spacing: 0){
            ForEach(topItems.indices, id: \.self){ index in
                PreferredModeItemViewAODA(data: topItems[index], isSelected: tripPlanManager.pubModeFilterCollection.contains(where: { $0 == topItems[index]}), action:{
                    isMainMode in
                        // MARK: if isMainMode is true then action came from Main mode and if false then action came from submode's checkbox
                        if isMainMode {
                            if self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == tripFiltersModel.topItems[index]}) {
                                self.tripPlanManager.pubModeFilterCollection.removeAll(where: { $0 == tripFiltersModel.topItems[index] })
                            } else {
                                var isAppendAllItems = true
                                self.tripPlanManager.pubModeFilterCollection.append(tripFiltersModel.topItems[index])
                                if let subItems = topItems[index].selectedSubModes, !subItems.isEmpty {
                                    for subItem in subItems {
                                        if self.tripPlanManager.pubSubModeFilterCollection.contains(subItem) {
                                            isAppendAllItems = false
                                        }
                                    }
                                }
                                if isAppendAllItems {
                                    if let subModes = tripFiltersModel.topItems[index].selectedSubModes {
                                        self.tripPlanManager.pubSubModeFilterCollection.append(contentsOf: subModes)
                                    }
                                }
                            }
                        } else {
                            
                            // MARK: Check weather all sub modes are selected or not for main mode and if not turn of main mode
                            var isRemoveMainMode = true
                            if let subItems = topItems[index].selectedSubModes, !subItems.isEmpty {
                                for subItem in subItems {
                                    if self.tripPlanManager.pubSubModeFilterCollection.contains(subItem) {
                                        isRemoveMainMode = false
                                    }
                                }
                            }
                            
                            if isRemoveMainMode {
                                self.tripPlanManager.pubModeFilterCollection.removeAll(where: { $0 == tripFiltersModel.topItems[index] })
                                refreshMainModeView.toggle()
                            }
                        }
                        tripPlanManager.updateSubFilter()
                })
                .accessibilityAddTraits(.isButton)
                .id(refreshMainModeView)
            }
        }
    }
    
    
    var routePreferenceAODAView: some View {
        VStack(alignment: .leading, spacing: 0){
            HStack {
                TextLabel("Route preferences...".localized(), .bold)
                Spacer()
            }
            
            VStack {
                ForEach(mapFromToModel.routePreferences, id: \.self){ item in
                    HStack(spacing: 10){
                        Image(systemName: mapFromToModel.pubSelectedRoutePreference == item ? "circle.inset.filled" : "circle")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2)
                            .foregroundStyle(mapFromToModel.pubSelectedRoutePreference == item ? Color.java_main : Color.black)
                        Text(item.localized())
                        Spacer()
                    }
                    .accessibilityAddTraits(.isButton)
                    .onTapGesture {
                        mapFromToModel.pubSelectedRoutePreference = item
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom)
        }
    }
    
    var planTripButtonAODA: some View {
        Button(action: {
            updateAndSaveUserPreferences()
        }, label: {
            HStack {
                Spacer()
                TextLabel("Save Preferences".localized(), .bold)
                    .lineLimit(nil)
                    .foregroundStyle(Color.black)
                Spacer()
            }
            .padding(.vertical, 10)
            .frame(minHeight: 50)
            .background(Color.yellow_main)
            .padding()
        })
    }
    
    func updateAndSaveUserPreferences() {
        
        mapFromToModel.updateStates(updated: selectedTimeSetting)
        mapFromToModel.pubShowAdvancedPreferences.toggle()
        tripSettingsViewModel.isAccessibleRoutingSelected = isAccessibleTripSwitchOn
        tripSettingsViewModel.isAvoidWalkingSelected = isAvoidWalkingSwitchOn
        if let _ = SearchManager.shared.userCriterias.accessibleRouting {
            SearchManager.shared.userCriterias.accessibleRouting = isAccessibleTripSwitchOn
        }
        if let _ = SearchManager.shared.userCriterias.avoidWalking {
            SearchManager.shared.userCriterias.avoidWalking = isAvoidWalkingSwitchOn
        }
        
        
        let selectedModes = tripPlanManager.pubModeFilterCollection
        let selectedSubModes = tripPlanManager.pubSubModeFilterCollection
        
        for item in selectedModes {
            if item.mode == Mode.rent.rawValue {
                if selectedSubModes.contains(where: {$0.mode == Mode.scooter_rent.rawValue}) || selectedSubModes.contains(where: {$0.mode == Mode.bicycle_rent.rawValue}){}else {
                    tripPlanManager.pubModeFilterCollection.removeAll(where: {$0 == item})
                }
            }
            
            if item.mode == Mode.transit.rawValue {
                if let transitSelectedSubModes = item.selectedSubModes {
                    for transitSelectedSubMode in transitSelectedSubModes {
                        if selectedSubModes.contains(transitSelectedSubMode) {
                            break
                        } else {
                            tripPlanManager.pubModeFilterCollection.removeAll(where: {$0 == item})
                        }
                    }
                }
            }
        }
        
        Helper.shared.saveUserPreferredSettings()
    }
    
    func updateLeaveTimeViewStatus() {
        mapFromToModel.showCalenderView = false
        mapFromToModel.showTimeView = false
        withAnimation {
            leaveTimeViewButtonRotationAngle = leaveTimeViewButtonRotationAngle == -180 ? 0 : -180
            showLeaveTimeOptionsView.toggle()
        }
    }
}

struct PreferredModeItemViewAODA: View {
    
    let data: SearchMode
    @State var isSelected: Bool
    var action: ((Bool) -> Void)? = nil
    
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var mapFromToModel = MapFromToViewModel.shared
    @ObservedObject var tripFiltersModel = TripFiltersModel()
    
    @State private var refreshView = false
    
    var body: some View {
        let subModes = data.selectedSubModes ?? []
        return VStack(spacing: 0){
            Button(action: {
                isSelected.toggle()
            }, label: {
                HStack {
                    HStack {
                        Image(data.mode_image)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(Color.white)
                            .frame(width: getModeIconWidth(), height: getModeIconHeight())
                    }
                    .frame(width: accessibilityManager.getFontSize(), height: accessibilityManager.getFontSize())
                    .background(Color.black)
                    .clipShape(Circle())
                    Spacer().frame(width: 10)
                    TextLabel(data.label.localized())
                        .foregroundStyle(Color.black)
                    Spacer()
                    Toggle(isOn: $isSelected, label: {})
                        .tint(Color.java_main)
                        .onChange(of: isSelected) { newValue in
                            action?(true)
                        }
                }
                .padding(.vertical, 10)
            })
            
            if isSelected && subModes.count > 0 {
                Divider()
                Spacer().frame(height: 10)
                alternativeModesView
                    .id(refreshView)
                Spacer().frame(height: 10)
            }
            HorizontalLine(color: Color.black)
        }
        
    }
    
    var alternativeModesView: some View {
        let subModes = data.selectedSubModes ?? []
        
        return VStack {
            VStack {
                ForEach(subModes.indices, id: \.self){ index in
                    CheckBoxView(isChecked: self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == subModes[index]}), title: subModes[index].label, icon: subModes[index].mode_image, checboxSize: accessibilityManager.getFontSize() / 2) {
                        if self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == subModes[index]}) {
                            self.tripPlanManager.pubSubModeFilterCollection.removeAll(where: { $0 == subModes[index] })
                        } else {
                            self.tripPlanManager.pubSubModeFilterCollection.append(subModes[index])
                        }
                        self.tripPlanManager.pubSubModeFilterCollection = tripPlanManager.removeDuplicatedModes(from: tripPlanManager.pubSubModeFilterCollection)
                        refreshAlternativeModesView()
                        action?(false)
                    }
                }
            }
        }
    }
    
    func checkAllTransitAvail() -> Bool {
        return mapFromToModel.checkTransitModesAvailability(mode: data)
    }
    
    func refreshAlternativeModesView() {
        refreshView.toggle()
    }
    
    func isCheck(mode: SearchMode) -> Bool {
        if tripPlanManager.pubModeFilterCollection.contains(mode) {
            return false
        } else {
            return true
        }
    }
    
    func getModeIconHeight() -> CGFloat {
        switch data.mode {
        case Mode.transit.rawValue:
            return (accessibilityManager.getFontSize() / 2) //20
        case Mode.bicycle.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 10 //20
        case Mode.car.rawValue:
            return accessibilityManager.getFontSize() / 2 //15
        case Mode.walk.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 10 //17
        case Mode.rent.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 5 //17
        default:
            return accessibilityManager.getFontSize() / 2 //15
        }
    }
    
    func getModeIconWidth() -> CGFloat {
        switch data.mode {
        case Mode.transit.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 10 //20
        case Mode.bicycle.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 10 //20
        case Mode.car.rawValue:
            return (accessibilityManager.getFontSize() / 2) + 6 //18
        case Mode.walk.rawValue:
            return accessibilityManager.getFontSize() / 2 - 5 //15
        case Mode.rent.rawValue:
            return accessibilityManager.getFontSize() / 2 - 10 //15
        default:
            return accessibilityManager.getFontSize() / 2 //15
        }
    }
    
}

