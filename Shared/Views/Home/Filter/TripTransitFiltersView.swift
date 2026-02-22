//
//  TripTransitFiltersView.swift
//

import SwiftUI

final class TripTransitFiltersViewModel: ObservableObject {
	
    @Published var items: [SearchMode]
    @Published var subitems: [SearchMode]
    
    /// Shared.
    /// - Parameters:
    ///   - TripTransitFiltersViewModel: Parameter description
    public static var shared: TripTransitFiltersViewModel = {
        let model = TripTransitFiltersViewModel()
        return model
    }()
    
    /// Initializes a new instance.
    init() {
		self.items = FeatureConfig.shared.searchModes
        self.subitems = FeatureConfig.shared.searchModes.count > 0 ? FeatureConfig.shared.searchModes[0].selectedSubModes ?? [] : []
    }
    
    /// Get rows
    /// - Returns: (Int, [GridItem])
    /// Retrieves rows.
    func getRows() -> (Int, [GridItem]) {
        let rowsCount = Double(Double(subitems.count) / 3)
        let intCount = Int(ceil(rowsCount))
        var rows: [GridItem] = []
        
        for _ in 0..<intCount{
            rows.append(GridItem(.flexible()))
        }
        return (Int(rowsCount),rows)
    }
    
    /// Get view height
    /// - Returns: CGFloat
    /// Retrieves view height.
    func getViewHeight() -> CGFloat{
        let rowsCount = Double(Double(subitems.count) / 3)
        let intCount = Int(ceil(rowsCount))
        
        return CGFloat(120 * intCount)
    }
}

struct TripTransitFiltersView: View {
    @ObservedObject var model = TripTransitFiltersViewModel.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        
        let (rowsCount, _) = model.getRows()
       return  GeometryReader { geo in
           HStack(alignment: .top, spacing: 0) {
               VFlow(alignment: .leading, spacing: 13){
                    ForEach(model.subitems.indices, id: \.self) { index in
                        SubFiltersView(subitem: self.model.subitems[index], isSelected: self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}), index: index, action: { idx in
                            if self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}) {
                                self.tripPlanManager.pubSubModeFilterCollection.removeAll(where: { $0 == model.subitems[idx] })
                            } else {
                                self.tripPlanManager.pubSubModeFilterCollection.append(model.subitems[idx])
                            }
                            Helper.shared.saveUserPreferredSettings()
                        }, width: (geo.size.width - 90) / CGFloat(model.subitems.count / rowsCount))
                        .padding(.vertical, 6)
                        .addAccessibility(text: "%1 toggle button is %2".localized(self.model.subitems[index].mode,(self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}) ? "On".localized(): "Off".localized())))
                    }
                }
                .padding(.vertical, 10)
                
            }
            .background(Color.white)
        }
    }
    
    
}

struct TripTransitFiltersViewAODA: View {
    @ObservedObject var model = TripTransitFiltersViewModel.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            ForEach(model.subitems.indices, id: \.self) { index in
                SubFiltersViewAODA(subitem: model.subitems[index], isSelected: self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}), index: index, action: { idx in
                    if self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}) {
                        self.tripPlanManager.pubSubModeFilterCollection.removeAll(where: { $0 == model.subitems[idx] })
                    } else {
                        self.tripPlanManager.pubSubModeFilterCollection.append(model.subitems[idx])
                    }
                })
                .addAccessibility(text: "%1 toggle button is %2".localized(self.model.subitems[index].mode,(self.tripPlanManager.pubSubModeFilterCollection.contains(where: {$0 == model.subitems[index]}) ? "On".localized(): "Off".localized())))
            }
        }
    }
}



