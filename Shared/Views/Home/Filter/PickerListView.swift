//
//  PickerListView.swift
//

import SwiftUI
import Combine

struct PickerLisItem: Identifiable {
    var id: UUID = UUID()
    let item: String
    let settings: TripSearchSettings
    var isSelected: Bool
    
    /// Deselect
    /// Deselect.
    mutating func deselect() {
        self.isSelected = false
    }
    
    /// Select
    /// Select.
    mutating func select() {
        self.isSelected = true
    }
}

final class PickerListViewModel: ObservableObject {
    @ObservedObject var tripSettingsModel = TripSettingsViewModel.shared
    @Published var pubItems = [PickerLisItem]()
    var item: TripSearchSettingsItem = TripSearchSettingsItem(item: .walkSpeed,
                                                              defaultValue: String(SearchManager.shared.userCriterias.walkSpeed),
                                                              /// Initializes a new instance.
                                                              allValues: FeatureConfig.shared.availableCriterias.walkSpeed.flatMap { $0.keys.map(String.init) })
    var isMaxWlakChanged: Bool = false
    var isWlakSpeedChanged: Bool = false
    var isOptimizeForChanged: Bool = false
    /// Shared.
    /// - Parameters:
    ///   - PickerListViewModel: Parameter description
    static var shared: PickerListViewModel = {
        let mgr = PickerListViewModel()
        return mgr
    }()
    
    /// Load item
    /// Loads item.
    func loadItem(){
        self.pubItems = self.item.allValues.map({
            let isSelected = $0 == item.defaultValue
            return PickerLisItem(item: $0, settings: item.item, isSelected: isSelected)
        })
    }
    
    /// Did select item at index.
    /// - Parameters:
    ///   - _: Parameter description
    /// Handles when did select item at index.
    func didSelectItemAtIndex(_ index: Int) {
        let newItem = item.allValues[index]
        pubItems = pubItems.map({
            var newValue = $0
            newValue.isSelected = newItem == $0.item
            return newValue
        })
    }
    
    /// Reset crieria picker
    /// Resets crieria picker.
    func resetCrieriaPicker(){
        let defaultMaximumWalk = FeatureConfig.shared.defaultCriterias.maximumWalk
        let defaultWalkSpeed = FeatureConfig.shared.defaultCriterias.walkSpeed
        let defaultOptimize = FeatureConfig.shared.defaultCriterias.optimize
        
        TripPlanningManager.shared.selectedCriterias.maximumWalk = defaultMaximumWalk
        SearchManager.shared.userCriterias.maximumWalk = defaultMaximumWalk
        tripSettingsModel.pubWalkMax = TripSearchSettingsItem.item(for: .walkMax)
        
        TripPlanningManager.shared.selectedCriterias.walkSpeed = defaultWalkSpeed
        SearchManager.shared.userCriterias.walkSpeed = defaultWalkSpeed
        tripSettingsModel.pubWalkSpeed = TripSearchSettingsItem.item(for: .walkSpeed)
        
        TripPlanningManager.shared.selectedCriterias.optimize = defaultOptimize
        SearchManager.shared.userCriterias.optimize = defaultOptimize
        tripSettingsModel.pubOptimized = TripSearchSettingsItem.item(for: .optimize)
        
        tripSettingsModel.isSubFilterValueChanged = false
    }
    
    /// Save selected
    /// Saves selected.
    func saveSelected() {
        guard let selected = pubItems.first(where: { $0.isSelected }) else {
            return
        }
        
        var valueList = [String]()
        
        switch selected.settings {
        case .walkMax: SearchManager.shared.userCriterias.maximumWalk = selected.item
            TripPlanningManager.shared.selectedCriterias.maximumWalk = selected.item
            SearchManager.shared.userCriterias.maximumWalk = selected.item
            valueList =  FeatureConfig.shared.availableCriterias.maximumWalk
            
        case .walkSpeed: SearchManager.shared.userCriterias.walkSpeed = Int(selected.item) ?? FeatureConfig.shared.defaultCriterias.walkSpeed
            TripPlanningManager.shared.selectedCriterias.walkSpeed = Int(selected.item) ?? FeatureConfig.shared.defaultCriterias.walkSpeed
			SearchManager.shared.userCriterias.walkSpeed = TripPlanningManager.shared.selectedCriterias.walkSpeed
            /// Initializes a new instance.
            valueList =  FeatureConfig.shared.availableCriterias.walkSpeed.flatMap { $0.keys.map(String.init) }
        case .optimize: SearchManager.shared.userCriterias.optimize = selected.item
            TripPlanningManager.shared.selectedCriterias.optimize = selected.item
            SearchManager.shared.userCriterias.optimize = selected.item
            valueList =  FeatureConfig.shared.availableCriterias.optimize
        }
        
        self.item = TripSearchSettingsItem(item: selected.settings,
                                           defaultValue: selected.item,
                                           allValues: valueList)
        
        switch selected.settings {
        case .walkMax:
            tripSettingsModel.pubWalkMax = self.item
            isMaxWlakChanged = selected.item == "3/4" ? false : true
            break
        case .walkSpeed:
            tripSettingsModel.pubWalkSpeed = self.item
            isWlakSpeedChanged = selected.item == "3" ? false : true
            break
        case .optimize:
            tripSettingsModel.pubOptimized = self.item
            isOptimizeForChanged = selected.item == "Speed" ? false : true
            break
        }
        
        tripSettingsModel.isSubFilterValueChanged = isMaxWlakChanged || isWlakSpeedChanged || isOptimizeForChanged ? true : false
        
    }
}

