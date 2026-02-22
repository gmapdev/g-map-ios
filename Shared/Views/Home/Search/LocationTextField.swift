//
//  LocationTextField.swift
//

import Foundation
import SwiftUI
import UIKit
import Combine

struct HorizontalLine: View {
    var color: Color
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        Divider().frame(height: 1).background(color).cornerRadius(8)
    }
}

struct LocationTextField: View {
    
    enum FocusedField {
         case searchField
    }
    
    @FocusState private var focusedField: FocusedField?
    @ObservedObject var searchViewModel = SearchLocationViewModel.shared
    @ObservedObject var autoCompleteManager = AutoCompleteManager.shared
    @ObservedObject var viewModel = SearchLocationViewModel.shared
    @ObservedObject var mapFromToViewModel = MapFromToViewModel.shared
    @ObservedObject var searchManager = SearchManager.shared
    @State var firstIgnore = true    // this is used to avoid 0 results for the first time.
    
    var placeholder: String
    var lineColor: Color
    var imageName: String?
    var resize: CGFloat?
	var colorImageWithMask: Color? = nil
	var treatAsButton: Bool = false
    var leadingPadding: CGFloat
    var imageOnTap:(()->Void)?
    var showClearButton: Bool = false
    var isPushedFrom: Bool = false
    
    @Binding var text: String
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {

		let savedLocationCount = AppSession.shared.loginInfo?.savedLocations?.count ?? 0
		let recentSearchCount = searchViewModel.recentLocations.count
        
		var summarizationText = "Enter location"
		if recentSearchCount > 0 {
			if savedLocationCount > 0 {
				summarizationText = "Enter a location or swipe right to access Recent Searched Locations and Favorite Places".localized()
			}else{
				summarizationText = "Enter a location or swipe right to access Recently Searched locations".localized()
			}
		}else{
			if savedLocationCount > 0 {
				summarizationText = "Enter a location or swipe right to access Favorite Places".localized()
			}
		}
		
		// check current typing search
		if autoCompleteManager.pubFilteredItems.count > 0 {
			if autoCompleteManager.pubKeyword.count > 0 {
				let keywords = viewModel.searchText.chunckCharacters()
				summarizationText = "%1 results for %2. swipe right to access the list of results".localized("\(AutoCompleteManager.shared.pubFilteredItems.count)", "\(keywords)")
			}
		}

        let buttonTextColor = text.count > 0 ? Color.black : Color.gray_subtitle_color
        let buttonText = text.count > 0 ? text : placeholder
        return HStack(spacing: 0) {
                if !AccessibilityManager.shared.pubIsLargeFontSize {
                    Button(action:{
                        self.imageOnTap?()
                    }, label:{
                        VStack{
                            if let imageName = imageName {
                                if let color = colorImageWithMask {
                                    Image(imageName)
                                        .renderingMode(.template)
                                        .resizable()
                                        .foregroundColor(color)
                                        .frame(width: resize ?? 20, height: resize ?? 20, alignment: .center)
                                        .aspectRatio(contentMode: .fit)
                                        .padding(.leading, 10)
                                        .padding(.top, imageName != "icon_search" ? 15 : 3)
                                }else{
                                    Image(imageName)
                                        .resizable()
                                        .frame(width: resize ?? 20, height: resize ?? 20, alignment: .center)
                                        .aspectRatio(contentMode: .fit)
                                        .padding(.leading, 10)
                                }
                            }
                        }
                    }).accessibilityHidden(true)
                } else {
                    Spacer().frame(width: leadingPadding)
                }
                
				if treatAsButton {
					HStack{
                        TextLabel(buttonText.localized(), .bold, .body).foregroundColor(buttonTextColor)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.gray_subtitle_color)
						Spacer()
					}
				}else{
					HStack{
						TextField(placeholder, text: $text)
							.accessibilityAddTraits([.isStaticText])
							.focused($focusedField, equals: .searchField)
							.accessibilityLabel("")
							.accessibilityHint("")
							.accessibilityValue(summarizationText)
                            .padding(.top, 3)
                            .foregroundColor(Color.gray_subtitle_color)
                    }
                    .padding(10)
                }
            if showClearButton {
                if !text.isEmpty {
                    Button(action: {
                        if isPushedFrom {
                            clearOrigin()
                        } else {
                            clearDestination()
                        }
                    }, label: {
                        Image(systemName: "xmark")
                            .renderingMode(.template)
                            .resizable()
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .frame(width: 15, height: 15)
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.clearSearchTextButton.rawValue.localized())
                    .accessibilityAction {
                        
                    }
                    Spacer().frame(width: 15)
                }
            }
                
            }.frame(maxWidth: ScreenSize.width())
        .onAppear(){
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                searchViewModel.firstIgnore = true
                focusedField = .searchField
            })
        }
        .onReceive(Just(viewModel.searchText)) { value in
            if !searchViewModel.firstIgnore {
                let searchResultsCount = viewModel.locations.count
                let searchResultsText = searchResultsCount > 0 ? "%1 results for %2. swipe right to access the list of results".localized(searchResultsCount, "\(viewModel.searchText.chunckCharacters())") : "0 result found."
                UIAccessibility.post(notification: .announcement, argument: searchResultsText)
            }
            
            if let timer = searchViewModel.firstIngoreTimer {
                timer.invalidate()
                searchViewModel.firstIngoreTimer = nil
            }
            
            searchViewModel.firstIngoreTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
                searchViewModel.firstIgnore = false
            })
        }
    }
    
    /// Clear origin
    /// Clears origin.
    func clearOrigin() {
        text = ""
        searchManager.from = nil
        mapFromToViewModel.pubFromDisplayString = ""
        mapFromToViewModel.pubFromString = ""
    }

    /// Clear destination
    /// Clears destination.
    func clearDestination() {
        text = ""
        searchManager.to = nil
        mapFromToViewModel.pubToDisplayString = ""
        mapFromToViewModel.pubToString = ""
    }
}

struct TripLocationView: View {
    let placeholder: String
    let lineColor: Color
    let imageName: String
    let isLargeFont: Bool
    var action: (()->Void)? = nil
    @Binding var text: String
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            HStack {
                button
            }
        }
    }
    
    /// Button.
    /// - Parameters:
    ///   - some: Parameter description
    private var button: some View {
       return  Button(action: {
           TripPlanningManager.shared.cancelAllItinerariesRequests()
			StopViewerViewModel.shared.cancelAllStopsRequests()
            action?()
        }) {
            HStack{
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isLargeFont ? 40 : 20, height: isLargeFont ? 40 : 20)
                if text.isEmpty {
                    TextLabel("\(placeholder)".localized(), .bold, .body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color.gray_subtitle_color)
                        .lineLimit(5)
                } else {
                    TextLabel("\(text)".localized(), .bold, .body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                }
                Spacer()
            }
			
        }
    }
}
