//
//  SearchViewerView.swift
//

import Foundation
import SwiftUI
import Combine
import UIKit


struct SearchViewerView: View {
	@ObservedObject var autoCompleteManager = AutoCompleteManager.shared
    @ObservedObject var routeViewer = RouteViewerModel.shared
    @ObservedObject var routeFilterPickerModel = RouteFilterPickerListViewModel.shared
	
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
        let sections = autoCompleteManager.pubFilteredItems
		let placeholder = autoCompleteManager.placeholder
		let imageName = autoCompleteManager.textImageName
		let binding = Binding<String>(get: {
			return autoCompleteManager.pubKeyword
		}, set: {
            autoCompleteManager.pubKeyword = $0
            // Excluding Route from the Search
            var filteredKeyword = autoCompleteManager.pubKeyword
            if $0.lowercased().contains("route"){
                filteredKeyword = $0.lowercased().replacingOccurrences(of: "route", with: "").trimmingCharacters(in: .whitespaces)
            }
			autoCompleteManager.loadSections(keywords: filteredKeyword)
		})
		return GeometryReader { geometry in
			ZStack(alignment: .topTrailing) {
				VStack {
					Spacer().frame(height:ScreenSize.safeTop())
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        topViewAODA
                    } else {
                        topView
                    }
					LocationTextField(placeholder: placeholder, lineColor: Color.black, imageName: imageName,
						colorImageWithMask:Color.black,
                                      leadingPadding: 0, imageOnTap: {
                    }, text: binding)
						.background(Color.white)
						.clipShape(RoundedCorner(radius: 10, corners: .allCorners))
						.padding(10)
						.shadow(radius: 5)
                        .addAccessibility(text: AvailableAccessibilityItem.searchRouteTextField.rawValue.localized())
					
					if sections.count > 0 {
						ScrollView(showsIndicators:false){
							ForEach(sections, id:\.sectionTitle) { section in
								AutoCompleteSectionView(section: section)
							}
						}
					}else{
						VStack{
							Spacer().frame(height:20)
							HStack{
								Spacer()
								TextLabel("Please type keyword in the text field \nabove to start search".localized()).multilineTextAlignment(.center)
                                    .font(.caption)
									.foregroundColor(Color.gray_subtitle_color)
								Spacer()
							}
							Spacer()
                        }.onAppear {
                            if autoCompleteManager.autoCompleteMode == .stopList{
                                if let login = AppSession.shared.loginInfo{
                                    autoCompleteManager.favoriteStopsListSection(login: login)
                                }
                            }
                        }
					}
				}
				.background(Color.white)
				.edgesIgnoringSafeArea(.bottom)
                
                if routeFilterPickerModel.pubIsPresentPicker{
                    ZStack{
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                            }
                        }
                        .background(Color.black).opacity(0.5)
                        .ignoresSafeArea(edges: .all)
                        .disabled(false)
                        .allowsHitTesting(true)
                        .onTapGesture {}
                        .onDrag({ NSItemProvider(object: "" as NSItemProviderWriting) })
                        .zIndex(998)
                        VStack{
                            Spacer()
                            VStack{
                                pickerListView.frame(height: AccessibilityManager.shared.pubIsLargeFontSize ? 350 : 250)
                                Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white).zIndex(999)
                            }
                            .edgesIgnoringSafeArea(.bottom).padding(.top, 10)
                            .background(Color.white).clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                            .transition(.scale)
                            .accessibilityAddTraits([.isModal])
                        }
                        .zIndex(999)
                    }
                    
                }
			}
		}
	}
    
    /// Top view.
    /// - Parameters:
    ///   - some: Parameter description
    var topView: some View {
        HStack(spacing: 0){
            Button(action: {
                autoCompleteManager.pubOpenPage = false
                autoCompleteManager.pubFilteredItems.removeAll()
                autoCompleteManager.pubKeyword = ""
                autoCompleteManager.pubFilterKeywordForRoute = ""
            }, label: {
                Image("ic_leftarrow")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundColor(Color.main)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25, alignment: .center)
                    .padding(.horizontal, 10)
            })
            .frame(width: 30, height: 30, alignment: .center)
            .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
            Spacer()
            Button(action: {
                UIApplication.shared.dismissKeyboard()
                let agencies = RouteViewerModel.shared.agencies
                routeFilterPickerModel.filterType = .agency
                routeFilterPickerModel.prepareItems(items: agencies)
                routeFilterPickerModel.pubIsPresentPicker = true
            }, label: {
                ZStack{
                    HStack{
                        TextLabel(routeFilterPickerModel.pubSelectedAgency)
                            .foregroundColor(Color.black)
                            .font(.subheadline)
                        Spacer()
                        Image("ic_down")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.black)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                    }
                    .padding(5)
                    .cornerRadius(5)
                    .frame(width: (ScreenSize.width()/2)-35, height: 30)
                    .background(Color.shadow)
                    .cornerRadius(5)
                    if routeFilterPickerModel.pubIsAgencyValueChanged {
                        HStack{
                            Spacer()
                            Circle().fill(Color.green).frame(width: 8, height: 8, alignment: .center)
                                .offset(x: -1, y: -13)
                        }
                    }else{
                        HStack{
                            Spacer()
                            Spacer().frame(width: 8)
                        }
                    }
                }
            })
            
            .addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedAgency) + ",Double Tap to Change Agency")
            Button(action: {
                UIApplication.shared.dismissKeyboard()
                let agency = routeFilterPickerModel.pubSelectedAgency
                let modes = RouteViewerModel.shared.modesFor(agency: agency)
                routeFilterPickerModel.filterType = .mode
                routeFilterPickerModel.prepareItems(items: modes)
                routeFilterPickerModel.pubIsPresentPicker = true
            }, label: {
                ZStack{
                    HStack{
                        TextLabel(routeFilterPickerModel.pubSelectedMode.mapModeNameAliase())
                            .foregroundColor(Color.black)
                            .font(.subheadline)
                        Spacer()
                        Image("ic_down")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.black)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                    }
                    .padding(5)
                    .frame(width: (ScreenSize.width()/2)-35, height: 30)
                    .background(Color.shadow)
                    .cornerRadius(5)
                    if routeFilterPickerModel.pubIsModeValueChanged {
                        HStack{
                            Spacer()
                            Circle().fill(Color.green).frame(width: 8, height: 8, alignment: .center)
                                .offset(x: -1, y: -13)
                        }
                    }else{
                        HStack{
                            Spacer()
                            Spacer().frame(width: 8)
                        }
                    }
                }
            })
            .addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedMode) + ",Double Tap to Change Mode")
        }
        .padding(.horizontal, 10)
    }
    
    /// Top view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var topViewAODA: some View {
        VStack(spacing: 10){
            Button(action: {
                autoCompleteManager.pubOpenPage = false
                autoCompleteManager.pubFilteredItems.removeAll()
                autoCompleteManager.pubKeyword = ""
                autoCompleteManager.pubFilterKeywordForRoute = ""
            }, label: {
                HStack{
                    Spacer()
                    TextLabel("Back")
                        .foregroundColor(Color.black)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(5)
                .cornerRadius(5)
                .background(Color.shadow)
                .cornerRadius(5)
            })
            .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
            Button(action: {
                UIApplication.shared.dismissKeyboard()
                let agencies = RouteViewerModel.shared.agencies
                routeFilterPickerModel.filterType = .agency
                routeFilterPickerModel.prepareItems(items: agencies)
                routeFilterPickerModel.pubIsPresentPicker = true
            }, label: {
                ZStack{
                    HStack{
                        TextLabel(routeFilterPickerModel.pubSelectedAgency)
                            .foregroundColor(Color.black)
                            .font(.subheadline)
                        Spacer()
                        Image("ic_down")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.black)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                    }
                    .padding(5)
                    .cornerRadius(5)
                    .background(Color.shadow)
                    .cornerRadius(5)
                    if routeFilterPickerModel.pubIsAgencyValueChanged {
                        HStack{
                            Spacer()
                            Circle().fill(Color.green).frame(width: 8, height: 8, alignment: .center)
                                .offset(x: -1, y: -13)
                        }
                    }else{
                        HStack{
                            Spacer()
                            Spacer().frame(width: 8)
                        }
                    }
                }
            })
            
            .addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedAgency) + ",Double Tap to Change Agency")
            Button(action: {
                UIApplication.shared.dismissKeyboard()
                let agency = routeFilterPickerModel.pubSelectedAgency
                let modes = RouteViewerModel.shared.modesFor(agency: agency)
                routeFilterPickerModel.filterType = .mode
                routeFilterPickerModel.prepareItems(items: modes)
                routeFilterPickerModel.pubIsPresentPicker = true
            }, label: {
                ZStack{
                    HStack{
                        TextLabel(routeFilterPickerModel.pubSelectedMode.mapModeNameAliase())
                            .foregroundColor(Color.black)
                            .font(.subheadline)
                        Spacer()
                        Image("ic_down")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(Color.black)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                    }
                    .padding(5)
                    .background(Color.shadow)
                    .cornerRadius(5)
                    if routeFilterPickerModel.pubIsModeValueChanged {
                        HStack{
                            Spacer()
                            Circle().fill(Color.green).frame(width: 8, height: 8, alignment: .center)
                                .offset(x: -1, y: -13)
                        }
                    }else{
                        HStack{
                            Spacer()
                            Spacer().frame(width: 8)
                        }
                    }
                }
            })
            .addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedMode) + ",Double Tap to Change Mode")
        }
        .padding(.horizontal, 10)
    }
    
    /// Picker list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var pickerListView: some View {
        var pickerView =  RouteFilterPickerListView()
        pickerView.cancelAction = {
            routeFilterPickerModel.pubIsPresentPicker = false
        }
        
        pickerView.doneAction = {
            autoCompleteManager.pubFilteredItems.removeAll()
            let filteredRouteItems =  RouteViewerModel.shared.filteredRouteItems
            RouteViewerModel.shared.pubRouteItems = filteredRouteItems
            autoCompleteManager.loadSections(keywords: autoCompleteManager.pubKeyword)
            routeFilterPickerModel.pubIsPresentPicker = false
        }
        return pickerView
    }
}