struct PickerListView: View {
    @ObservedObject var model = PickerListViewModel.shared
    
    var cancelAction: (() -> Void)? = nil
    var doneAction: (() -> Void)? = nil
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            ToolBarView(title: PickerListViewModel.shared.item.titleText.localized(), cancelAction: cancelAction, doneAction: {
                model.saveSelected()
                doneAction?()
            })
            ScrollView {
                VStack {
                    ForEach(model.pubItems.indices, id: \.self) { index in
                        itemView(for: index)
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    /// Item view.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: some View
    private func itemView(for index: Int) -> some View {
        Button(action: {
            model.didSelectItemAtIndex(index)
        }) {
            VStack {
                HStack(alignment: .center)  {
                    ZStack {
                        TextLabel(textForItemAtIndex(index))
                            .foregroundColor(Color.black)
                            .font(.body)
                        if model.pubItems[index].isSelected {
                            HStack {
                                Spacer()
                                Image("checkmark_blue_icon")
                                    .resizable()
                                    .padding(.horizontal, 5)
                                    .frame(width: 40, height: 30)
                            }
                            
                        }
                    }
                }.padding(.bottom, 10)
                Divider()
            }
        }.frame(height: 48)
    }
    
    /// Text for item at index.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    private func textForItemAtIndex(_ index: Int) -> String {
        let string =  "\(model.pubItems[index].item)"
        switch model.item.item {
        case .walkMax: return string.maxWalkDisplayString
        case .walkSpeed: return string.walkSpeedDisplayString
        case .optimize: return string
        }
    }
}

struct PickerListViewAODA: View {
    @ObservedObject var model = PickerListViewModel.shared
    
    var cancelAction: (() -> Void)? = nil
    var doneAction: (() -> Void)? = nil
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            TextLabel(model.item.titleText, .bold)
            Button(action: {
                cancelAction?()
            }, label: {
                HStack(spacing: 10){
                    Image("ic_leftarrow")
                        .renderingMode(.template)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30, alignment: .center)
                        .foregroundColor(.white)
                    TextLabel("Back").foregroundColor(Color.white)
                    Spacer()
                }
                .padding()
                .background(Color.java_main)
                .cornerRadius(10)
            })
            .padding(.horizontal)
            ScrollView {
                VStack {
                    ForEach(model.pubItems.indices, id: \.self) { index in
                        itemViewAODA(for: index)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
        .background(Color.white)
    }
    
    /// Item view a o d a.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: some View
    private func itemViewAODA(for index: Int) -> some View {
        Button(action: {
            model.didSelectItemAtIndex(index)
            model.saveSelected()
            doneAction?()
        }) {
            VStack {
                HStack(alignment: .center)  {
                    Spacer()
                    TextLabel(textForItemAtIndex(index))
                        .foregroundColor(Color.black)
                        .font(.body)
                    Spacer()
                }
                .padding()
                .background(model.pubItems[index].isSelected ? Color.java_main : Color.white)
                .cornerRadius(10)
                .roundedBorderWithColor(10, 0, Color.java_main)
                
            }
        }
    }
    
    /// Text for item at index.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    private func textForItemAtIndex(_ index: Int) -> String {
        let string =  "\(model.pubItems[index].item)"
        switch model.item.item {
        case .walkMax: return string.maxWalkDisplayString
        case .walkSpeed: return string.walkSpeedDisplayString
        case .optimize: return string
        }
    }
}
