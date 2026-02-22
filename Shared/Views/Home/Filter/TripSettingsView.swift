//
//  TripSettingsView.swift
//

import SwiftUI

enum TripSearchSettings: Codable {
    case walkMax, walkSpeed, optimize
}

struct TripSearchSettingsItem: Codable {
    let item: TripSearchSettings
    var defaultValue: String
    let allValues: [String]
}

extension TripSearchSettingsItem {
    /// Item.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: TripSearchSettingsItem
    static func item(for criteria: TripSearchSettings) -> TripSearchSettingsItem {
        switch criteria {
        case .walkMax: return TripSearchSettingsItem(item: .walkMax,
													 defaultValue: FeatureConfig.shared.defaultCriterias.maximumWalk,
													 allValues: FeatureConfig.shared.availableCriterias.maximumWalk)
        case .walkSpeed: return TripSearchSettingsItem(item: .walkSpeed,
                                                       defaultValue: String(FeatureConfig.shared.defaultCriterias.walkSpeed),
                                                       /// Initializes a new instance.
                                                       allValues: FeatureConfig.shared.availableCriterias.walkSpeed.flatMap { $0.keys.map(String.init) })
        case .optimize: return TripSearchSettingsItem(item: .optimize,
                                                      defaultValue: FeatureConfig.shared.defaultCriterias.optimize,
                                                      allValues: FeatureConfig.shared.availableCriterias.optimize)
        }
    }
}

extension TripSearchSettingsItem {
    /// Title text.
    /// - Parameters:
    ///   - String: Parameter description
    var titleText: String {
        switch item {
        case .walkMax: return "MAXIMUM WALK".localized()
        case .walkSpeed: return "Walk Speed".localized()
        case .optimize: return "OPTIMIZE FOR".localized()
        }
    }
}

class TripSettingsViewModel: ObservableObject {
    @Published var pubDidItemSelected = false
	
	@Published var pubWalkMax = TripSearchSettingsItem.item(for: .walkMax)
	@Published var pubWalkSpeed = TripSearchSettingsItem.item(for: .walkSpeed)
	@Published var pubOptimized = TripSearchSettingsItem.item(for: .optimize)
    
    @Published var isAvoidWalkingSelected = SearchManager.shared.userCriterias.avoidWalking ?? false
    @Published var isAccessibleRoutingSelected = SearchManager.shared.userCriterias.accessibleRouting ?? false
    @Published var isAllowBikeRentalSelected = SearchManager.shared.userCriterias.allowBikeRental ?? true
    @Published var isAllowScooterRentalSelected = SearchManager.shared.userCriterias.allowScooterRental ?? true
    @Published var isSubFilterValueChanged = false
    
    @Published var isTransitSelected: Bool = true
    @Published var isRentSelected: Bool = true
    
    @Published var pubMobilityProfileDropdownItems = ["Myself"]
    @Published var pubSelectedMobilityProfile = "Myself"
    
    /// Shared.
    /// - Parameters:
    ///   - TripSettingsViewModel: Parameter description
    public static var shared: TripSettingsViewModel = {
        let viewModel = TripSettingsViewModel()
        return viewModel
    }()
    
    /// Check settings
    /// Checks settings.
    func checkSettings(){
        let selectedModes = TripPlanningManager.shared.pubModeFilterCollection
        if selectedModes.contains(where: { $0.mode == "TRANSIT"}){
            isTransitSelected = true
        }else{
            isTransitSelected = false
        }
        if selectedModes.contains(where: { $0.mode == "ST-RENT"}){
            isRentSelected = true
        }else{
            isRentSelected = false
        }
    }
    
    /// Is settings required
    /// - Returns: Bool
    /// Checks if settings required.
    func isSettingsRequired() -> Bool{
        let selectedModes = TripPlanningManager.shared.pubModeFilterCollection
        return selectedModes.contains(where: { $0.mode == "TRANSIT"}) || selectedModes.contains(where: { $0.mode == "ST-RENT"}) || selectedModes.contains(where: { $0.mode == "BICYCLE"})
    }
}