struct AutoCompleteSectionView: View {
	var section: AutoCompleteSection
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		return VStack{
			
			HStack{
                TextLabel(section.sectionTitle, .bold, .title3)
				Spacer()
            }.addAccessibility(text: "%1".localized(section.sectionTitle))
			
			VStack(alignment:.leading) {
				HStack{ Spacer() }
				ForEach(section.sectionItems, id:\.id){ item in
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        AutoCompleteSectionItemViewAODA(item: item, style:section.displayStyle)
                    } else {
                        AutoCompleteSectionItemView(item: item, style:section.displayStyle)
                    }
				}
			}
		}
		.padding()
	}
}

struct AutoCompleteSectionItemView: View {
	
	var item: AutoCompleteItem
	var style: AutoCompleteDisplayStyle
	
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
        //get agency name and image for each route
        let agencyName = item.agencyTitle ?? ""
        var agencyImage = UIImage()
        if agencyName.count > 0 {
            agencyImage = RouteViewerModel.shared.agencyLogos[agencyName.lowercased()] ?? UIImage()
        }
		return VStack(alignment:.leading){
			if style == .plainText {
				HStack{
                    TextLabel(item.title, .bold, .subheadline)
						.foregroundColor(Color.black)
						.fixedSize(horizontal: false, vertical: true)
                        .addAccessibility(text: item.title.localized())
                }
			}
			else if style == .imageBeforeText {
				HStack{
					if let imageName = item.imageName {
						if item.imageWithMask {
                            Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:25, height: 25)
						}else{
							Image(imageName).resizable().frame(width:25, height: 25)
						}
					}
                    TextLabel(item.title, .bold, .subheadline)
						.foregroundColor(Color.black)
						.fixedSize(horizontal: false, vertical: true)
                }.addAccessibility(text: item.title.localized())
			}
			else if style == .imageWithTitleAndSubTitle {
				HStack{
					if let imageName = item.imageName {
						if item.imageWithMask {
							Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:25, height: 25)
						}else{
							Image(imageName).resizable().frame(width:25, height: 25)
						}
					}
					VStack(alignment:.leading){
                        TextLabel(item.title, .bold , .subheadline)
							.foregroundColor(Color.black)
							.fixedSize(horizontal: false, vertical: true)
                        if let subTitle = item.subTitle {
                            TextLabel(subTitle).font(.caption)
                                .foregroundColor(Color.gray_subtitle_color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
					}
                }.addAccessibility(text: item.title.localized() + (item.subTitle ?? "").localized())
			}
            else if style == .tagWithImageTitleAndSubTitle {
                let fontContrastColor = Helper.shared.getContrastColor(hexColor: item.tagColor ?? "#aaaaaa")
                HStack{
                    
                    if agencyName.count > 0 {
                        Image(uiImage: agencyImage)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50, alignment: .center)
                            .padding(.bottom, 5)
                    }
                    
                    if let imageName = item.imageName {
                        if item.imageWithMask {
                            Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:25, height: 25)
                        }else{
                            Image(imageName).resizable().aspectRatio(contentMode: .fit).frame(width:25, height: 25)
                        }
                    }
                    TextLabel(item.tagNumber == "N/A" ? item.title : item.tagNumber ?? "")
                        .font(.subheadline).padding(.horizontal, 2)
                        .foregroundColor(fontContrastColor).frame(minWidth: 60)
                        .frame(height: 30, alignment: .center)
                        /// Hex: item.tag color ?? "#aaaaaa")
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - Color.init(hex: item.tagColor ?? "#aaaaaa"
                        .background(Color.init(hex: item.tagColor ?? "#aaaaaa"))
                        .cornerRadius(5)
                        .padding(.all, 5)
                        .shadow(color: Color.gray, radius: 2)
                    
                    if item.tagNumber != "N/A" {
                        TextLabel(item.title, .bold, .subheadline)
                            .foregroundColor(Color.black)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }.addAccessibility(text: (item.tagNumber ?? "").localized() + item.title+(item.subTitle ?? "").localized())
                
            }
		}
		.frame(minHeight:60)
		.onTapGesture {
			item.onTap?(item.title, item.userInfo)
		}
	}
}

