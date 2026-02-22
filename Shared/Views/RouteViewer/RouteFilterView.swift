//
//  RouteFilterView.swift
//

import SwiftUI

struct RouteFilterView: View {
    @ObservedObject var model = TripSettingsViewModel.shared
    @ObservedObject var routeFilterPickerModel = RouteFilterPickerListViewModel.shared
    
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
            }
            .background(Color.black).opacity(0.5)
            .ignoresSafeArea(edges: .all)
            .disabled(false)
            .allowsHitTesting(true)
            .onTapGesture {}
            .onDrag({ NSItemProvider(object: "" as NSItemProviderWriting) })
            .zIndex(1)
            
            VStack{
                Spacer()
                
                if !routeFilterPickerModel.pubIsPresentPicker {
                    VStack(spacing: 10){
                        HStack{
                            TextLabel("AGENCY".localized(), .bold, .body)
                            Spacer()
                        }
                        .padding()
                        
                        Button(action: {
                            let agencies = RouteViewerModel.shared.agencies
                            routeFilterPickerModel.filterType = .agency
                            routeFilterPickerModel.prepareItems(items: agencies)
                            routeFilterPickerModel.pubIsPresentPicker.toggle()
                        }, label: {
                            HStack{
                                Spacer().frame(width:20)
                                HStack{
                                    TextLabel(routeFilterPickerModel.pubSelectedAgency, .bold, .body).foregroundColor(Color.black)
                                    Spacer()
                                    Image("ic_sort_down")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 35, height: 35)
                                }
                                .frame(height: 50)
                                .padding(.horizontal)
                                .background(Color.white)
                                /// Radius: 5)
                                /// Initializes a new instance.
                                /// - Parameters:

                                ///   - RoundedCorner.init(radius: 5
                                .clipShape(RoundedCorner.init(radius: 5))
                                Spacer().frame(width:20)
                            }
                        })
                        .addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedAgency)+",Double Tap to Change Agency".localized())
                        
                        .frame(height: 20, alignment: .center)
                        
                        Spacer().frame(height: 20)
                        
                        HStack{
                            TextLabel("MODES".localized(), .bold, .body)
                            Spacer()
                        }
                        .padding()
                        
                        Button(action: {
                            let agency = routeFilterPickerModel.pubSelectedAgency
                            let modes = RouteViewerModel.shared.modesFor(agency: agency)
                            routeFilterPickerModel.filterType = .mode
                            routeFilterPickerModel.prepareItems(items: modes)
                            routeFilterPickerModel.pubIsPresentPicker.toggle()
                        }, label: {
                            HStack{
                                Spacer().frame(width:20)
                                HStack{
                                    TextLabel(routeFilterPickerModel.pubSelectedMode.mapModeNameAliase(), .bold, .body).foregroundColor(Color.black)
                                    Spacer()
                                    Image("ic_sort_down")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 35, height: 35)
                                }
                                .frame(height: 50)
                                .padding(.horizontal)
                                .background(Color.white)
                                /// Radius: 5)
                                /// Initializes a new instance.
                                /// - Parameters:

                                ///   - RoundedCorner.init(radius: 5
                                .clipShape(RoundedCorner.init(radius: 5))
                                Spacer().frame(width:20)
                            }
                        }).addAccessibility(text: "%1".localized(routeFilterPickerModel.pubSelectedMode)+",Double Tap to Change Mode".localized())
                        .frame(height: 20, alignment: .center)
                        
                        
                        HStack{
                            Spacer()
                            Button(action: {
                                RouteViewerModel.shared.pubIsPresentRouteFilter = false
                            }, label: {
                                TextLabel("Cancel".localized(), .bold, .body).foregroundColor(Color.black)
                            })
                            .frame(height: 20, alignment: .center)
                            Spacer().frame(width:100)
                            Button(action: {
                                RouteViewerModel.shared.pubIsPresentRouteFilter = false
                                let filteredRouteItems =  RouteViewerModel.shared.filteredRouteItems
                                RouteViewerModel.shared.pubRouteItems = filteredRouteItems
                            }, label: {
                                TextLabel("Save".localized(), .bold, .body).foregroundColor(Color.black)
                            })
                            .frame(height: 20, alignment: .center)
                            Spacer()
                        }
                        .frame(height: 50)
                        .padding(10)
                        .padding(.top, 20)
                        
                    }
                    .frame(height: 300)
                    .background(Color.gray_main)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding()
                }
                
                Spacer()
                
                if routeFilterPickerModel.pubIsPresentPicker{
                    VStack{
                        pickerListView.frame(height: AccessibilityManager.shared.pubIsLargeFontSize ? 350 : 250)
                        Spacer().frame(height: ScreenSize.safeBottom()).background(Color.white).zIndex(999)
                    }
                    .edgesIgnoringSafeArea(.bottom).padding(.top, 10)
                        .background(Color.white).clipShape(RoundedCorner(radius: 15, corners: [.topLeft, .topRight]))
                        .transition(.scale)
                }
                
            }
            .ignoresSafeArea(edges: .bottom)
            .zIndex(2)
        }
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
            routeFilterPickerModel.pubIsPresentPicker = false
        }
        return pickerView
    }
}

