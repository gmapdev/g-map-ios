//
//  MapFromToView.swift
//

import SwiftUI
import Combine

class MapFromToViewModel: ObservableObject{
    @Published var pubFromString = ""
    @Published var pubToString = ""
    @Published var pubFromDisplayString = ""
    @Published var pubToDisplayString = ""
    @Published var isSettingsExpanded = false
    @Published var isPushedFrom = false
    @Published var isPushedTo = false
    @Published var pubIsTimeSettingsExpanded = false
    @Published var pubIsTripFiltersViewExpanded = false
    @Published var pubDate = Date()
    @Published var pubShowAdvancedPreferences = false
    @Published var pubShowCloseAlert = false // show custom alert view
    @Published var pubShowAccessibleTripMessage = false // show custom message view
    @Published var pubShowAdditionalModesMessage = false // show custom message view
    @Published var pubTempTopModes: [SearchMode] = [] // hold the top modes temporarily for AdvancedPreferencesView
    @Published var pubTempSubModes: [SearchMode] = [] // hold the sub modes temporarily for AdvancedPreferencesView
    
    
    @Published var pubTempDate: Date = Date.now // hold the Date temporarily for AdvancedPreferencesView
    @Published var pubTempTime: Date = Date.now // hold the time temporarily for AdvancedPreferencesView
    
    @Published var showCalenderView: Bool = false // show date picker (for AdvancedPreferencesView & HomeView)
    @Published var showTimeView: Bool = false // show time picker (for AdvancedPreferencesView & HomeView)
    
    @ObservedObject var searchSettings = SearchSettings.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var searchManager = SearchManager.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    var routePreferences: [String] = [RoutePreference.fewestTransfer.rawValue, RoutePreference.fastest.rawValue, RoutePreference.lessWalking.rawValue]
    @Published var pubSelectedRoutePreference = RoutePreference.fewestTransfer.rawValue
    
    /// Shared.
    /// - Parameters:
    ///   - MapFromToViewModel: Parameter description
    static var shared: MapFromToViewModel = {
        let model = MapFromToViewModel()
        return model
    }()
    
    /// Clear address info
    /// Clears address info.
    func clearAddressInfo(){
        pubFromString = ""
        pubToString = ""
        pubFromDisplayString = ""
        pubToDisplayString = ""
    }
    
    /// Reset action
    /// Resets action.
    func resetAction(){
        mapManager.pubShowUsersCurrentLocation = false
        self.clearAddressInfo()
        searchManager.from = nil
        searchManager.to = nil
        searchSettings.pubsSelectedTimeSetting = .leaveNow
        searchSettings.date = Date()
        mapManager.cleanPlotRoute()
        mapManager.removePreviewMarkers()
        tripPlanManager.resetTopFilters()
        tripPlanManager.resetSubfilter()
        RouteFilterPickerListViewModel.shared.resetFilter() // MARK: reset route filters.
        mapManager.followMe(enable: false)
        if let userlocation = mapManager.mapView.userLocation?.coordinate{
            mapManager.reverseLocation(latitude: userlocation.latitude, longitude: userlocation.longitude) { [self] autoComplete in
                if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                    if let feature = autocomplete.features.first {
                        if searchManager.from == nil{
                            mapManager.pubShowUsersCurrentLocation = true
                            pubFromString = feature.properties.label
                            pubFromDisplayString = "(Current Location)".localized()
                            searchManager.from = feature
                            if let location = feature.geometry?.coordinate{
                                mapManager.previewFromMarker(coordinates: location)
                            }
                        }
                    }
                }
            }
        }
        Helper.shared.saveUserPreferredSettings()
    }
    
    /// Check transit modes availability.
    /// - Parameters:
    ///   - mode: Parameter description
    /// - Returns: Bool
    func checkTransitModesAvailability(mode: SearchMode) -> Bool{
        let transitMode = mode.selectedSubModes ?? []
        for element in transitMode {
            if !tripPlanManager.pubSubModeFilterCollection.contains(element) {
                return false
            }
        }
        return true
    }
    
    /// Update states.
    /// - Parameters:
    ///   - updated: Parameter description
    /// Updates states.
    func updateStates(updated: TripTimeSettingsItem) {
        switch updated {
        case .leaveNow:
            searchSettings.pubsSelectedTimeSetting = .leaveNow
            searchSettings.date = Date()
            searchManager.dateSettings.arriveBy = nil
            searchManager.dateSettings.departAt = nil
            searchManager.dateSettings.time = nil
            tripPlanManager.isLeaveNow = true
        case .departAt:
            searchSettings.pubsSelectedTimeSetting = .departAt
            searchManager.dateSettings.departAt = searchSettings.date
            searchManager.dateSettings.arriveBy = nil
            searchManager.dateSettings.time = searchSettings.time
            tripPlanManager.isLeaveNow = false
        case .arriveBy:
            searchSettings.pubsSelectedTimeSetting = .arriveBy
            searchManager.dateSettings.arriveBy = searchSettings.date
            searchManager.dateSettings.departAt = nil
            searchManager.dateSettings.time = searchSettings.time
            tripPlanManager.isLeaveNow = false
        }
    }
}

