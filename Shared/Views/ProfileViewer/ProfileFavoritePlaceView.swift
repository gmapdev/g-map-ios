//
//  ProfileFavoritePlaceView.swift
//

import Foundation
import SwiftUI
import Combine

enum ProfileFavoritePlaceState: String {
    case editHome
    case editWork
    case addNewPlace
    case editPlace
    case view
}

struct ProfileFavoritePlaceView: View {
    @ObservedObject var profileManager = ProfileManager.shared
    @State var generalPlacesList = AppSession.shared.loginInfo?.savedLocations
    @State var showHomeSearchLocationView = false
    @State var showWorkSearchLocationView = false
    @State var homeAddress = "Set your home address".localized()
    @State var workAddress = "Set your work address".localized()
    @State var hasHomeAddress = false
    @State var hasWorkAddress = false
    @State var selectedAddress = ""
    @State var selectedPlaceName = ""
    @State var placeId : UUID = UUID()
    @State var action: ((Bool) -> Void)? = nil
    
    @Inject var userAccountProvider: UserAccountProvider
    
    var title = "Add your locations".localized()
    var spacing: CGFloat = 50
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if profileManager.pubViewState == .view{
            VStack{
                Spacer().frame(height:spacing)
                VStack(spacing:20){
                    HStack{
                        TextLabel(title.localized(), .bold, .title2).foregroundColor(Color.black)
                        Spacer()
                    }
                    HStack{
                        TextLabel("Add the places you frequent often to save time planning trips:".localized(), .bold, .subheadline).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    HStack{
                        HStack{
                            Button(action: {
                                profileManager.pubViewState = .editHome
                                selectedAddress = homeAddress
                                action?(false)
                            }, label: {
                                VStack{
                                    Spacer()
                                    Image("ic_home").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30)
                                    Spacer()
                                }.padding(.leading, 10)
                                
                                VStack(alignment: HorizontalAlignment.leading){
                                    TextLabel("Home".localized()).lineLimit(nil).font(.title3).foregroundColor(Color.black)
                                    TextLabel("\(homeAddress)".localized()).font(.caption).lineLimit(nil).foregroundColor(Color.black).multilineTextAlignment(.leading)
                                }
                                Spacer()
                            })
                        }
                        .frame(minHeight:60)
                        .roundedBorder(10, 0)
                        .accessibilityElement(children: .combine)
                        .addAccessibility(text: homeAddress == "Set your home address" ? "Set your home address button, double tap to %1".localized(homeAddress) : "Home address, %1".localized(homeAddress))
                        
                        if hasHomeAddress{
                            Spacer()
                            Button(action: {
                                removeAddress(state: .editHome)
                                hasHomeAddress = false
                                homeAddress = "Set your home address".localized()
                            }, label: {
                                ZStack{
                                    Image("ic_delete").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).accentColor(.black).frame(width: 30, height: 30).zIndex(9)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.77)
                                        .frame(width: 60, alignment: .center)
                                        .alignmentGuide(.leading) { dimensions in
                                            dimensions[HorizontalAlignment.trailing]
                                        }
                                        .zIndex(1)
                                }
                            })
                            .accessibilityElement(children: .combine)
                            .addAccessibility(text: "Delete your home address button, double tap to delete %1".localized(homeAddress))
                        }
                    }
                    
                    HStack{
                        HStack{
                                Button(action:{
                                    profileManager.pubViewState = .editWork
                                    selectedAddress = workAddress
                                    action?(false)
                                }, label:{
                                    VStack{
                                        Spacer()
                                        Image("ic_work").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30)
                                        Spacer()
                                    }.padding(.leading, 10)
                                    
                                    VStack(alignment: HorizontalAlignment.leading){
                                        TextLabel("Work".localized()).lineLimit(nil).font(.title3).foregroundColor(Color.black)
                                        TextLabel("\(workAddress)".localized()).font(.caption).lineLimit(nil).foregroundColor(Color.black).multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                })
                            }
                            .frame(minHeight:60)
                            .roundedBorder(10, 0)
                            .accessibilityElement(children: .combine)
                            .addAccessibility(text: workAddress == "Set your work address" ? "Set your work address button, double tap to %1 ".localized(workAddress) : "Work address, %1".localized(workAddress))
                        
                        if hasWorkAddress{
                            Spacer()
                            Button(action: {
                                removeAddress(state: .editWork)
                                hasWorkAddress = false
                                workAddress = "Set your work address".localized()
                            }, label: {
                                ZStack{
                                    Image("ic_delete").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).accentColor(.black).frame(width: 30, height: 30).zIndex(9)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 0.77)
                                        .frame(width: 60, alignment: .center)
                                        .alignmentGuide(.leading) { dimensions in
                                            dimensions[HorizontalAlignment.trailing]
                                        }
                                        .zIndex(1)
                                }
                            })
                            .accessibilityElement(children: .combine)
                            .addAccessibility(text: "Delete your work address button, double tap to delete %1".localized(workAddress))
                        }
                    }
                    if let savedLocations = self.generalPlacesList {
                        ForEach( 0..<savedLocations.count, id: \.self) { idx in
                            if savedLocations[idx].type == "custom" || savedLocations[idx].type == "dining"{
                                HStack{
                                    HStack{
                                        Button {
                                            profileManager.pubViewState = .editPlace
                                            selectedAddress = savedLocations[idx].address
                                            selectedPlaceName = savedLocations[idx].name
                                            placeId = savedLocations[idx].id
                                            action?(false)
                                        } label: {
                                        VStack{
                                            Spacer()
                                            Image(savedLocations[idx].type == "dining" ? "ic_dinein" : "ic_location").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).accentColor(.black).frame(width: 30, height: 30)
                                            Spacer()
                                        }.padding(.leading, 10)
                                        
                                            VStack(alignment: HorizontalAlignment.leading){
                                                TextLabel("\(savedLocations[idx].name)").lineLimit(nil).font(.title3).foregroundColor(Color.black)
                                                    .multilineTextAlignment(.leading)
                                                TextLabel("\(savedLocations[idx].address)").font(.caption).lineLimit(nil).foregroundColor(Color.black)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }

                                        
                                        Spacer()
                                    }
                                    .frame(minHeight:60)
                                    .roundedBorder(10, 0)
                                    .accessibilityElement(children: .combine)
                                    .addAccessibility(text: "Saved address: %1, address is: %2".localized(savedLocations[idx].name, savedLocations[idx].address))
                                    
                                    Spacer()
                                    Button(action: {
                                        self.generalPlacesList?.remove(at: idx)
                                        AppSession.shared.loginInfo?.savedLocations = self.generalPlacesList
                                    }, label: {
                                        ZStack{
                                            Image("ic_delete").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).accentColor(.black).frame(width: 30, height: 30).zIndex(9)
                                            
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.gray, lineWidth: 0.77)
                                                .frame(width: 60, alignment: .center)
                                                .alignmentGuide(.leading) { dimensions in
                                                    dimensions[HorizontalAlignment.trailing]
                                                }
                                                .zIndex(1)
                                        }
                                    })
                                    .accessibilityElement(children: .combine)
                                    .addAccessibility(text: "Delete Saved Address, double tap to delete %1".localized(savedLocations[idx].name))
                                }
                            }
                        }
                    }
                    
                    Button(action:{
                        profileManager.pubViewState = .addNewPlace
                        selectedAddress = ""
                        selectedPlaceName = ""
                        action?(false)
                    },label:{
                        HStack{
                            VStack{
                                Spacer()
                                Image("ic_add").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: 30, height: 30).foregroundColor(Color.black)
                                Spacer()
                            }.padding(.leading, 10)
                            
                            VStack(alignment: HorizontalAlignment.leading){
                                TextLabel("Add another place".localized()).font(.title3).lineLimit(nil).foregroundColor(Color.black).multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .frame(minHeight:60)
                        .roundedBorder(10, 0)
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.AddAnotherPlaceButton.rawValue.localized())
                    Spacer()
                }
                Spacer()
            }
            .onAppear{
                self.generalPlacesList = AppSession.shared.loginInfo?.savedLocations
                self.setInitialName()
            }
            .padding(.horizontal)
        }
        else{
            ProfileAutoCompleteAddressArea(placeId: placeId, newPlaceName: $selectedPlaceName, searchedPlaceText: $selectedAddress,state: $profileManager.pubViewState, generalPlaceList: self.$generalPlacesList, action:{ value in
                action?(value)
            })
        }
    }
    
    /// Initializes a new instance.

    /// Set initial name

    /// Sets initial name.
    func setInitialName(){
        generalPlacesList?.forEach({ location in
            if location.type == "home"{
                self.homeAddress = location.address
                self.hasHomeAddress = true
                
            }
            else if location.type == "work"{
                self.workAddress = location.address
                self.hasWorkAddress = true
            }
        })
    }
    
    /// Remove address.
    /// - Parameters:
    ///   - state: Parameter description
    /// Removes address.
    func removeAddress(state: ProfileFavoritePlaceState){
        var locationIndex:Int = -1
        if state == .editHome{
            for index in 0..<(generalPlacesList?.count)!{
                    if generalPlacesList?[index].type == "home"{
                        locationIndex = index
                        break
                    }
                }
        }
        
        if state == .editWork{
            for index in 0..<(AppSession.shared.loginInfo?.savedLocations!.count)!{
                    if generalPlacesList?[index].type == "work"{
                        locationIndex = index
                        break
                    }
                }
        }
        if locationIndex != -1{
            self.generalPlacesList?.remove(at: locationIndex)
            AppSession.shared.loginInfo?.savedLocations = self.generalPlacesList
            userAccountProvider.storeUserInfoToServer { success in }
        }
    }
}

