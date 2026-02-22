//
//  TripFiltersView.swift
//

import SwiftUI


final class TripFiltersModel: ObservableObject {
    
 /// Items.
 /// - Parameters:
 ///   - [SearchMode]: Parameter description
	@Published var items: [SearchMode] {
        didSet {
            updateTripSettings()
        }
    }
	
    @Published var topItems: [SearchMode]
    
    /// Initializes a new instance.
    init() {
		let filters: [SearchMode] = FeatureConfig.shared.searchModes.map({
            for filter in SearchManager.shared.selectedModes {
				if $0 == filter {
					var newSearchMode = $0
					newSearchMode.isSelected = true
					return newSearchMode
				}
			}
			var newSearchMode = $0
			newSearchMode.isSelected = false
			return newSearchMode
		})
        self.items = filters
        let topFilters = FeatureConfig.shared.searchModes
        self.topItems = topFilters
    }
}

struct TripFiltersView: View {
    @ObservedObject var model = TripFiltersModel()
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        contentView()
    }
    
    /// Content view
    /// - Returns: some View
    /// Content view.
    func contentView() -> some View {
        ZStack(alignment: .center){
            VStack{
                HStack{
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            .background(Color.black.opacity(0.6))
            .zIndex(9990)
            .accessibilityAddTraits(.isButton)
            .addAccessibility(text: AvailableAccessibilityItem.blackAreaFliter.rawValue.localized())
            .accessibilityAction {
                MapFromToViewModel.shared.pubIsTripFiltersViewExpanded.toggle()
            }
            .onTapGesture {
                MapFromToViewModel.shared.pubIsTripFiltersViewExpanded.toggle()
            }
            VStack {
                Spacer().frame(height: ScreenSize.safeTop())
                HStack {
                    Spacer()
                    Button(action: {
                        MapFromToViewModel.shared.pubIsTripFiltersViewExpanded = false
                    }, label: {
                        Image("cancel_icon")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: 22, height: 22)
                    })
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .addAccessibility(text: "Close button, Double tap to activate".localized())
                    Spacer().frame(width: 20)
                }
                Spacer()
            }.zIndex(9998)
            VStack {
                LazyVGrid(columns: columns, spacing: 20){
                    ForEach(model.topItems.indices, id: \.self){ index in
                        FilterButtonView(width: (ScreenSize.width()-130)/3, data: model.topItems[index], isSelected: self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == model.topItems[index]}), action:{
                            if self.tripPlanManager.pubModeFilterCollection.contains(where: { $0 == model.topItems[index]}) {
                                self.tripPlanManager.pubModeFilterCollection.removeAll(where: { $0 == model.topItems[index] })
                            } else {
                                self.tripPlanManager.pubModeFilterCollection.append(model.topItems[index])
                            }
                            tripPlanManager.updateSubFilter()
                        })
                        .accessibilityAddTraits(.isButton)
                    }
                }.padding()
            }
            .background(Color.white)
            .foregroundColor(Color.primary)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
            .zIndex(9999)
        }
        
    }
}

struct FilterButtonView: View{
    let width: CGFloat
    let data: SearchMode
    var isSelected = false
    var action: (() -> Void)? = nil

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        Button(action: {
            action?()
        }, label: {
            VStack(spacing: 0){
                ZStack{
                    if isSelected{
                        Circle()
                            .fill(Color.white)
                            .frame(width: width - 10)
                    }
                    VStack{
                        Spacer().frame(height: 10)
                        Image(data.mode_image)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width - 60, height: width - 60)
                        Spacer().frame(height: 1)
                        TextLabel(data.label.localized(), .bold , .subheadline)
                        Spacer().frame(height: 10)
                    }
                }
            }
            .frame(width: width, height: width)
            .background(isSelected ? Color.java_main : Color.clear)
            .foregroundColor(Color.black)
            .cornerRadius(5)
            .roundedBorderWithColor(5, 0, Color.java_main,2)
        }).addAccessibility(text: isSelected ? "%1 mode on, double tap to turn off".localized(data.label) : "%1 mode off, double tap to turn on".localized(data.label) )
    }
}

struct FilterButtonViewV2: View{
    let width: CGFloat
    let data: SearchMode
    var isSelected = false
    var action: (() -> Void)? = nil

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View{
        Button(action: {
            action?()
        }, label: {
            VStack(spacing: 0){
                ZStack{
                    if isSelected{
                        Circle()
                            .fill(Color.white)
                            .frame(width: width - 10)
                    }
                    VStack{
                        Spacer().frame(height: 10)
                        Image(data.mode_image)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width/2, height: width/2)
                        Spacer().frame(height: 10)
                    }
                }
            }
            .frame(width: width, height: width)
            .background(isSelected ? Color.java_main : Color.clear)
            .foregroundColor(Color.black)
            .cornerRadius(5)
            .roundedBorderWithColor(5, 0, Color.java_main,2)
        }).addAccessibility(text: isSelected ? "%1 mode on, double tap to turn off".localized(data.label) : "%1 mode off, double tap to turn on".localized(data.label) )
    }
}

extension TripFiltersModel {
    /// Update trip settings
    /// Updates trip settings.
    func updateTripSettings() {
		let selectedFilters = items.filter({ $0.isSelected ?? false })
        var updatedFilters: [SearchMode] = []
		for filter in FeatureConfig.shared.searchModes {
			if selectedFilters.contains(where: { filter == $0 }) {
                updatedFilters.append(filter)
            }
        }
		SearchManager.shared.selectedModes = updatedFilters
    }
}