struct MapFromToView: View {
    
    @Environment(\.presentationMode) var presentation
    
    @ObservedObject var viewModel = SearchLocationViewModel.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var model = MapFromToViewModel.shared
    @ObservedObject var settings = SearchSettings.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var tripSettingsModel = TripSettingsViewModel.shared
    @ObservedObject var searchManager = SearchManager.shared
    @ObservedObject var helper = Helper.shared
    
    @State var generalPlacesList = AppSession.shared.loginInfo?.savedLocations
    @State private var showAlert = false
    @State var iconName: String
    @State var defaultTextfieldText: String
    @State private var contentSize: CGSize = .zero
    
    var itemDidSelect: ((TripSearchSettingsItem) -> Void)? = nil
    var refreshSettingsDidSelect: (() -> Void)? = nil
    var datePressed: (() -> Void)? = nil
    
    @Binding var isSearchPressed: Bool
    
    
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
            })
        }
        else{
            ZStack {
                searchFieldView.padding(.bottom, mapManager.pubSearchRoute ? 10 : 0)
            }
            .padding(.horizontal, 10)
            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10)).shadow(radius: 5)
            .transition(.asymmetric(insertion: .scale, removal: .scale))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missed data".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
                      message: Text("Please define the following fields to plan a trip: from, to".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
                      dismissButton: .default(Text("OK".localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))))
            }
        }
        
    }
    
    /// Search field view.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchFieldView: some View {
        HStack(alignment: .top){
            if model.isPushedFrom || model.isPushedTo{
                backButton
                    .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
            }
                VStack {
                    if !mapManager.pubSearchRoute {
                        toTextView()
                    } else {
                        if AccessibilityManager.shared.pubIsLargeFontSize {
                            contentViewAODA
                        } else {
                            contentView
                        }
                    }
                }
                .padding(.horizontal, mapManager.pubSearchRoute ? 10 : 0)
            }
    }
    
    /// Content view.
    /// - Parameters:
    ///   - some: Parameter description
    private var contentView: some View {
        return VStack {
                HStack{
                    VStack(spacing: 0){
                        if !model.isPushedTo {
                            VStack{
                                HStack{
                                    fromTextView()
                                }
                                if !model.isPushedFrom {
                                    HorizontalLine(color: .gray)
                                        .padding(.trailing, 10)
                                        .offset(y: -5)
                                }
                            }
                        }
                        
                        if !model.isPushedFrom {
                            HStack{
                                toTextView().padding(.trailing, 10)
                            }
                            if !model.isPushedTo {
                                HorizontalLine(color: .gray)
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                    if !model.isPushedTo && !model.isPushedFrom{
                        VStack(spacing: 20){
                            
                            if mapManager.pubIsInTripPlan{
                                collapseButton
                            }
                            switchButton
                                .addAccessibility(text: AvailableAccessibilityItem.switchAddress.rawValue.localized())
                        }
                    }
                }
                if !(model.isPushedFrom || model.isPushedTo) && !mapManager.pubIsInTripPlan{
                    
                    filtersView
                }
            }
    }
    
    /// Content view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var contentViewAODA: some View {
            return ScrollView {
                VStack {
                    VStack{
                        VStack(spacing: 0){
                            if !model.isPushedTo {
                                VStack{
                                    HStack{
                                        fromTextView()
                                    }
                                    if !model.isPushedFrom {
                                        HorizontalLine(color: .gray)
                                            .padding(.trailing, 10)
                                            .offset(y: -5)
                                    }
                                }
                            }
                            
                            if !model.isPushedFrom {
                                HStack{
                                    toTextView().padding(.trailing, 10)
                                }
                                if !model.isPushedTo {
                                    HorizontalLine(color: .gray)
                                        .padding(.trailing, 10)
                                }
                            }
                        }
                        if !model.isPushedTo && !model.isPushedFrom{
                            VStack(spacing: 20){
                                
                                if mapManager.pubIsInTripPlan{
                                    collapseButtonAODA
                                }
                                switchButtonAODA
                                    .addAccessibility(text: AvailableAccessibilityItem.switchAddress.rawValue.localized())
                            }
                        }
                    }
                    if !(model.isPushedFrom || model.isPushedTo) && !mapManager.pubIsInTripPlan{
                        
                        filtersViewAODA
                    }
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
    }
    
    /// Restore text search state
    /// Restore text search state.
    private func restoreTextSearchState(){
        
        if let from = searchManager.from {
            let (placeText, subTitleTexts) = helper.getFormattedPlaceText(feature: from)
            self.model.pubFromString = placeText
            self.model.pubFromDisplayString = self.model.pubFromDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : placeText
        }else{
            self.model.pubFromString = ""
            self.model.pubFromDisplayString = ""
        }
        
        if let to = searchManager.to {
            let (placeText, subTitleTexts) = helper.getFormattedPlaceText(feature: to)
            
            self.model.pubToString = placeText
            self.model.pubToDisplayString = self.model.pubToDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : placeText
        }else{
            self.model.pubToString = ""
            self.model.pubToDisplayString = ""
        }
    }
    
    
    /// Back button.
    /// - Parameters:
    ///   - some: Parameter description
    private var backButton: some View {
        Button(action: {
            backButtonAction()
        }) {
            Image("ic_leftarrow")
                .renderingMode(.template)
                .resizable()
                .padding(5)
                .foregroundColor(.black)
        }
        .frame(width: 25, height: 30)
        .padding(.top, 20)
        .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
        .accessibilityAction {
            backButtonAction()
        }
    }
    
    /// Switch button.
    /// - Parameters:
    ///   - some: Parameter description
    private var switchButton: some View {
        Button(action: {
            mapManager.pubShowUsersCurrentLocation = false
            searchManager.switchFromAndTo()
            if let to = searchManager.to {
                let (toText, subTitleTexts) = helper.getFormattedPlaceText(feature: to)
                self.model.pubToString = toText
            }
            if let from = searchManager.from {
                let (fromText, subTitleTexts) = helper.getFormattedPlaceText(feature: from)
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
        }) {
            Image("ic_switch")
                .renderingMode(.template)
                .resizable()
                .padding(7)
                .foregroundColor(.black)
        }
        .background(Color.white)
        .frame(width: 40, height: 40)
        
    }
    
    /// Switch button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var switchButtonAODA: some View {
        Button(action: {
            mapManager.pubShowUsersCurrentLocation = false
            searchManager.switchFromAndTo()
            if let to = searchManager.to {
                let (toText, subTitleTexts) = helper.getFormattedPlaceText(feature: to)
                self.model.pubToString = toText
            }
            if let from = searchManager.from {
                let (fromText, subTitleTexts) = helper.getFormattedPlaceText(feature: from)
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
        }) {
            HStack {
                Spacer()
                TextLabel("Switch Locations", .bold)
                    .lineLimit(2)
                Spacer()
            }
        }
        .background(Color.white)
        .roundedBorder(10)
        
    }
    
    /// Settings button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var settingsButtonAODA: some View {
        var submodeFilterCount = 0
        if FeatureConfig.shared.searchModes.count > 0 {
            let submodeFilters = FeatureConfig.shared.searchModes[0]
            if let modes = submodeFilters.selectedSubModes {
                submodeFilterCount = modes.count
            }
        }
        return ZStack{
            Button(action: {
                if !tripPlanManager.pubModeFilterCollection.isEmpty {
                    model.isSettingsExpanded.toggle()
                    if model.isSettingsExpanded{
                        model.pubIsTimeSettingsExpanded = false
                    }
                }
            }) {
                Image("ic_more")
                    .renderingMode(.template)
                    .resizable()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                    .foregroundColor(.black)
            }
            .frame(width: 70, height: 70)
            if tripSettingsModel.isSubFilterValueChanged{
                Circle().fill(Color.badgeColor).frame(width: 12, height: 12, alignment: .center)
                    .offset(x: 35, y: -25)
            }
        }
        
    }
    
    /// Settings button.
    /// - Parameters:
    ///   - some: Parameter description
    private var settingsButton: some View {
        return ZStack{
            Button(action: {
                if !tripPlanManager.pubModeFilterCollection.isEmpty {
                    model.isSettingsExpanded.toggle()
                    if model.isSettingsExpanded{
                        model.pubIsTimeSettingsExpanded = false
                    }
                }
            }) {
                Image("ic_more")
                    .renderingMode(.template)
                    .resizable()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                    .foregroundColor(.black)
            }
            .frame(width: 40, height: 48)
            if tripSettingsModel.isSubFilterValueChanged{
                Circle().fill(Color.badgeColor).frame(width: 8, height: 8, alignment: .center)
                    .offset(x: 18, y: -22)
            }
        }
        
    }
    
    /// Filter button.
    /// - Parameters:
    ///   - some: Parameter description
    private var filterButton: some View {
        return ZStack{
            Button(action: {
                model.pubIsTripFiltersViewExpanded.toggle()
                if model.isSettingsExpanded{
                    model.pubIsTimeSettingsExpanded = false
                }
            }) {
                Image("ic_filter")
                    .renderingMode(.template)
                    .resizable()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                    .foregroundColor(.black)
            }
            .frame(width: 80, height: 60)
            if checkBadgeConditions(){
                Circle().fill(Color.badgeColor).frame(width: 8, height: 8, alignment: .center)
                    .offset(x: 35, y: -22)
            }
        }
        
    }
    
    /// Filter button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var filterButtonAODA: some View {
        return ZStack{
            Button(action: {
                model.pubIsTripFiltersViewExpanded.toggle()
                if model.isSettingsExpanded{
                    model.pubIsTimeSettingsExpanded = false
                }
            }) {
                Image("ic_filter")
                    .renderingMode(.template)
                    .resizable()
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                    .foregroundColor(.black)
            }
            .frame(width: 130, height: 90)
            if checkBadgeConditions() {
                Circle().fill(Color.badgeColor).frame(width: 12, height: 12, alignment: .center)
                    .offset(x: 63, y: -25)
            }
        }
        
    }
    
    /// Check badge conditions
    /// - Returns: Bool
    /// Checks badge conditions.
    func checkBadgeConditions() -> Bool  {
        if self.tripPlanManager.pubModeFilterCollection.count < 1 || self.tripPlanManager.pubModeFilterCollection[0].mode != "TRANSIT" || self.tripPlanManager.pubModeFilterCollection.count > 1{
            return true
        }
        return false
    }
    
    /// Back button action
    /// Back button action.
    private func backButtonAction(){
        mapManager.cleanPlotRoute()
        mapManager.plantTripPlotItems = nil
        if model.isPushedFrom{
            model.isPushedFrom.toggle()
            self.restoreTextSearchState()
        }
        else if model.isPushedTo{
            model.isPushedTo.toggle()
            self.restoreTextSearchState()
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
    
    /// Collapse button.
    /// - Parameters:
    ///   - some: Parameter description
    private var collapseButton: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                mapManager.pubHideAddressBar.toggle()
            }
        } label: {
            Image(mapManager.pubHideAddressBar ? "btn_expand" : "btn_collapse")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.black)
            
        }.background(Color.white)
            .frame(width: 48, height: 48, alignment: .center)
            .addAccessibility(text: (mapManager.pubHideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
    
    /// Collapse button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var collapseButtonAODA: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                mapManager.pubHideAddressBar.toggle()
            }
        } label: {
            HStack {
                Spacer()
                TextLabel("Show Map View",.bold)
                    .lineLimit(2)
                Spacer()
            }
            
        }.background(Color.white)
            .roundedBorder(10)
            .addAccessibility(text: (mapManager.pubHideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
    
    
    /// From text view
    /// - Returns: some View
    /// From text view.
    func fromTextView() -> some View {
        return VStack{
            if model.isPushedFrom{
                searchTextField.padding(.top, 10)
                HorizontalLine(color: .gray)
                    .padding(.trailing, 10)
                    .offset(y: AccessibilityManager.shared.pubIsLargeFontSize ? 5 : -5)
                searchListView
                Spacer()
            }else{
                VStack{
                    HStack{
                        fromTextField.padding(.top, 10)
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
                        HorizontalLine(color: .gray)
                            .padding(.trailing, 10)
                            .offset(y: AccessibilityManager.shared.pubIsLargeFontSize ? 5 : -5)
                    }
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        Spacer().frame(height: 10)
                    }
                }
            }
            
        }
    }
    
    /// To text view
    /// - Returns: some View
    /// To text view.
    func toTextView() -> some View {

        
        return VStack{
            if model.isPushedTo {
                searchTextField
                   
                
                HorizontalLine(color: .gray)
                    .padding(.trailing, 10)
                    .offset(y: AccessibilityManager.shared.pubIsLargeFontSize ? 10 : 0)
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    Spacer().frame(height: 10)
                }
                searchListView
                Spacer()
            }else{
                toTextField
            }
        }
    }
    
    /// To text field.
    /// - Parameters:
    ///   - some: Parameter description
    private var toTextField: some View{
        VStack{
            TripLocationView(placeholder: mapManager.pubSearchRoute ? "Enter destination or choose on map".localized() : "\(self.defaultTextfieldText)".localized(),
                             lineColor: Color.gray,
                             imageName: mapManager.pubSearchRoute ? "ic_destination" : self.iconName, isLargeFont: AccessibilityManager.shared.pubIsLargeFontSize,
                             action: {
                model.isPushedTo = true
                mapManager.isMapSettings = false
                model.isSettingsExpanded = false
                updateFromToStringForAnnotation()
                model.isPushedFrom = false
                withAnimation {
                    mapManager.pubIsInTripPlan = false
                }
                mapManager.isSearchingPlace = true
            },text: self.$model.pubToDisplayString)
            .frame(minHeight: 50)
        }
    }
    
    /// From text field.
    /// - Parameters:
    ///   - some: Parameter description
    private var fromTextField: some View{
        VStack{
            TripLocationView(placeholder: "Enter start location or choose on map".localized(),
                             lineColor: Color.gray,
                             imageName: "ic_origin", isLargeFont: AccessibilityManager.shared.pubIsLargeFontSize,
                             action: {
                model.isPushedFrom = true
                mapManager.isMapSettings = false
                model.isSettingsExpanded = false
                updateFromToStringForAnnotation()
                model.isPushedTo = false
                withAnimation {
                    mapManager.pubIsInTripPlan = false
                }
                mapManager.isSearchingPlace = true
            },text: self.$model.pubFromDisplayString)
        }
    }
    
    /// Search text field.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchTextField: some View {
        
        return VStack {
            LocationTextField(placeholder: model.isPushedFrom ? "Enter start location".localized() : "Enter destination".localized(),
                              lineColor: Color.black, leadingPadding: 0, showClearButton: true, 
                              text: $viewModel.searchText)
            .frame(height: 50)
            .padding(.top, model.isPushedTo ? 10 : 0)
        }
    }
    
    /// Search list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchListView: some View {
        ScrollView {
            VStack {
                Spacer().frame(height: 10)
                if (AppSession.shared.loginInfo != nil) {
                    ForEach( 0..<SearchLocationViewModel.shared.searchedSavedLocations.count, id: \.self) { idx in
                        savedLocationView(location: SearchLocationViewModel.shared.searchedSavedLocations[idx])
                    }
                    if SearchLocationViewModel.shared.searchedSavedLocations.count > 0 {
                        Spacer().frame(height: 10)
                    }
                }
                if viewModel.getStopLocations().count > 0 {
                    HStack{
                        TextLabel("Stops".localized(), .bold, .body).foregroundColor(Color.black)
                            .addAccessibility(text: "Stops, %1 in total".localized(viewModel.getStopLocations().count))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                    }
                }
                ForEach(viewModel.getStopLocations()) { location in
                    item(by: location)
                }

                if viewModel.getOtherLocations().count > 0 {
                    HStack{
                        TextLabel("Other".localized(), .bold, .body).foregroundColor(Color.black)
                            .addAccessibility(text: "Other Places, %1 in total".localized(viewModel.getOtherLocations().count))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                    }
                }
                ForEach(viewModel.getOtherLocations()) { location in
                    item(by: location)
                }
                
                
                if !viewModel.recentLocations.isEmpty {
                    recentListView
                }
                currentLocationView()
                if settings.pubIsProcessing{
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
            settings.pubIsProcessing = true
            LoginAuthProvider().getUserInfo {
                DispatchQueue.main.async {
                    settings.pubIsProcessing = false
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
    private var recentListView: some View {
        return VStack {
            HStack {
                TextLabel("Recently Searched".localized(), .bold, .body)
                    .foregroundColor(Color.black)
                    .addAccessibility(text: "Recently Searched Address".localized())
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(3)
                Spacer()
            }
            .frame(alignment: .leading)
            .padding(.horizontal, 0)
            ForEach(viewModel.recentLocations) { location in
                item(by: location, isRecent: true)
            }
        }
        .background(Color.white)
    }
    
    /// Item.
    private func item(by location: SearchLocationItem,
                      isRecent: Bool = false) -> SearchItemView {
        let imageName =  isRecent ? "search_icon" : "location_pin_icon"
        let (titleText, subTitleTexts) = helper.getFormattedPlaceText(feature: location.feature)
        var itemView = SearchItemView(imageName: imageName,
                                      titleText: titleText, subTexts: subTitleTexts)
        itemView.action = {
            mapManager.cleanPlotRoute()
            viewModel.saveFeature(location.feature, isRecent: isRecent)
            viewModel.searchText = ""
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
                                viewModel.searchText = ""
                                if model.isPushedTo{
                                    model.isPushedTo = false
                                    model.pubToString = feature.properties.label
                                    model.pubToDisplayString = "(Current Location)".localized()
                                    searchManager.to = feature
                                }else{
                                    model.isPushedFrom = false
                                    model.pubFromString = feature.properties.label
                                    model.pubFromDisplayString =  "(Current Location)".localized()
                                    searchManager.from = feature
                                }
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
    private func savedLocationView(location: FavouriteLocation) -> MyLocationItemView?{
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
            let properties = Autocomplete.Properties(id: location.id.uuidString, name: location.name, label: location.address, gid: location.id.uuidString, layer: nil, source: nil, source_id: nil, accuracy: nil, modes: [], street: nil, neighbourhood: nil, locality: nil, region_a: nil, secondaryLabels: nil)
            let coordinate = Coordinate(lat: location.lat, long: location.lon)
            let geometry = Autocomplete.Geometry(type: location.type, coordinate: coordinate)
            let feature = Autocomplete.Feature(properties: properties, geometry: geometry, id: location.id.uuidString)
            if model.isPushedTo {
                model.isPushedTo = false
                let (toString, subTitleTexts) = helper.getFormattedPlaceText(feature: feature)
                model.pubToString = toString
                model.pubToDisplayString = toString
                searchManager.to = feature
            } else if model.isPushedFrom {
                mapManager.pubShowUsersCurrentLocation = false
                model.isPushedFrom = false
                let (fromString, subTitleTexts) = helper.getFormattedPlaceText(feature: feature)
                model.pubFromString = fromString
                model.pubFromDisplayString = fromString
                searchManager.from = feature
            }
            
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
            if mapManager.isSearchingPlace {
                mapManager.isSearchingPlace = false
            }
            UIApplication.shared.dismissKeyboard()
            presentation.wrappedValue.dismiss()
        }
        return itemView
    }
    
    /// Filters view.
    /// - Parameters:
    ///   - some: Parameter description
    var filtersView: some View {
        VStack {
            TripFilterActionsView(date: $model.pubDate, settings: settings,
                                  timeSettingsAction: {
                model.pubIsTimeSettingsExpanded.toggle()
                if model.pubIsTimeSettingsExpanded {
                    model.isSettingsExpanded = false
                }
            })
            HStack(spacing: 0){
                settingsButton
                    .addAccessibility(text: AvailableAccessibilityItem.settingButton.rawValue.localized())
                filterButton.padding(.trailing, 10)
                    .addAccessibility(text: AvailableAccessibilityItem.filterButton.rawValue.localized())
                Spacer()
                resetButton
                    .padding([.vertical, .trailing], 10)
                    .addAccessibility(text: AvailableAccessibilityItem.resetButton.rawValue.localized())
                searchButton
                    .addAccessibility(text: AvailableAccessibilityItem.planTripButton.rawValue.localized())
            }
            .padding(.bottom, 5)
        }
    }
    
    /// Filters view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var filtersViewAODA: some View {
        VStack {
            TripFilterActionsView(date: $model.pubDate, settings: settings,
                                  timeSettingsAction: {
                model.pubIsTimeSettingsExpanded.toggle()
                if model.pubIsTimeSettingsExpanded {
                    model.isSettingsExpanded = false
                }
            })
            VStack {
                HStack(spacing: 0){
                    settingsButtonAODA
                        .addAccessibility(text: AvailableAccessibilityItem.settingButton.rawValue.localized())
                    Spacer()
                    filterButtonAODA.padding(.trailing, 10)
                        .addAccessibility(text: AvailableAccessibilityItem.filterButton.rawValue.localized())
                    Spacer()
                    resetButtonAODA
                        .padding([.vertical, .trailing], 10)
                        .addAccessibility(text: AvailableAccessibilityItem.resetButton.rawValue.localized())
                }
                searchButtonAODA
                    .addAccessibility(text: AvailableAccessibilityItem.planTripButton.rawValue.localized())
            }
        }
    }
    
    /// Search button.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchButton: some View {
        Button(action: {
            searchAction()
        }, label: {
            HStack{
                TextLabel("Plan trip".localized(), .bold, .subheadline)
                    .foregroundColor(ThemeConfig.shared.plan_trip_button_in_search_font_color)
            }
            .padding(.horizontal, 10)
        })
        .frame(height: 50)
        .background(ThemeConfig.shared.plan_trip_button_in_search_bg_color)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    /// Search button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchButtonAODA: some View {
        Button(action: {
            searchAction()
        }, label: {
            HStack{
                Spacer()
                TextLabel("Plan trip".localized(), .bold)
                    .foregroundColor(Color.black)
                Spacer()
            }
            .padding(.horizontal, 10)
        })
        .background(ThemeConfig.shared.plan_trip_button_in_search_bg_color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .roundedBorderWithColor(10, 0, Color.black, 2)
    }
    
    /// Reset button.
    /// - Parameters:
    ///   - some: Parameter description
    private var resetButton: some View {
        Button(action: {
            model.resetAction()
        }, label: {
            HStack{
                Image("ic_reset")
                    .renderingMode(.template)
                    .resizable()
                    .font(.system(size: 10, weight: .regular))
                    .frame(width: 26, height: 30)
                    .foregroundColor(.gray)
                
            }
        })
        .frame(width: 50, height: 50)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    /// Reset button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var resetButtonAODA: some View {
        Button(action: {
            model.resetAction()
        }, label: {
            HStack{
                Image("ic_reset")
                    .renderingMode(.template)
                    .resizable()
                    .font(.system(size: 10, weight: .regular))
                    .frame(width: 36, height: 40)
                    .foregroundColor(.gray)
                
            }
        })
        .frame(width: 70, height: 70)
        .background(Color.white)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    /// Search action
    /// Searches action.
    func searchAction(){
        
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
        if !selectedModes.contains(where: {$0.mode == "TRANSIT"}){
            selectedSubModes.removeAll()
        }
        if selectedModes.contains(where: {$0.mode == "ST-RENT"}) {
            if TripSettingsViewModel.shared.isAllowScooterRentalSelected {
                let mode = SearchMode(mode: "SCOOTER_RENT", label: "SCOOTER_RENT", mode_image: "", marker_image: "", line_color: "", color: "")
                selectedSubModes.append(mode)
            }
            if TripSettingsViewModel.shared.isAllowBikeRentalSelected {
                let mode = SearchMode(mode: "BICYCLE_RENT", label: "BICYCLE_RENT", mode_image: "", marker_image: "", line_color: "", color: "")
                selectedSubModes.append(mode)
            }
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
            let (toText, subTitleTexts) = helper.getFormattedPlaceText(feature: to)
            self.model.pubToString = toText
            self.model.pubFromDisplayString = self.model.pubFromDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : self.model.pubFromDisplayString
        }
        if let from = searchManager.from {
            let (fromText, subTitleTexts) = helper.getFormattedPlaceText(feature: from)
            self.model.pubFromString = fromText
            self.model.pubToDisplayString = self.model.pubToDisplayString == "(Current Location)".localized() ? "(Current Location)".localized() : self.model.pubToDisplayString
        }
    }
    
}