struct AutoCompleteSectionItemViewAODA: View {
    
    var item: AutoCompleteItem
    var style: AutoCompleteDisplayStyle
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        //get agency name and image for each route
        let agencyName = item.agencyTitle ?? ""
        var agencyImage = UIImage()
        if agencyName.count > 0 {
            agencyImage = RouteViewerModel.shared.agencyLogos[agencyName.lowercased()] ?? UIImage()
        }
        return VStack(alignment:.leading){
            if style == .plainText {
                HStack{
                    TextLabel(item.title, .bold, .subheadline)
                        .foregroundColor(Color.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .addAccessibility(text: item.title.localized())
                }
            }
            else if style == .imageBeforeText {
                VStack{
                    if let imageName = item.imageName {
                        if item.imageWithMask {
                            Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:25, height: 25)
                        }else{
                            Image(imageName).resizable().frame(width:25, height: 25)
                        }
                    }
                    TextLabel(item.title , .bold, .subheadline)
                        .foregroundColor(Color.black)
                        .fixedSize(horizontal: false, vertical: true)
                }.addAccessibility(text: item.title.localized())
            }
            else if style == .imageWithTitleAndSubTitle {
                VStack{
                    if let imageName = item.imageName {
                        if item.imageWithMask {
                            Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:25, height: 25)
                        }else{
                            Image(imageName).resizable().frame(width:25, height: 25)
                        }
                    }
                    VStack(alignment:.leading){
                        TextLabel(item.title, .bold, .subheadline)
                            .foregroundColor(Color.black)
                            .fixedSize(horizontal: false, vertical: true)
                        if let subTitle = item.subTitle {
                            TextLabel(subTitle).font(.caption)
                                .foregroundColor(Color.gray_subtitle_color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }.addAccessibility(text: item.title+(item.subTitle ?? "").localized())
            }
            else if style == .tagWithImageTitleAndSubTitle {
                let fontContrastColor = Helper.shared.getContrastColor(hexColor: item.tagColor ?? "#aaaaaa")
                VStack(alignment: .leading){
                    HStack {
                        if agencyName.count > 0 {
                            Image(uiImage: agencyImage)
                                .resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60, alignment: .center)
                                .padding(.bottom, 5)
                        }
                        
                        if let imageName = item.imageName {
                            if item.imageWithMask {
                                Image(imageName).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).foregroundColor(Color.black).frame(width:60, height: 60)
                            }else{
                                Image(imageName).resizable().aspectRatio(contentMode: .fit).frame(width:60, height: 60)
                            }
                        }
                    }
                    TextLabel(item.tagNumber == "N/A" ? item.title : item.tagNumber ?? "")
                        .font(.subheadline).padding(.horizontal, 2)
                        .foregroundColor(fontContrastColor).frame(minWidth: 60)
                        /// Hex: item.tag color ?? "#aaaaaa")
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - Color.init(hex: item.tagColor ?? "#aaaaaa"
                        .background(Color.init(hex: item.tagColor ?? "#aaaaaa"))
                        .cornerRadius(5)
                        .padding(.all, 5)
                        .shadow(color: Color.gray, radius: 2)
                        .multilineTextAlignment(.leading)
                    
                    if item.tagNumber != "N/A" {
                        TextLabel(item.title, .bold, .subheadline)
                            .foregroundColor(Color.black)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }.addAccessibility(text: (item.tagNumber ?? "").localized()+item.title+(item.subTitle ?? "").localized())
                
            }
            HorizontalLine(color: Color.gray).padding(.bottom, 10)
        }
        .frame(minHeight:60)
        .onTapGesture {
            item.onTap?(item.title, item.userInfo)
        }
    }
}

