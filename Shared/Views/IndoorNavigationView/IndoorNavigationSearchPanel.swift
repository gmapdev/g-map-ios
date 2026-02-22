//
//  IndoorNavigationSearchPanel.swift
//

import Foundation
import SwiftUI

struct IndoorNavigationSearchPanel: View {
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    @FocusState private var focusOriginTextField: Bool
    @FocusState private var focusDestinationTextField: Bool
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 60)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(.white)
                        .cornerRadius(10)
                        
                        VStack{
                            Spacer().frame(height:10)
                            HStack{
                                Spacer().frame(width:5)
                                Image(systemName: "location.circle").resizable().frame(width:20, height:20)
                                TextField("Current Location", text: self.$jmapManager.pubOrigin, onEditingChanged: { focused in
                                    self.indoor.originFocused = true
                                    self.indoor.destinationFocused = false
                                    if !focused{
                                        jmapManager.searchDestinations(searchText: self.jmapManager.pubOrigin)
                                    }
                                })
                                .onChange(of: self.jmapManager.pubOrigin) { newText in
                                    jmapManager.searchDestinations(searchText: newText)
                                }
                                .focused(self.$focusOriginTextField).padding(10)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 2))
                            .padding(10)
                            Spacer().frame(height: 2)
                            HStack{
                                Spacer().frame(width:5)
                                Image(systemName: "location.circle.fill").resizable().frame(width:20, height:20)
                                TextField("Enter Destination", text: self.$jmapManager.pubDestination, onEditingChanged: { focused in
                                    self.indoor.originFocused = false
                                    self.indoor.destinationFocused = true
                                    jmapManager.searchDestinations(searchText: self.jmapManager.pubDestination)
                                    if !focused{
                                        jmapManager.searchDestinations(searchText: self.jmapManager.pubDestination)
                                    }
                                })
                                .onChange(of: self.jmapManager.pubDestination) { newText in
                                    jmapManager.searchDestinations(searchText: newText)
                                }
                                .focused(self.$focusDestinationTextField).padding(10)
                            }
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 2))
                            .padding(10)
                            Spacer().frame(height:10)
                            HStack{
                                Spacer().frame(width:10)
                                Text("Available Locations:").font(.body).bold()
                                Spacer()
                            }
                            ScrollView{
                                VStack(spacing: 0){
                                    if self.indoor.originFocused {
                                        HStack{
                                            Spacer().frame(width:10)
                                            Image(systemName: "location.viewfinder")
                                            Text("Current Location").padding()
                                            Spacer()
                                        }.onTapGesture {
                                            // when current location Selected
                                            self.jmapManager.pubOrigin = "current location"
                                        }
                                    }
                                    ForEach(0..<self.jmapManager.pubSearchableDestinationList.count, id:\.self){ index in
                                        HStack{
                                            Spacer().frame(width:10)
                                            Image(systemName: "location.viewfinder")
                                            Text( jmapManager.getDestinationNameWithFloorString(self.jmapManager.pubSearchableDestinationList[index])).padding()
                                            Spacer()
                                        }.onTapGesture {
                                            if self.indoor.destinationFocused {
                                                self.jmapManager.pubDestination = self.jmapManager.pubSearchableDestinationList[index]
                                            }else if self.indoor.originFocused {
                                                self.jmapManager.pubOrigin = self.jmapManager.pubSearchableDestinationList[index]
                                            }
                                        }.padding(0)
                                    }
                                    if self.jmapManager.pubSearchableDestinationList.count <= 0{
                                        HStack{
                                            Spacer().frame(width:10)
                                            Text("No Location Found!").padding()
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .frame(height:300)
                            Spacer().frame(height:20)
                            HStack{
                                Spacer().frame(width:10)
                                Button(action: {
                                    IndoorNavigationManager.shared.pubPresentSearchPanel = false
                                    jmapManager.pubOrigin = "current location"
                                }, label: {
                                    HStack{
                                        Spacer()
                                        TextLabel("Cancel".localized()).font(.body).foregroundColor(Color.white).padding(15)
                                        Spacer()
                                    }
                                    .background(Color.secondary)
                                    .cornerRadius(5)
                                })
                                Spacer()
                                Button(action: {
                                    IndoorNavigationManager.shared.pubPresentSearchPanel = false
                                    jmapManager.calculateRoutes { sucess, err in
                                        if sucess{
                                            jmapManager.pubPresentDirectionPanel = true
                                            jmapManager.checkDeviationInterval = FeatureConfig.shared.indoor_nav_deviation_popup_wait_time_seconds
                                            jmapManager.nextDeviationTimeStemp = Date().timeIntervalSince1970
                                            jmapManager.pubOrigin = "current location"
                                            self.indoor.destinationFocused = true
                                            jmapManager.pubIsActiveIndoorNavigation = true
                                        }else{
                                            jmapManager.pubPresentDirectionPanel = false
                                        }
                                    }
                                }, label: {
                                    HStack{
                                        Spacer()
                                        TextLabel("Search".localized()).font(.body).foregroundColor(Color.white).padding(15)
                                        Spacer()
                                    }
                                    .background(Color.main)
                                    .cornerRadius(5)
                                })
                                Spacer().frame(width:10)
                            }
                        }
                        Spacer().frame(height:20)
                    }
                    Spacer().frame(width: 60)
                }
                Spacer()
                Spacer().frame(height: 80 + ScreenSize.safeBottom())
            }
            .zIndex(2)
        }
        
    }
}