// MARK: ProfileAutoCompleteAddressArea

struct ProfileAutoCompleteAddressArea: View {
    @ObservedObject var profileManager = ProfileManager.shared
    
    @State var placeId : UUID
    @Binding var newPlaceName : String
    @Binding var searchedPlaceText : String
    @State var isExpanded = false
    @State var type = ""
    @State var icon = ""
    @Binding var state: ProfileFavoritePlaceState
    @State var lat:Double = 0
    @State var lon:Double = 0
    @Binding var generalPlaceList: [FavouriteLocation]?
    @State var locationIndex = -1
    @State var isSearching = false
    @State var isEmptyAddress = false
    @State var isEmptyPlace = false
    
    @Inject var userAccountProvider: UserAccountProvider
    
    var actionFrom: ((Autocomplete.Feature) -> Void)? = nil
    @State var action: ((Bool) -> Void)? = nil
    
    @State private var keyboardHeight: CGFloat = 0

        /// Keyboard height publisher.
        /// - Parameters:
        ///   - AnyPublisher<CGFloat: Parameter description
        ///   - Never>: Parameter description
        private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
            Publishers.Merge(
                NotificationCenter.default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                    .map { $0.cgRectValue.height },
                NotificationCenter.default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in CGFloat(0) }
           ).eraseToAnyPublisher()
        }
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            VStack(spacing:0){
                if state == .addNewPlace{
                    HStack{
                        TextLabel("Add a new place".localized()).font(.title2).foregroundColor(Color.black)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    AutoHeightTextField(text: self.$newPlaceName, placeholder: "Set place name".localized(), keyboradType: .default)
                        .roundedBorder(10,0)
                    .padding(.bottom, 20)
                    .addAccessibility(text: AvailableAccessibilityItem.setPlaceNameTextField.rawValue.localized())
                    if isEmptyPlace{
                        TextLabel("Please enter a name for this place.".localized(), .semibold, .footnote).foregroundColor(Color.red).padding(.bottom, 30)
                    }
                }
                else if state == .editHome{
                    HStack{
                        TextLabel("Edit Home".localized()).font(.title2).foregroundColor(Color.black)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                else if state == .editWork{
                    HStack{
                        TextLabel("Edit Work".localized()).font(.title2).foregroundColor(Color.black)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }else if state == .editPlace{
                    HStack{
                        TextLabel("Edit Place".localized()).font(.title2).foregroundColor(Color.black)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    AutoHeightTextField(text: self.$newPlaceName, placeholder: "Set place name".localized(), keyboradType: .default)
                        .roundedBorder(10,0)
                    .padding(.bottom, 20)
                    .addAccessibility(text: AvailableAccessibilityItem.setPlaceNameTextField.rawValue.localized())
                    if isEmptyPlace{
                        TextLabel("Please enter a name for this place.".localized(), .semibold, .footnote).foregroundColor(Color.red).padding(.bottom, 30)
                    }
                }
                VStack{
                    if !ProfileManager.shared.pubShowSearchLocationView{
                        
                        AutoHeightTextField(text: self.$searchedPlaceText, placeholder: "Search for location".localized(), keyboradType: .default, minHeight: self.getHeight(text: searchedPlaceText), onTapTrigger:{
                            ProfileManager.shared.pubShowSearchLocationView.toggle()
                        })
                        .roundedBorder(10,0)
                        .addAccessibility(text: AvailableAccessibilityItem.searchForLocationTextField.rawValue.localized())
                        
                    }
                    else{
                        SearchLocationView(title: "Select from location".localized(),icon: "map_from_icon",action: { feature in
                            profileManager.pubShowSearchLocationView.toggle()
                            actionFrom?(feature)
                            let (placeText, subTitleTexts) = Helper.shared.getFormattedPlaceText(feature: feature)
                            searchedPlaceText = placeText
                            updateFromTo()
                            lat = feature.geometry?.coordinate?.latitude ?? 0
                            lon = feature.geometry?.coordinate?.longitude ?? 0
                            type = "custom"
                            icon = "map-marker"
                            if state == .editHome{
                                newPlaceName = "Home".localized()
                                type = "home"
                                icon = "home"
                            }
                            else if state == .editWork{
                                newPlaceName = "Work".localized()
                                type = "work"
                                icon = "briefcase"
                            }
                            profileManager.pubLastTripListUpdate = Date().timeIntervalSince1970
                        })
                        .frame(height: ScreenSize.height() - (keyboardHeight + (state == .addNewPlace ? 250 : 180)))
                    }
                }
                .padding(.bottom, 20)
                
                if isEmptyAddress{
                    TextLabel("Please set a location for this place".localized(), .semibold, .footnote).foregroundColor(Color.red).padding(.bottom, 30)
                }
                Spacer()
                
                HStack{
                    Spacer()
                    Button(action: {
                        self.state = .view
                        searchedPlaceText = ""
                        action?(true)
                    }, label: {
                        HStack{
                            TextLabel("Cancel".localized()).padding(10)
                                .font(.body)
                        }
                        /// Hex: "#eeeeee")
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - Color.init(hex: "#eeeeee"
                        .background(Color.init(hex: "#eeeeee"))
                        /// Corner radius: 10)
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - RoundedRectangle.init(cornerRadius: 10
                        .clipShape(RoundedRectangle.init(cornerRadius: 10))
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.cancelButton.rawValue)
                    Spacer()
                    Button(action: {
                        let favoriteLocation: FavouriteLocation = FavouriteLocation(address: searchedPlaceText, icon: icon, lat: lat, lon: lon, name: newPlaceName, type: type)
                        if state == .addNewPlace {
                            if newPlaceName.count > 0 && searchedPlaceText.count > 0 {
                                isEmptyPlace = false
                                isEmptyAddress = false
                                self.generalPlaceList?.append(favoriteLocation)
                                AppSession.shared.loginInfo?.savedLocations?.append(favoriteLocation)
                                self.state = .view
                                action?(true)
                            }
                            else{
                                isEmptyPlace = !(newPlaceName.count > 0)
                                isEmptyAddress = !(searchedPlaceText.count > 0)
                            }
                        }
                        else if state == .editHome{
                            if searchedPlaceText != "Set your home address" && searchedPlaceText.count > 0{
                                isEmptyAddress = false
                                if let count = self.generalPlaceList?.count{
                                    for index in 0..<count{
                                        if generalPlaceList?[index].type == "home"{
                                            self.locationIndex = index
                                            break
                                        }
                                    }
                                    if locationIndex != -1{
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].address = searchedPlaceText
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lat = lat
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lon = lon
                                    }
                                    else if locationIndex == -1{
                                        self.generalPlaceList?.append(favoriteLocation)
                                        AppSession.shared.loginInfo?.savedLocations?.append(favoriteLocation)
                                    }
                                    self.state = .view
                                    action?(true)
                                }
                            }
                            else{
                                isEmptyAddress = true
                            }
                        }
                        else if state == .editWork{
                            if searchedPlaceText != "Set your work address" && searchedPlaceText.count > 0 {
                                isEmptyAddress = false
                                if let count = AppSession.shared.loginInfo?.savedLocations?.count{
                                    for index in 0..<count{
                                        if AppSession.shared.loginInfo?.savedLocations?[index].type == "work"{
                                            self.locationIndex = index
                                            break
                                        }
                                    }
                                    if locationIndex != -1{
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].address = searchedPlaceText
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lat = lat
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lon = lon
                                    }
                                    else if locationIndex == -1 {
                                        self.generalPlaceList?.append(favoriteLocation)
                                        AppSession.shared.loginInfo?.savedLocations?.append(favoriteLocation)
                                    }
                                    self.state = .view
                                    action?(true)
                                }
                            }
                            else{
                                isEmptyAddress = true
                            }
                        }
                        else if state == .editPlace{
                            if newPlaceName.count > 0 && searchedPlaceText.count > 0 {
                                isEmptyPlace = false
                                isEmptyAddress = false
                                if let count = AppSession.shared.loginInfo?.savedLocations?.count{
                                    for index in 0..<count{
                                        if AppSession.shared.loginInfo?.savedLocations?[index].id == placeId{
                                            self.locationIndex = index
                                            break
                                        }
                                    }
                                    if locationIndex != -1{
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].name = newPlaceName
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].address = searchedPlaceText
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lat = lat
                                        AppSession.shared.loginInfo?.savedLocations?[locationIndex].lon = lon
                                    }
                                    self.state = .view
                                    action?(true)
                                }
                            }
                            else{
                                isEmptyPlace = !(newPlaceName.count > 0)
                                isEmptyAddress = !(searchedPlaceText.count > 0)
                            }
                        }
                    }, label: {
                        HStack{
                            TextLabel("Save".localized()).padding(10)
                                .font(.body)
                        }
                        .background(Color.main)
                        .foregroundColor(Color.white)
                        /// Corner radius: 10)
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - RoundedRectangle.init(cornerRadius: 10
                        .clipShape(RoundedRectangle.init(cornerRadius: 10))
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.saveButton.rawValue)
                    Spacer()
                }
            }
            .padding([.horizontal],20)
            .padding(.bottom, 0)
            .onReceive(keyboardHeightPublisher) { self.keyboardHeight = $0 }
        }
    }
    
    /// Update from to
    /// Updates from to.
    private func updateFromTo() {
        if !searchedPlaceText.isEmpty && !isExpanded {
            isExpanded.toggle()
        }
    }
    
    /// Get height.
    /// - Parameters:
    ///   - text: Parameter description
    /// - Returns: CGFloat
    func getHeight(text: String) -> CGFloat {
        let width = CGFloat(text.count * (AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 9))
        let maxWidth = (ScreenSize.width() - 80)
        let lines = width / maxWidth
        if lines < 0 {
            return 40
        } else {
            return (lines * 40)
        }
    }
}
