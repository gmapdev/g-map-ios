//
//  SearchLocationView.swift
//

import SwiftUI

struct SearchLocationView: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var viewModel = SearchLocationViewModel.shared
    
    let title: String
    var action: ((Autocomplete.Feature) -> Void)?
    let icon: String
    
    /// Initializes a new instance.
    init(title: String,
         viewModel: SearchLocationViewModel = SearchLocationViewModel.shared,
         icon: String,
         action: ((Autocomplete.Feature) -> Void)? = nil) {
        self.title = title
        self.viewModel = viewModel
        self.action = action
        self.icon = icon
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if #available(iOS 14.0, *) {
            ZStack(alignment: .topTrailing) {
                VStack {
                    searchTextField
                    searchListView
                        .roundedBorder(10,0)
                    Spacer()
                }
            }.navigationBarTitle(title, displayMode: .inline)
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// Search text field.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchTextField: some View {
        VStack {
            LocationTextField(placeholder: "Enter location".localized(),
                              lineColor: Color.black,
                              imageName: "ic_location",
                              leadingPadding: 0, text: $viewModel.searchText)
                
                .frame(minHeight: 50)
                .roundedBorder(10,0)
                .addAccessibility(text: AvailableAccessibilityItem.enterLocationTextfield.rawValue.localized())
        }
    }
    
    /// Search list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var searchListView: some View {
        ScrollView {
            VStack (alignment: .leading) {
                Spacer().frame(height: 10)
                ForEach(viewModel.locations) { location in
                    item(by: location)
                        .padding(.horizontal, 22)
                }
                if !viewModel.recentLocations.isEmpty {
                    recentListView
                }
                currentLocationView()
                    .padding(.horizontal, 22)
            }
            .background(Color.white)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 5)
    }
    
    /// Recent list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var recentListView: some View {
        VStack {
            HStack {
                TextLabel("Recently Searched".localized(), .bold, .body)
                    .foregroundColor(Color.text_header)
                    .accessibilityAddTraits(.isHeader)
                    .lineLimit(3)
                Spacer()
            }
            .frame(alignment: .leading)
            ForEach(viewModel.recentLocations) { location in
                item(by: location, isRecent: true)
            }
        }
        .padding(.horizontal, 22)
        .background(Color.white)
    }
    
    /// Item.
    private func item(by location: SearchLocationItem,
                      isRecent: Bool = false) -> SearchItemView {
        let imageName =  isRecent ? "search_icon" : "location_pin_icon"
        let (titleText, subtitleTexts) = Helper.shared.getFormattedPlaceText(feature: location.feature)
        var itemView = SearchItemView(imageName: imageName,
                                      titleText: titleText, subTexts: subtitleTexts)
        itemView.action = {
            viewModel.saveFeature(location.feature, isRecent: isRecent)
            action?(location.feature)
            viewModel.searchText = ""
            presentation.wrappedValue.dismiss()
        }
        return itemView
    }
    
    /// Current location view
    /// - Returns: SearchItemView
    /// Current location view.
    private func currentLocationView() -> SearchItemView {
        var itemView = SearchItemView(imageName: "map_location_move_icon",
                                      titleText: "Current location".localized(), subTexts: [])
        itemView.action = {
            if let userLocation = MapManager.shared.mapView.userLocation {
                let from = userLocation.coordinate
                MapManager.shared.reverseLocation(latitude: from.latitude, longitude: from.longitude, completion: { autoComplete in
                    if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                        if let feature = autocomplete.features.first {
                            DispatchQueue.main.async {
                                self.action?(feature)
                                viewModel.searchText = ""
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
        var itemView = MyLocationItemView(imageName: "ic_home", text: "Home".localized(), addressLine: location.address)
        if location.type == "work"{
            let newItemView = MyLocationItemView(imageName: "ic_work", text: "Work".localized(), addressLine: location.address)
            itemView = newItemView
        }
        if location.type == "custom"{
            let newItemView = MyLocationItemView(imageName: "ic_location", text: location.name, addressLine: location.address)
            itemView = newItemView
        }
        itemView.action = {
            MapManager.shared.reverseLocation(latitude: location.lat, longitude: location.lon, completion: { autoComplete in
                if let autocomplete = autoComplete, autocomplete.features.count > 0 {
                    if let feature = autocomplete.features.first {
                        DispatchQueue.main.async {
                            self.action?(feature)
                            viewModel.searchText = ""
                            presentation.wrappedValue.dismiss()
                        }
                    }
                }
            })
        }
        return itemView
    }
    
}

struct SearchItemView: View {
    let imageName: String
    let titleText: String
    let subTexts: [String]
    var action: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack {
            Button(action: {
                action?()
            }) {
                HStack(alignment: .top){
                    VStack{
                        Image(imageName)
                            .resizable()
                            .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2 : 15, height: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2 : 15, alignment: .bottomLeading)
                            .padding(.top, 5)
                        Spacer()
                    }
                    VStack(alignment: .leading){
                        TextLabel(titleText, .regular, .body)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Color.black)
                        
                        ForEach(subTexts, id: \.self) { item in
                            TextLabel(item, .regular, .subheadline)
                                .foregroundStyle(Color.gray)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(Color.black)
                        }
                    }
                    Spacer()
                }
                            
            }
        }
        .padding(.horizontal, 0)
        .onTapGesture {
            action?()
        }
    }
}

struct MyLocationItemView: View {
    let imageName: String
    let text: String
    let addressLine: String
    var action: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack {
            Button(action: {
                action?()
            }) {
                HStack(spacing: 20){
                    Image(imageName)
                        .resizable().renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .accentColor(.black)
                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2 : 30, height: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() / 2 : 30, alignment: .center)
                    VStack(alignment: .leading){
                        TextLabel(text.localized())
                            .foregroundColor(Color.black)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        TextLabel(addressLine)
                            .foregroundColor(Color.gray_subtitle_color)
                            .font(.subheadline)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 0)
        .onTapGesture {
            action?()
        }
    }
}

struct SearchLocationView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        SearchLocationView(title: "SET DESTINATION", icon: "")
    }
}