struct TripSettingsView: View {
    @ObservedObject var model = TripSettingsViewModel.shared
	@ObservedObject var pickerModel = PickerListViewModel.shared
    @ObservedObject var tripsFilterModel = TripTransitFiltersViewModel.shared
	
    var itemDidSelect: ((TripSearchSettingsItem) -> Void)? = nil
    var refreshSettingsDidSelect: (() -> Void)? = nil
    
    @State var showDropdownMenu: Bool = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
            VStack{
                Spacer()
                HStack{
                    Spacer()
                }
            }.background(Color.black).opacity(0.43).ignoresSafeArea(edges: .all)
			.onTapGesture {
                TripPlanningManager.shared.updateSubFilter()
                MapFromToViewModel.shared.isSettingsExpanded = false
                Helper.shared.saveUserPreferredSettings()
            }
            .addAccessibility(text: AvailableAccessibilityItem.blackAreaFliter.rawValue.localized())
            .accessibilityAction {
                TripPlanningManager.shared.updateSubFilter()
                MapFromToViewModel.shared.isSettingsExpanded = false
                Helper.shared.saveUserPreferredSettings()
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        TripPlanningManager.shared.updateSubFilter()
                        MapFromToViewModel.shared.isSettingsExpanded.toggle()
                        Helper.shared.saveUserPreferredSettings()
                    }, label: {
                        Image("cancel_icon")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: 20, height: 20)
                    })
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .addAccessibility(text: "Close button, Double tap to activate".localized())
                    .accessibilityAction {
                        TripPlanningManager.shared.updateSubFilter()
                        MapFromToViewModel.shared.isSettingsExpanded.toggle()
                        Helper.shared.saveUserPreferredSettings()
                    }
                }
                Spacer()
            }
            
            VStack{
                Spacer()
                if model.pubDidItemSelected{
                    VStack{
                        pickerListView.frame(height: 250)
                            
                        Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white).zIndex(999)
                    }
					.edgesIgnoringSafeArea(.bottom)
					.padding(.top, 10)
                    .background(Color.white)
					.clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                    .transition(.scale)
                }
                else {
                    VStack {
                        HStack {
                            TextLabel("Preferred mode of Travel:".localized(), .bold, .body)
                                .foregroundColor(Color.black)
                            Spacer()
                        }
                        if model.isTransitSelected{
                            topActionsView.frame(height: tripsFilterModel.getViewHeight())
                                .padding(.bottom, 20)
                            
                            if SearchManager.shared.userCriterias.avoidWalking != nil{
                                CheckBoxView(isChecked: model.isAvoidWalkingSelected, title: "Avoid Walking", icon: "", checboxSize: 20) {
                                    model.isAvoidWalkingSelected.toggle()
                                    if let _ = SearchManager.shared.userCriterias.avoidWalking {
                                        SearchManager.shared.userCriterias.avoidWalking?.toggle()
                                    }
                                }.padding(.bottom, 5)
                            }
                            
                            if SearchManager.shared.userCriterias.accessibleRouting != nil {
                                CheckBoxView(isChecked: model.isAccessibleRoutingSelected, title: "Accessible Routing", icon: "", checboxSize: 20) {
                                    model.isAccessibleRoutingSelected.toggle()
                                    if let _ = SearchManager.shared.userCriterias.accessibleRouting {
                                        SearchManager.shared.userCriterias.accessibleRouting?.toggle()
                                    }
                                }.padding(.bottom, 5)
                            }
                            
                            TripSearchSettingsItemView(item: model.pubWalkSpeed) { item in
                                itemDidSelect?(item)
                            }
                            
                            if let _ = AppSession.shared.loginInfo {
                                if !TravelCompanionsViewModel.shared.pubDependents.isEmpty{
                                    VStack{
                                        HStack{
                                            TextLabel("Mobility Profile".localized(), .bold, .callout)
                                                .padding(.bottom, 5)
                                            Spacer()
                                        }
                                        HStack{
                                            TextLabel("If you have a travel companion, you can choose to plan this trip according to their mobility profile.".localized(), .regular, .subheadline)
                                            Spacer()
                                        }
                                        HStack{
                                            TextLabel("User mobility profile:".localized(), .semibold, .subheadline)
                                            Spacer()
                                            TripSettingDropDownMenuView(title: model.pubSelectedMobilityProfile, choices: model.pubMobilityProfileDropdownItems) { selectedChoice in
                                                model.pubSelectedMobilityProfile = selectedChoice
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if model.isRentSelected{
                            CheckBoxView(isChecked: model.isAllowBikeRentalSelected, title: "Allow Bike Rental", icon: "", checboxSize: 20) {
                                model.isAllowBikeRentalSelected.toggle()
                                if let _ = SearchManager.shared.userCriterias.allowBikeRental {
                                    SearchManager.shared.userCriterias.allowBikeRental?.toggle()
                                }
                            }.padding(.bottom, 5)
                            
                            CheckBoxView(isChecked: model.isAllowScooterRentalSelected, title: "Allow Scooter Rental", icon: "", checboxSize: 20) {
                                model.isAllowScooterRentalSelected.toggle()
                                if let _ = SearchManager.shared.userCriterias.allowScooterRental {
                                    SearchManager.shared.userCriterias.allowScooterRental?.toggle()
                                }
                            }.padding(.bottom, 5)
                        }
                        
                        Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white)
                    }
					.padding(.top, 20).padding(.horizontal, 15)
					.background(Color.white)
					.clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                }
            }
			.ignoresSafeArea(edges: .bottom)
            .onAppear{
                model.checkSettings()
            }
        }
    }
    
    /// Transit filters view.
    /// - Parameters:
    ///   - some: Parameter description
    private var transitFiltersView: some View {
        return TripTransitFiltersView()
    }
    
    /// Top actions view.
    /// - Parameters:
    ///   - some: Parameter description
    private var topActionsView: some View {
        VStack(alignment: .leading){
			Spacer().frame(height:10)
            transitFiltersView
        }
    }
    
    private var forgetButton: some View {
        Button(action: {
            
        }) {
            HStack(alignment: .center) {
                TextLabel("Forget my options".localized(), .semibold, .footnote)
                    .foregroundColor(.main)
            }
        }
        .frame(height: 48)
    }
    
    /// Restore button.
    /// - Parameters:
    ///   - some: Parameter description
    private var restoreButton: some View {
        Button(action: {
			SearchManager.shared.userCriterias = FeatureConfig.shared.defaultCriterias
            refreshSettingsDidSelect?()
        }) {
            HStack(alignment: .center) {
                TextLabel("Restore to defaults".localized(), .semibold, .footnote)
                    .foregroundColor(.main)
            }
        }
        .frame(height: 48)
    }
    
    /// Picker list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var pickerListView: some View {
        var pickerView: PickerListView =  PickerListView()
        pickerView.cancelAction = {
            withAnimation {
                TripSettingsViewModel.shared.pubDidItemSelected.toggle()
            }
            
        }

        pickerView.doneAction = {
            withAnimation {
                TripSettingsViewModel.shared.pubDidItemSelected.toggle()
            }
        }
        return pickerView
    }
}

