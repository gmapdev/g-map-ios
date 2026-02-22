//
//  TripPlanningUIView.swift
//

import SwiftUI

struct TripPlanningUIView: View {
    
    @Environment(\.presentationMode) var presentation
    
    @ObservedObject var model = MapFromToViewModel.shared
    @ObservedObject var searchLocationViewModel = SearchLocationViewModel.shared
    @ObservedObject var searchSettings = SearchSettings.shared
    @ObservedObject var searchManager = SearchManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var tripFiltersModel = TripFiltersModel()
    @ObservedObject var helper = Helper.shared
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    
    @State private var showAlert = false
    
    @Binding var isSearchPressed: Bool
    @State private var contentSize: CGSize = .zero
    @State private var fromToContentSize: CGSize = .zero
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if mapManager.pubHideAddressBar{
            CollapsedSearchBarView(hideAddressBar: mapManager.pubHideAddressBar, backAction: {
                backButtonAction()
            }, collapseAction: {
                withAnimation(.easeIn(duration: 0.1)) {
                    mapManager.pubHideAddressBar.toggle()
                }
                mapManager.isMapSettings = false
            })
        } else {
            ZStack {
                VStack {
                    if model.isPushedTo || model.isPushedFrom {
                        HStack(alignment: .top){
                            backButton
                            VStack {
                                searchTextField
                                    .padding(.top, 10)
                                HorizontalLine(color: .gray)
                                    .padding(.trailing, 10)
                                    .offset(y: accessibilityManager.pubIsLargeFontSize ? 5 : -5)
                                searchListView
                                Spacer()
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(radius: 5)
                    } else {
                        if !mapManager.pubSearchRoute {
                            locationTextField
                        } else {
                            if accessibilityManager.pubIsLargeFontSize {
                                contentViewAODA
                            } else {
                                contentView
                            }
                        }
                    }
                }
            }
            .transition(.asymmetric(insertion: .scale, removal: .scale))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missed data".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
                      message: Text("Please define the following fields to plan a trip: from, to".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
                      dismissButton: .default(Text("OK".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))))
            }
        }
    }
    
    /// Content view.
    /// - Parameters:
    ///   - some: Parameter description
    var contentView: some View {
        VStack {
            if mapManager.pubIsInTripPlan {
                HStack {
                    VStack {
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubFromDisplayString == "(Current Location)".localized() {
                                model.pubFromDisplayString = ""
                            }
                            if searchManager.from != nil {
                                searchLocationViewModel.searchText = model.pubFromDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedFrom.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_origin")
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubFromDisplayString.isEmpty ? "Start".localized() : model.pubFromDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubFromDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                Spacer()
                            }
                            .frame(minHeight: 50)
                            .border(Color.black)
                        })
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubToDisplayString == "(Current Location)".localized() {
                                model.pubToDisplayString = ""
                            }
                            if searchManager.to != nil {
                                searchLocationViewModel.searchText = model.pubToDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedTo.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_destination")
                                    .resizable()
                                    .frame(width: 23, height: 23, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubToDisplayString.isEmpty ? "Destination".localized() : model.pubToDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubToDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                Spacer()
                            }
                            .frame(minHeight: 50)
                            .border(Color.black)
                        })
                    }
                    VStack {
                        collapseButton
                        Button(action: {
                            switchLocations()
                        }) {
                            Image("ic_switch")
                                .renderingMode(.template)
                                .resizable()
                                .padding(7)
                                .foregroundColor(.black)
                        }
                        .background(Color.white)
                        .frame(width: 40, height: 40)
                        .addAccessibility(text: AvailableAccessibilityItem.switchAddress.rawValue.localized())
                    }
                }
            } else {
                ZStack {
                    VStack {
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubFromDisplayString == "(Current Location)".localized() {
                                model.pubFromDisplayString = ""
                            }
                            if searchManager.from != nil {
                                searchLocationViewModel.searchText = model.pubFromDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedFrom.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_origin")
                                    .resizable()
                                    .frame(width: 20, height: 20, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubFromDisplayString.isEmpty ? "Start".localized() : model.pubFromDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubFromDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Spacer().frame(width: 50)
                            }
                            .frame(height: 50)
                            .border(Color.black)
                        })
                        .onAppear {
                            if mapManager.pubShowUsersCurrentLocation{
                                mapManager.pubShowUsersCurrentLocation = false
                                mapManager.followMe(enable: false)
                                if let userlocation = mapManager.mapView.userLocation?.coordinate{
                                    mapManager.reverseLocation(latitude: userlocation.latitude, longitude: userlocation.longitude) { autoComplete in
                                        if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                                            if let feature = autocomplete.features.first {
                                                if searchManager.from == nil{
                                                    mapManager.pubShowUsersCurrentLocation = true
                                                    model.pubFromString = feature.properties.label
                                                    model.pubFromDisplayString = "(Current Location)".localized()
                                                    searchManager.from = feature
                                                    if let location = feature.geometry?.coordinate{
                                                        mapManager.previewFromMarker(coordinates: location)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .addAccessibility(text: "\(model.pubFromDisplayString.isEmpty ? "Origin location textfield".localized() : "Origin %1")".localized(model.pubFromDisplayString))
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubToDisplayString == "(Current Location)".localized() {
                                model.pubToDisplayString = ""
                            }
                            if searchManager.to != nil {
                                searchLocationViewModel.searchText = model.pubToDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedTo.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_destination")
                                    .resizable()
                                    .frame(width: 23, height: 23, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubToDisplayString.isEmpty ? "Destination".localized() : model.pubToDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubToDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Spacer().frame(width: 50)
                            }
                            .frame(height: 50)
                            .border(Color.black)
                        })
                        .addAccessibility(text: "\(model.pubToDisplayString.isEmpty ? "Destination location textfield".localized() : "Destination %1")".localized(model.pubToDisplayString))
                    }
                    HStack {
                        Spacer()
                        switchButton
                        Spacer()
                            .frame(width: 10)
                    }
                }
                optionsView
                if searchSettings.pubsSelectedTimeSetting != .leaveNow {
                    departureOptionsView
                }
                modeOptionsView
                searchButton
            }
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }

    /// Content view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var contentViewAODA: some View {
        ScrollView {
            VStack {
                if mapManager.pubIsInTripPlan {
                    HStack {
                        VStack {
                            Button(action: {
                                // MARK: Clearing the `pubFromDisplayString` when user start typing
                                if model.pubFromDisplayString == "(Current Location)".localized() {
                                    model.pubFromDisplayString = ""
                                }
                                if searchManager.from != nil {
                                    searchLocationViewModel.searchText = model.pubFromDisplayString
                                } else {
                                    searchLocationViewModel.searchText = ""
                                }
                                mapManager.pubIsInTripPlan = false
                                tripPlanManager.pubShowFullPage = false
                                model.isPushedFrom.toggle()
                                mapManager.isMapSettings = false
                                mapManager.isSearchingPlace = true
                            }, label: {
                                HStack {
                                    Spacer()
                                        .frame(width: 10)
                                    Image("ic_origin")
                                        .resizable()
                                        .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                    Spacer()
                                        .frame(width: 10)
                                    TextLabel(model.pubFromDisplayString.isEmpty ? "Start".localized() : model.pubFromDisplayString, .regular, .body)
                                        .foregroundStyle(model.pubFromDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                    Spacer()
                                }
                                .frame(minHeight: 50)
                                .border(Color.black)
                            })
                            Button(action: {
                                if searchManager.to != nil {
                                    searchLocationViewModel.searchText = model.pubToDisplayString
                                } else {
                                    searchLocationViewModel.searchText = ""
                                }
                                mapManager.pubIsInTripPlan = false
                                tripPlanManager.pubShowFullPage = false
                                model.isPushedTo.toggle()
                                mapManager.isMapSettings = false
                                mapManager.isSearchingPlace = true
                            }, label: {
                                HStack {
                                    Spacer()
                                        .frame(width: 10)
                                    Image("ic_destination")
                                        .resizable()
                                        .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                    Spacer()
                                        .frame(width: 10)
                                    TextLabel(model.pubToDisplayString.isEmpty ? "Destination".localized() : model.pubToDisplayString, .regular, .body)
                                        .foregroundStyle(model.pubToDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                    Spacer()
                                }
                                .frame(minHeight: 50)
                                .border(Color.black)
                            })
                        }
                        VStack {
                            Spacer()
                            collapseButton
                            Spacer()
                            Button(action: {
                                switchLocations()
                            }) {
                                Image("ic_switch")
                                    .renderingMode(.template)
                                    .resizable()
                                    .padding(7)
                                    .foregroundColor(.black)
                            }
                            .background(Color.white)
                            .frame(width: 40, height: 40)
                            .addAccessibility(text: AvailableAccessibilityItem.switchAddress.rawValue.localized())
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 0){
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubFromDisplayString == "(Current Location)".localized() {
                                model.pubFromDisplayString = ""
                            }
                            if searchManager.from != nil {
                                searchLocationViewModel.searchText = model.pubFromDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedFrom.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_origin")
                                    .resizable()
                                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubFromDisplayString.isEmpty ? "Start".localized() : model.pubFromDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubFromDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                Spacer()
                                Spacer().frame(width: 50)
                            }
                            .frame(minHeight: 50)
                            .border(Color.black)
                        })
                        .onAppear {
                            if mapManager.pubShowUsersCurrentLocation{
                                mapManager.pubShowUsersCurrentLocation = false
                                mapManager.followMe(enable: false)
                                if let userlocation = mapManager.mapView.userLocation?.coordinate{
                                    mapManager.reverseLocation(latitude: userlocation.latitude, longitude: userlocation.longitude) { autoComplete in
                                        if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                                            if let feature = autocomplete.features.first {
                                                if searchManager.from == nil{
                                                    mapManager.pubShowUsersCurrentLocation = true
                                                    model.pubFromString = feature.properties.label
                                                    model.pubFromDisplayString = "(Current Location)".localized()
                                                    searchManager.from = feature
                                                    if let location = feature.geometry?.coordinate{
                                                        mapManager.previewFromMarker(coordinates: location)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        HStack {
                            Spacer()
                            switchButton
                            Spacer()
                                .frame(width: 10)
                        }.offset(y: -22.5)
                            .zIndex(999)
                        Button(action: {
                            // MARK: Clearing the `pubFromDisplayString` when user start typing
                            if model.pubToDisplayString == "(Current Location)".localized() {
                                model.pubToDisplayString = ""
                            }
                            if searchManager.to != nil {
                                searchLocationViewModel.searchText = model.pubToDisplayString
                            } else {
                                searchLocationViewModel.searchText = ""
                            }
                            mapManager.pubIsInTripPlan = false
                            tripPlanManager.pubShowFullPage = false
                            model.isPushedTo.toggle()
                            mapManager.isMapSettings = false
                            mapManager.isSearchingPlace = true
                        }, label: {
                            HStack {
                                Spacer()
                                    .frame(width: 10)
                                Image("ic_destination")
                                    .resizable()
                                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                Spacer()
                                    .frame(width: 10)
                                TextLabel(model.pubToDisplayString.isEmpty ? "Destination".localized() : model.pubToDisplayString, .regular, .body)
                                    .foregroundStyle(model.pubToDisplayString.isEmpty ? Color.gray_subtitle_color : Color.black)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                Spacer()
                                Spacer().frame(width: 50)
                            }
                            .frame(minHeight: 50)
                            .border(Color.black)
                        })
                        .offset(y: -35)
                        .zIndex(998)
                    }
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                fromToContentSize = geo.size
                            }
                        }
                    )
                    HStack {
                        leaveTimeAODAView
                        Spacer()
                    }
                    .offset(y: -20)
                    if searchSettings.pubsSelectedTimeSetting != .leaveNow {
                        departureOptionsAODAView
                            .offset(y: -20)
                    }
                    moreOptionsAODAView
                        .offset(y: -20)
                    modeOptionsView
                        .offset(y: -20)
                    searchButton
                        .offset(y: -10)
                }
            }.overlay(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        contentSize = geo.size
                    }
                }
            )
        }
        .frame(maxHeight: contentSize.height)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        
    }
    
    // Leave time and More options view
    var optionsView: some View {
        HStack {
            Menu(content: {
                ForEach(searchSettings.pubTripTimeSettingsSelectableItem, id: \.self) { item in
                    Button {
                        searchSettings.pubsSelectedTimeSetting = item
                    } label: {
                        HStack {
                            TextLabel(item.rawValue.localized())
                            if searchSettings.pubsSelectedTimeSetting == item {
                                Image(systemName: "checkmark")
                                    .renderingMode(.template)
                                    .resizable()
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 10, height: 5)
                            }
                        }
                    }
                    .addAccessibility(text: "%1 button, double tap to %2".localized(item.rawValue.localized(), searchSettings.pubsSelectedTimeSetting == item ? "de select".localized() : "select".localized()))
                }
            }, label: {
                HStack {
                    TextLabel(searchSettings.pubsSelectedTimeSetting.rawValue.localized())
                        .foregroundStyle(Color.black)
                    Image(systemName: "chevron.down")
                        .renderingMode(.template)
                        .resizable()
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 14, height: 8)
                        .offset(y: 1)
                }
            })
            Spacer()
            
            ClickableText("More options".localized(), ["More options".localized()], ["More options".localized()], Color.black, Color.black, [:]) { _ in
                model.pubShowAdvancedPreferences = true
            }
            .addAccessibility(text: "More options button, double tap to activate".localized())
        }
        .padding(.top, 10)
    }
    
    // Leave time AODA View
    var leaveTimeAODAView: some View {
        HStack{
            Menu(content: {
                ForEach(searchSettings.pubTripTimeSettingsSelectableItem, id: \.self) { item in
                    Button {
                        searchSettings.pubsSelectedTimeSetting = item
                    } label: {
                        HStack {
                            TextLabel(item.rawValue)
                            if searchSettings.pubsSelectedTimeSetting == item {
                                Image(systemName: "checkmark")
                                    .renderingMode(.template)
                                    .resizable()
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(Color.black)
                                    .frame(width: 10, height: 5)
                            }
                        }
                    }
                }
            }, label: {
                HStack {
                    TextLabel(searchSettings.pubsSelectedTimeSetting.rawValue)
                        .foregroundStyle(Color.black)
                    Image(systemName: "chevron.down")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: accessibilityManager.getFontSize() / 2, height: accessibilityManager.getFontSize() / 2.2 - 8)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black)
                }
            })
        }
    }
    
    // More options AODA View
    var moreOptionsAODAView: some View {
        HStack{
            ClickableText("More options", ["More options"], ["More options"], Color.black, Color.black, [:]) { _ in
                model.pubShowAdvancedPreferences = true
            }
            Spacer()
        }
        .addAccessibility(text: "More options button, double tap to activate".localized())
        .padding(.top, 10)
        
    }
    
    /// Departure options view.
    /// - Parameters:
    ///   - some: Parameter description
    var departureOptionsView: some View {
        HStack {
            Button(action: {
                model.showTimeView = false
                model.showCalenderView.toggle()
            }, label: {
                HStack {
                    TextLabel(searchSettings.date.displayDate(type: searchSettings.pubsSelectedTimeSetting))
                        .foregroundStyle(Color.black)
                    Image(systemName: "calendar")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.java_main)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(minHeight: 50)
                .padding(.horizontal)
                .border(model.showCalenderView ? Color.java_main : Color.black, width: model.showCalenderView ? 2 : 1)
            })
            .CustomContextPopover(isPresented: $model.showCalenderView, arrowDirection: .up, content: {
                DatePicker("", selection: $searchSettings.date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            })
            
            Spacer()
            Button(action: {
                model.showCalenderView = false
                model.showTimeView.toggle()
            }, label: {
                HStack {
                    TextLabel(searchSettings.time.displayTimeV2(type: searchSettings.pubsSelectedTimeSetting))
                        .foregroundStyle(Color.black)
                    Image(systemName: "clock")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.java_main)
                        .frame(width: 20, height: 20)
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(minHeight: 50)
                .padding(.horizontal)
                .border(model.showTimeView ? Color.java_main : Color.black, width: model.showTimeView ? 2 : 1)
            })
            .CustomContextPopover(isPresented: $model.showTimeView, arrowDirection: .up, content: {
                DatePicker("", selection: $searchSettings.time, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            })
        }
        .frame(minHeight: 50)
        .padding(.vertical, 2)
    }
    
    /// Departure options a o d a view.
    /// - Parameters:
    ///   - some: Parameter description
    var departureOptionsAODAView: some View {
        VStack {
            Button(action: {
                model.showTimeView = false
                model.showCalenderView.toggle()
            }, label: {
                HStack {
                    TextLabel(searchSettings.date.displayDate(type: searchSettings.pubsSelectedTimeSetting))
                        .foregroundStyle(Color.black)
                    Spacer()
                    Image(systemName: "calendar")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.java_main)
                        .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20)
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(minHeight: 50)
                .padding()
                .border(model.showCalenderView ? Color.java_main : Color.black, width: model.showCalenderView ? 2 : 1)
            })
            .CustomContextPopover(isPresented: $model.showCalenderView, arrowDirection: .up, content: {
                DatePicker("", selection: $searchSettings.date, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            })
            Button(action: {
                model.showCalenderView = false
                model.showTimeView.toggle()
            }, label: {
                HStack {
                    TextLabel(searchSettings.time.displayTimeV2(type: searchSettings.pubsSelectedTimeSetting))
                        .foregroundStyle(Color.black)
                    Spacer()
                    Image(systemName: "clock")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundStyle(Color.java_main)
                        .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20)
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(minHeight: 50)
                .padding()
                .border(model.showTimeView ? Color.java_main : Color.black, width: model.showTimeView ? 2 : 1)
            })
            .CustomContextPopover(isPresented: $model.showTimeView, arrowDirection: .up, content: {
                DatePicker("", selection: $searchSettings.time, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: SettingsManager.shared.appLanguage.languageCode()))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            })
        }
        .padding(.vertical, 2)
    }
    
    // Mode options View
    var modeOptionsView: some View {
        VStack{
            VFlow(alignment: .leading, spacing: accessibilityManager.pubIsLargeFontSize ? 10 : 7){
                ForEach(tripFiltersModel.topItems.indices, id: \.self){ index in
                    HStack {
                        FilterButtonViewV2(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() * 1.5 : ((ScreenSize.width()-95)/5), data: tripFiltersModel.topItems[index], isSelected: self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == tripFiltersModel.topItems[index]}), action:{
                            if self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == tripFiltersModel.topItems[index]}) {
                                self.tripPlanManager.pubModeFilterCollection.removeAll(where: { $0 == tripFiltersModel.topItems[index] })
                            } else {
                                self.tripPlanManager.pubModeFilterCollection.append(tripFiltersModel.topItems[index])
                                if let subModes = tripFiltersModel.topItems[index].selectedSubModes {
                                    self.tripPlanManager.pubSubModeFilterCollection.append(contentsOf: subModes)
                                }
                            }
                            tripPlanManager.updateSubFilter()
                            helper.saveUserPreferredSettings()
                        })
                        .accessibilityAddTraits(.isButton)
                        .padding(.vertical, accessibilityManager.pubIsLargeFontSize ? 2 : 5)
                    }
                }
            }
        }
    }
    
    // Plan trip button
    var searchButton: some View {
        Button(action: {
            searchAction()
        }, label: {
            HStack{
                Spacer()
                TextLabel("Plan Trip".localized(), .bold, .subheadline)
                    .foregroundColor(ThemeConfig.shared.plan_trip_button_in_search_font_color)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, accessibilityManager.pubIsLargeFontSize ? 10 : 0)
        })
        .frame(minHeight: 50)
        .background(ThemeConfig.shared.plan_trip_button_in_search_bg_color)
        .addAccessibility(text: "Plan trip button, double tap to start planning a trip".localized())
    }
    
    //Initial Search bar displayed on map view
    var locationTextField: some View {
        Button(action: {
            model.isPushedTo.toggle()
            mapManager.isMapSettings = false
            mapManager.isSearchingPlace = true
        }, label: {
            HStack {
                Spacer().frame(width: 10)
                Image("ic_destination")
                    .resizable()
                    .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() / 2 : 20)
                TextLabel("Enter destination or choose on map".localized(), .bold, .body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color.gray_subtitle_color)
                    .lineLimit(nil)
                Spacer()
                Spacer().frame(width: 10)
            }
            .frame(minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
        })
    }
    
    // Location switch button
    var switchButton: some View {
        Button(action: {
            switchLocations()
        }) {
            VStack {
                Image(systemName: "arrow.up.arrow.down")
                    .renderingMode(.template)
                    .resizable()
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 25, height: 20)
                    .foregroundStyle(Color.white)
            }.frame(width: 45, height: 45)
                .background(Color.gray_subtitle_color)
        }
        .addAccessibility(text: "Switch origin and destination button, double tap to switch".localized())
        
    }
    
    // Plan trip collapse button
    var collapseButton: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                mapManager.pubHideAddressBar.toggle()
            }
            mapManager.isMapSettings = false
        } label: {
            Image(mapManager.pubHideAddressBar ? "btn_expand" : "btn_collapse")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.black)
            
        }.background(Color.white)
            .frame(width: 48, height: 48, alignment: .center)
            .addAccessibility(text: (mapManager.pubHideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
    
    // Back button while searching for a location
    var backButton: some View {
        Button(action: {
            backButtonAction()
        }) {
            Image("ic_leftarrow")
                .renderingMode(.template)
                .resizable()
                .padding(5)
                .foregroundColor(.black)
        }
        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2.2 : 25, height: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2 : 30)
        .padding(.top, 20)
        .padding(.leading, 10)
        .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
        .accessibilityAction {
            backButtonAction()
        }
    }
    
    // Actual location search text field
    var searchTextField: some View {
        VStack {
            LocationTextField(placeholder: model.isPushedFrom ? "Enter start location".localized() : "Enter destination".localized(),
                              lineColor: Color.black, resize: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 20, leadingPadding: 0, showClearButton: true, isPushedFrom: model.isPushedFrom,
                              text: $searchLocationViewModel.searchText)
        }
    }
    
    // Search list view below location search text field
    var searchListView: some View {
        ScrollView {
            VStack {
                Spacer().frame(height: 10)
                if (AppSession.shared.loginInfo != nil) {
                    ForEach( 0..<searchLocationViewModel.searchedSavedLocations.count, id: \.self) { idx in
                        savedLocationView(location: searchLocationViewModel.searchedSavedLocations[idx])
                    }
                    if searchLocationViewModel.searchedSavedLocations.count > 0 {
                        Spacer().frame(height: 10)
                    }
                }
                
                if searchLocationViewModel.getOtherLocations().count > 0 {
                    HStack{
                        TextLabel("Addresses, Landmarks and Places".localized(), .bold, .body).foregroundColor(Color.black)
                            .addAccessibility(text: "Addresses, Landmarks and Places, %1 in total".localized(searchLocationViewModel.getOtherLocations().count))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                    }
                }
                ForEach(searchLocationViewModel.getOtherLocations()) { location in
                    item(by: location)
                }
                
                if searchLocationViewModel.getStopLocations().count > 0 {
                    HStack{
                        TextLabel("Stops".localized(), .bold, .body).foregroundColor(Color.black)
                            .addAccessibility(text: "Stops, %1 in total".localized(searchLocationViewModel.getStopLocations().count))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                    }
                }
                ForEach(searchLocationViewModel.getStopLocations()) { location in
                    item(by: location)
                }
                
                if !searchLocationViewModel.recentLocations.isEmpty {
                    recentListView
                }
                currentLocationView()
                if searchSettings.pubIsProcessing{
                    VStack{
                        HStack{
                            TextLabel("Favorite Places".localized(), .bold, .body).foregroundColor(Color.black)
                                .addAccessibility(text: "Favorite Places, %1 in total".localized(getItems().count))
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                        }.padding(.top)
                        ActivityIndicator(isAnimating: .constant(true), style: .large)
                    }
                }else{
                    if let _ = AppSession.shared.loginInfo{
                        
                        VStack{
                            HStack{
                                TextLabel("Favorite Places".localized(), .bold, .body).foregroundColor(Color.black)
                                    .addAccessibility(text: "Favorite Places, %1 in total".localized(getItems().count))
                                    .accessibilityAddTraits(.isHeader)
                                Spacer()
                            }.padding(.top)
                            
                            if getItems().count > 0 {
                                ForEach( 0..<getItems().count, id: \.self) { idx in
                                    savedLocationView(location: getItems()[idx])
                                }
                                Spacer().frame(height: 10)
                            }
                        }
                    }
                }
            }
            .background(Color.white)
        }
        .onAppear {
            searchSettings.pubIsProcessing = true
            TabBarMenuManager.shared.previousItemTab = .planTrip
            LoginAuthProvider().getUserInfo {
                DispatchQueue.main.async {
                    searchSettings.pubIsProcessing = false
                }
            }
        }
    }
    
    /// Get items
    /// - Returns: [FavouriteLocation]
    /// Retrieves items.
    func getItems() -> [FavouriteLocation]{
        var savedLocations = [FavouriteLocation]()
        
        if let locations = AppSession.shared.loginInfo?.savedLocations {
            savedLocations = locations
        }
        
        return savedLocations
    }
    
    /// Recent list view.
    /// - Parameters:
    ///   - some: Parameter description
    var recentListView: some View {
        return VStack {
            HStack {
                TextLabel("Recent Places".localized(), .bold, .body)
                    .foregroundColor(Color.black)
                    .addAccessibility(text: "Recently Searched Address".localized())
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(3)
                Spacer()
            }
            .frame(alignment: .leading)
            .padding(.horizontal, 0)
            ForEach(searchLocationViewModel.recentLocations) { location in
                item(by: location, isRecent: true)
            }
        }
        .background(Color.white)
    }
    
    /// Item.
    
    func getIconForLocation(isRecent: Bool, modes: [String]?) -> String {
        if isRecent {
            return "search_icon"
        } else {
            if let modes = modes,
                !modes.isEmpty {
                let mode = modes[0]
                switch mode {
                case Mode.bus.rawValue:
                    return "ic_bus"
                case Mode.rail.rawValue:
                    return "ic_rail"
                case Mode.tram.rawValue:
                    return "ic_light_rail"
                case Mode.water_taxi.rawValue:
                    return "ic_water_taxi"
                case Mode.ferry.rawValue:
                    return "ic_ferry"
                case Mode.streetcar.rawValue:
                    return "ic_streetcar"
                case Mode.monorail.rawValue:
                    return "filter_monorail_icon"
                default:
                    //MARK: kept print statement here to identify uncovered modes and add those as case in future
                    OTPLog.log(level: .info, info: "this is uncovered mode: \(mode)")
                    return "location_pin_icon"
                }
            } else {
                return "location_pin_icon"
            }
        }
    }
    
    func item(by location: SearchLocationItem,
              isRecent: Bool = false) -> SearchItemView {
        let modes = location.feature.properties.modes
        let imageName = getIconForLocation(isRecent: isRecent, modes: modes)
        let (titleText, subtitleTexts) = helper.getFormattedPlaceText(feature: location.feature)
        var itemView = SearchItemView(imageName: imageName,
                                      titleText: titleText, subTexts: subtitleTexts)
        itemView.action = {
            mapManager.cleanPlotRoute()
            searchLocationViewModel.saveFeature(location.feature, isRecent: isRecent)
            searchLocationViewModel.searchText = ""
            if model.isPushedTo{
                model.isPushedTo = false
                model.pubToString = titleText
                model.pubToDisplayString = titleText
                searchManager.to = location.feature
                mapManager.removePreviewToMarker()
            }else{
                model.isPushedFrom = false
                model.pubFromString = titleText
                model.pubFromDisplayString = titleText
                searchManager.from = location.feature
                mapManager.removePreviewFromMarker()
            }
            if let fromLocation = searchManager.from {
                guard let coordinates = fromLocation.geometry?.coordinate else { return }
                mapManager.previewFromMarker(coordinates: coordinates)
            }
            if let toLocation = searchManager.to {
                guard let coordinates = toLocation.geometry?.coordinate else { return }
                mapManager.previewToMarker(coordinates: coordinates)
            }
            tripPlanManager.isItineraryResult = true
            tripPlanManager.pubShowFullPage = true
            mapManager.pubIsInTripPlanDetail = false
            updateFromTo()
            updateFromToStringForAnnotation()
            UIApplication.shared.dismissKeyboard()
            presentation.wrappedValue.dismiss()
            mapManager.isSearchingPlace = false
            if !model.pubFromString.isEmpty{
                mapManager.pubShowUsersCurrentLocation = false
            }
            searchLocationViewModel.searchText = ""
        }
        return itemView
    }
    
    /// Current location view
    /// - Returns: SearchItemView
    /// Current location view.
    private func currentLocationView() -> SearchItemView {
        var itemView = SearchItemView(imageName: "map_location_move_icon",
                                      titleText: "Use current location".localized(), subTexts: [])
        itemView.action = {
            
            if !LocationService.shared.isLocationServiceEnabled() {
                AlertManager.shared.presentAlert(message: "Access to your location is blocked. To use your current location, enable location permissions from your device app settings.".localized())
                return
            }
            
            if let userLocation = MapManager.shared.mapView.userLocation {
                let from = userLocation.coordinate
                MapManager.shared.reverseLocation(latitude: from.latitude, longitude: from.longitude, completion: { autoComplete in
                    if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                        if let feature = autocomplete.features.first {
                            DispatchQueue.main.async {
                                searchLocationViewModel.searchText = ""
                                if model.isPushedTo{
                                    model.isPushedTo = false
                                    model.pubToString = feature.properties.label
                                    model.pubToDisplayString = "(Current Location)".localized()
                                    searchManager.to = feature
                                }else if model.isPushedFrom{
                                    model.isPushedFrom = false
                                    model.pubFromString = feature.properties.label
                                    model.pubFromDisplayString =  "(Current Location)".localized()
                                    searchManager.from = feature
                                }
                                searchLocationViewModel.searchText = ""
                                updateFromTo()
                                updateFromToStringForAnnotation()
                                UIApplication.shared.dismissKeyboard()
                                presentation.wrappedValue.dismiss()
                            }
                        }
                    }
                })
            }
        }
        return itemView
    }
    
    /// Saved location view.
    /// - Parameters:
    ///   - location: Parameter description
    /// - Returns: MyLocationItemView?
    func savedLocationView(location: FavouriteLocation) -> MyLocationItemView?{
        if location.type == "stop"{
            return nil
        }
        var itemView = MyLocationItemView(imageName: "ic_home", text: "Home", addressLine: location.address)
        if location.type == "work"{
            let newItemView = MyLocationItemView(imageName: "ic_work", text: "Work", addressLine: location.address)
            itemView = newItemView
        }
        else if location.type == "custom"{
            let newItemView = MyLocationItemView(imageName: "ic_location", text: location.name, addressLine: location.address)
            itemView = newItemView
        }
        else if location.type == "dining"{
            let newItemView = MyLocationItemView(imageName: "ic_dinein", text: location.name, addressLine: location.address)
            itemView = newItemView
        }
        itemView.action = {
            
            let properties = Autocomplete.Properties(id: location.id.uuidString, name: location.name, label: location.address, gid: location.id.uuidString, layer: nil, source: nil, source_id: nil, accuracy: nil, modes: [], street: nil, neighbourhood: nil, locality: nil, region_a: nil, secondaryLabels: [])
            let coordinate = Coordinate(lat: location.lat, long: location.lon)
            let geometry = Autocomplete.Geometry(type: location.type, coordinate: coordinate)
            let feature = Autocomplete.Feature(properties: properties, geometry: geometry, id: location.id.uuidString)
            let (placeString, _) = helper.getFormattedPlaceText(feature: feature)
            if model.isPushedTo {
                model.isPushedTo = false
                model.pubToString = placeString
                if geometry.type == "custom" || geometry.type == "dining" {
                    model.pubToDisplayString = "\(feature.properties.name) (\(placeString))"
                } else {
                    model.pubToDisplayString = placeString
                }
                searchManager.to = feature
            } else if model.isPushedFrom {
                mapManager.pubShowUsersCurrentLocation = false
                model.isPushedFrom = false
                model.pubFromString = placeString
                if geometry.type == "custom" || geometry.type == "dining" {
                    model.pubFromDisplayString = "\(feature.properties.name) (\(placeString))"
                } else {
                    model.pubFromDisplayString = placeString
                }
                searchManager.from = feature
            }
            searchLocationViewModel.searchText = ""
            updateFromTo()
            updateFromToStringForAnnotation()
            
            if let fromLocation = searchManager.from {
                guard let coordinates = fromLocation.geometry?.coordinate else { return }
                mapManager.previewFromMarker(coordinates: coordinates)
            }
            if let toLocation = searchManager.to {
                guard let coordinates = toLocation.geometry?.coordinate else { return }
                mapManager.previewToMarker(coordinates: coordinates)
            }
            
            UIApplication.shared.dismissKeyboard()
            presentation.wrappedValue.dismiss()
        }
        return itemView
    }
    
    /// Update from to
    /// Updates from to.
    private func updateFromTo() {
        if (!model.pubFromString.isEmpty || !model.pubToString.isEmpty) && !mapManager.pubSearchRoute {
            mapManager.pubSearchRoute.toggle()
        }
    }
    
    /// Update from to string for annotation
    /// Updates from to string for annotation.
    func updateFromToStringForAnnotation(){
        
        if let to = searchManager.to {
            let (toText, _) = helper.getFormattedPlaceText(feature: to)
            self.model.pubToString = toText
            self.model.pubFromDisplayString = self.model.pubFromDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : self.model.pubFromDisplayString
        }
        if let from = searchManager.from {
            let (fromText, _) = helper.getFormattedPlaceText(feature: from)
            self.model.pubFromString = fromText
            self.model.pubToDisplayString = self.model.pubToDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : self.model.pubToDisplayString
        }
    }
    
    /// Search action
    /// Searches action.
    func searchAction(){
        model.updateStates(updated: searchSettings.pubsSelectedTimeSetting)
        if !Env.shared.isNetworkConnected{
            Env.shared.pubShowOfflineDialog = true
            return
        }
        if model.pubToString.count == 0 ||
            model.pubFromString.count == 0 {
            AlertManager.shared.presentAlert(message: "Please define the following fields to plan a trip: origin and destination".localized())
            
            return
        }
        tripPlanManager.selectedItinerary = nil
        mapManager.isMapSettings = false
        model.isSettingsExpanded = false
        mapManager.map().dismissCalloutFromMap()
        guard let _ = searchManager.to,
              let _ = searchManager.from else {
            AlertManager.shared.presentAlert(message: "Planing a trip is not possible with the following origin and destination".localized())
            showAlert = true
            return
        }
        if let from = searchManager.from, let to = searchManager.to, from.properties == to.properties {
            AlertManager.shared.presentAlert(message: "Planing a trip is not possible with the same origin and destination".localized())
            showAlert = true
            return
        }
        model.isSettingsExpanded = false
        model.pubIsTimeSettingsExpanded = false
        isSearchPressed = true
        mapManager.pubHideAddressBar = true
        let selectedModes: [SearchMode] = tripPlanManager.pubModeFilterCollection
        var selectedSubModes: [SearchMode] = tripPlanManager.pubSubModeFilterCollection
        if !selectedModes.contains(where: {$0.mode == Mode.transit.rawValue}){
            selectedSubModes = selectedSubModes.filter { $0.mode == Mode.bicycle_rent.rawValue || $0.mode == Mode.scooter_rent.rawValue }
        }
        if !selectedModes.contains(where: {$0.mode == Mode.rent.rawValue}){
            selectedSubModes.removeAll { $0.mode == Mode.bicycle_rent.rawValue || $0.mode == Mode.scooter_rent.rawValue }
        }
        if tripPlanManager.isLeaveNow {
            tripPlanManager.pubSelectedDate = Date()
        }
        
        tripPlanManager.startFetchTripPlan(selectedModes: selectedModes, selectedSubModes: selectedSubModes)
        withAnimation {
            mapManager.pubIsInTripPlan = true
            tripPlanManager.pubShowFullPage = true
            BottomSlideBarViewModel.shared.pubIsDraggable = false
        }
    }
    
    /// Back button action
    /// Back button action.
    func backButtonAction(){
        searchLocationViewModel.searchText = ""
        mapManager.cleanPlotRoute()
        mapManager.plantTripPlotItems = nil
        if model.isPushedFrom{
            model.isPushedFrom.toggle()
            self.restoreTextSearchState()
            mapManager.isSearchingPlace = true
        }
        else if model.isPushedTo{
            model.isPushedTo.toggle()
            self.restoreTextSearchState()
            mapManager.isSearchingPlace = true
        }
        if !mapManager.isSearchingPlace{
            mapManager.pubIsInTripPlan = true
        }
        mapManager.isSearchingPlace = false
        tripPlanManager.pubSelectedTripPlanItem = nil
        mapManager.removePreviewMarkers()
        tripPlanManager.isItineraryResult = true
        mapManager.pubIsInTripPlanDetail = false
        mapManager.pubHideAddressBar = false
        mapManager.isMapSettings = false
        tripPlanManager.pubShowFullPage = true
        withAnimation {
            BottomSlideBarViewModel.shared.pubIsDraggable = false
        }
        
        mapManager.reDrawFromToMarkers()
        
    }
    
    /// Restore text search state
    /// Restore text search state.
    func restoreTextSearchState(){
        
        if let from = searchManager.from {
            let (placeText, _) = helper.getFormattedPlaceText(feature: from)
            self.model.pubFromString = placeText
            self.model.pubFromDisplayString = self.model.pubFromDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : placeText
        }else{
            self.model.pubFromString = ""
            self.model.pubFromDisplayString = ""
        }
        
        if let to = searchManager.to {
            let (placeText, _) = helper.getFormattedPlaceText(feature: to)
            
            self.model.pubToString = placeText
            self.model.pubToDisplayString = self.model.pubToDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : placeText
        }else{
            self.model.pubToString = ""
            self.model.pubToDisplayString = ""
        }
    }
    
    /// Switch locations
    /// Switch locations.
    func switchLocations() {
        mapManager.pubShowUsersCurrentLocation = false
        searchManager.switchFromAndTo()
        if let to = searchManager.to {
            let (toText, _) = helper.getFormattedPlaceText(feature: to)
            self.model.pubToString = toText
        }
        if let from = searchManager.from {
            let (fromText, _) = helper.getFormattedPlaceText(feature: from)
            self.model.pubFromString = fromText
        }
        let temp = model.pubFromDisplayString
        model.pubFromDisplayString = model.pubToDisplayString
        model.pubToDisplayString = temp
        withAnimation {
            mapManager.pubIsInTripPlan = false
        }
        MapManager.shared.cleanPlotRoute()
        tripPlanManager.isItineraryResult = true
        tripPlanManager.pubShowFullPage = true
        mapManager.pubIsInTripPlanDetail = false
        mapManager.reDrawFromToMarkers()
    }
}

#Preview {
    TripPlanningUIView(isSearchPressed: .constant(false))
}
