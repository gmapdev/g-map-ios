//
//  RouteFilterPickerListView.swift
//

import Foundation
import SwiftUI

struct RouteFilterPickerListItem: Identifiable {
    var id: UUID = UUID()
    let item: String
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

struct RouteFilterPickerListView: View {
    @ObservedObject var model = RouteFilterPickerListViewModel.shared
    
    var cancelAction: (() -> Void)? = nil
    var doneAction: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                ToolBarViewAODA(title: RouteFilterPickerListViewModel.shared.filterType.rawValue.localized(), cancelAction: cancelAction, doneAction: {
                    model.saveSelected()
                    doneAction?()
                })
            } else {
                ToolBarView(title: RouteFilterPickerListViewModel.shared.filterType.rawValue.localized(), cancelAction: cancelAction, doneAction: {
                    model.saveSelected()
                    doneAction?()
                })
            }
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
                    if model.pubItems[index].isSelected {
                        Spacer()
                        Spacer().frame(width: 40)
                    }
                    TextLabel(model.pubItems[index].item.mapModeNameAliase().localized())
                        .foregroundColor(Color.black)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.pubItems[index].isSelected {
                        Spacer()
                        Image("checkmark_blue_icon")
                            .resizable()
                            .padding(.horizontal, 5)
                            .frame(width: 40, height: 30)
                    }
                }.padding(.bottom, 10)
                Divider()
            }
        }.frame(minHeight: 48)
            .addAccessibility(text: "%1".localized(model.pubItems[index].item.mapModeNameAliase()) + (model.pubItems[index].isSelected ? ", Is selected".localized() : ", Double tap to select".localized()))
    }
}


enum RouteFilterType: String {
    case agency = "Agencies"
    case mode = "Modes"
}

final class RouteFilterPickerListViewModel: ObservableObject {
    @Published var pubItems = [RouteFilterPickerListItem]()
    @Published var pubSelectedAgency = "All Agencies".localized()
    @Published var pubSelectedMode = "All Modes".localized()
    @Published var pubIsPresentPicker = false
    @Published var pubIsAgencyValueChanged = false
    @Published var pubIsModeValueChanged = false
    
    var filterType = RouteFilterType.agency
    var isAgencyChanged: Bool = false
    var isModeChanged: Bool = false
    
    
    /// Shared.
    /// - Parameters:
    ///   - RouteFilterPickerListViewModel: Parameter description
    static var shared: RouteFilterPickerListViewModel = {
        let mgr = RouteFilterPickerListViewModel()
        return mgr
    }()
    
    /// Prepare items.
    /// - Parameters:
    ///   - items: Parameter description
    func prepareItems(items: [String]){
        var routeFilterItem = [RouteFilterPickerListItem]();
        for item in items {
            routeFilterItem.append(RouteFilterPickerListItem(item: item, isSelected: item == self.pubSelectedAgency || item == self.pubSelectedMode))
        }
        
        DispatchQueue.main.async {
            self.pubItems = routeFilterItem
        }
    }
    
    /// Did select item at index.
    /// - Parameters:
    ///   - _: Parameter description
    /// Handles when did select item at index.
    func didSelectItemAtIndex(_ index: Int) {
        var newItems = [RouteFilterPickerListItem]()
        pubItems.forEach { item in
            var newItem = item
            newItem.isSelected = false
            newItems.append(newItem)
        }
        pubItems = newItems
        pubItems[index].isSelected.toggle()
    }
    
    /// Save selected
    /// Saves selected.
    func saveSelected() {
        guard let selected = pubItems.first(where: { $0.isSelected }) else {
            return
        }
        
        if filterType == .agency{
            self.pubSelectedAgency = selected.item
            let mode = self.pubSelectedMode
            let modesForAgency = RouteViewerModel.shared.modesFor(agency: self.pubSelectedAgency)
            // MARK: Hardcoded condition needs to adjust later
            if pubSelectedAgency == "Kitsap Transit".localized() && pubSelectedMode == "Ferry".localized(){
                pubSelectedMode = "Ferry".localized()
            }
            else if !modesForAgency.contains(mode){
                self.pubSelectedMode = "All Modes".localized()
            }
        }else{
            self.pubSelectedMode = selected.item
        }
        isModeChanged = self.pubSelectedMode == "All Modes".localized() ? false : true
        isAgencyChanged = self.pubSelectedAgency == "All Agencies".localized() ? false : true
        self.pubIsAgencyValueChanged = isAgencyChanged ? true : false
        self.pubIsModeValueChanged = isModeChanged ? true : false
    }
    
    /// Reset filter
    /// Resets filter.
    func resetFilter(){
        pubSelectedAgency = "All Agencies".localized()
        pubSelectedMode = "All Modes".localized()
        pubIsAgencyValueChanged = false
        pubIsModeValueChanged = false
        RouteViewerModel.shared.pubRouteItems = RouteViewerModel.shared.filteredRouteItems
    }
}