struct TripSettingsViewAODA: View {
    @ObservedObject var model = TripSettingsViewModel.shared
    @ObservedObject var pickerModel = PickerListViewModel.shared
    
    var itemDidSelect: ((TripSearchSettingsItem) -> Void)? = nil
    var refreshSettingsDidSelect: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ScrollView {
            VStack{
                Spacer()
                if model.pubDidItemSelected{
                    VStack{
                        pickerListViewAODA
                        
                        Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white).zIndex(999)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .padding(.top, 10)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                    .transition(.scale)
                }
                else {
                    VStack {
                        HStack {
                            TextLabel("Search Settings".localized(), .bold, .body)
                                .foregroundColor(Color.black)
                                .padding(.top,20)
                            Spacer()
                            Button(action: {
                                TripPlanningManager.shared.updateSubFilter()
                                MapFromToViewModel.shared.isSettingsExpanded.toggle()
                                Helper.shared.saveUserPreferredSettings()
                            }, label: {
                                Image("cancel_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .foregroundColor(Color.white)
                                    .frame(width: 30, height: 30)
                            })
                            .padding(12)
                            .background(Color.java_main)
                            .clipShape(Circle())
                            .addAccessibility(text: "Close button, Double tap to activate".localized())
                        }
                    if model.isTransitSelected{
                        topActionsViewAODA
                            .padding(.bottom, 10)
                        if SearchManager.shared.userCriterias.avoidWalking != nil{
                            HStack {
                                Spacer()
                                TextLabel("Avoid Walking".localized(), .bold, .subheadline)
                                    .foregroundColor(Color.black)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .roundedBorderWithColor(10,5,Color.java_main,2)
                            .background(model.isAvoidWalkingSelected ? Color.java_main : Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onTapGesture {
                                model.isAvoidWalkingSelected.toggle()
                               SearchManager.shared.userCriterias.avoidWalking = model.isAvoidWalkingSelected
                                    
                            }
                        }
                        
                        if SearchManager.shared.userCriterias.accessibleRouting != nil{
                            HStack {
                                Spacer()
                                TextLabel("Accessible Routing".localized(), .bold, .subheadline)
                                    .foregroundColor(Color.black)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .roundedBorderWithColor(10,5,Color.java_main,2)
                            .background(model.isAccessibleRoutingSelected ? Color.java_main : Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onTapGesture {
                                model.isAccessibleRoutingSelected.toggle()
                                SearchManager.shared.userCriterias.accessibleRouting = model.isAccessibleRoutingSelected
                            }
                        }
                        
                        TripSearchSettingsItemView(item: model.pubWalkSpeed) { item in
                            itemDidSelect?(item)
                        }.padding(.bottom, 5)
                    }
                        if model.isRentSelected{
                            HStack {
                                Spacer()
                                TextLabel("Allow Bike Rental".localized(), .bold, .subheadline)
                                    .foregroundColor(Color.black)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .roundedBorderWithColor(10,5,Color.java_main,2)
                            .background(model.isAllowBikeRentalSelected ? Color.java_main : Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onTapGesture {
                                model.isAllowBikeRentalSelected.toggle()
                                SearchManager.shared.userCriterias.allowBikeRental = model.isAllowBikeRentalSelected
                            }
                            
                            HStack {
                                Spacer()
                                TextLabel("Allow Scooter Rental".localized(), .bold, .subheadline)
                                    .foregroundColor(Color.black)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .roundedBorderWithColor(10,5,Color.java_main,2)
                            .background(model.isAllowScooterRentalSelected ? Color.java_main : Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            .onTapGesture {
                                model.isAllowScooterRentalSelected.toggle()
                                SearchManager.shared.userCriterias.allowScooterRental = model.isAllowScooterRentalSelected
                            }
                        }
                        
                        Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white)
                    }.padding(.horizontal, 15)
                    .background(Color.white)
                    .clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                }
            }
            .onAppear{
                model.checkSettings()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(Color.white)
    }
    
    /// Transit filters view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var transitFiltersViewAODA: some View {
        return TripTransitFiltersViewAODA()
    }
    
    /// Top actions view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var topActionsViewAODA: some View {
        VStack(alignment: .leading){
            
            Spacer().frame(height: 10)
            transitFiltersViewAODA
        }
    }
    
    private var forgetButtonAODA: some View {
        Button(action: {
            
        }) {
            HStack(alignment: .center) {
                TextLabel("Forget my options".localized(), .semibold, .footnote)
                    .foregroundColor(.main)
            }
        }
    }
    
    /// Restore button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var restoreButtonAODA: some View {
        Button(action: {
            SearchManager.shared.userCriterias = FeatureConfig.shared.defaultCriterias
            refreshSettingsDidSelect?()
        }) {
            HStack(alignment: .center) {
                TextLabel("Restore to defaults".localized(), .semibold, .footnote)
                    .foregroundColor(.main)
            }
        }
    }
    
    /// Picker list view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var pickerListViewAODA: some View {
        var pickerView: PickerListViewAODA =  PickerListViewAODA()
        pickerView.cancelAction = {
            withAnimation {
                TripSettingsViewModel.shared.pubDidItemSelected.toggle()
            }
            
        }

        pickerView.doneAction = {
            withAnimation {
                TripSettingsViewModel.shared.pubDidItemSelected.toggle()
            }
        }
        return pickerView
    }
}
