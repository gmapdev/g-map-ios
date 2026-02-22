//
//  IndoorNavigationView.swift
//

import Foundation
import SwiftUI

struct IndoorNavigationView: View {
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    @State var presentGenericDialog = false
    @State var genericDialogTitle = ""
    @State var genericDialogMessage = ""
    @State var genericDialogCallback:((String)->Void)?
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let floors: [JMapFloor] = jmapManager.floors()
        return ZStack{
            // Top Bar with Back Button
            VStack{
                Spacer().frame(height: ScreenSize.safeTop())
                HStack{
                    /// Back Button
                    VStack{
                        Button(action: {
                            indoor.pubPresentIndoorNavigationView = false
                            IndoorNavigationManager.shared.stopIndoorExtendsSDK()
                            JMapManager.shared.stopUniversalTimer()
                            JMapManager.shared.lastTriggeredMainEntranceLocation = nil
                        }, label: {
                            Image(systemName: "chevron.backward.circle.fill").resizable().frame(width:45, height:45).foregroundColor(Color.main)
                        })
                        
                    }.zIndex(2)
                    Spacer()
                    /// Center Floor Name
                    VStack {
                        if floors.count > 1 {
                            /// Implementation of Menu
                            Menu {
                                ForEach(floors, id: \.self) { floor in
                                    Button(floor.name ?? "No Name") {
                                        jmapManager.pubSelectedFloor = floor
                                        jmapManager.renderFloor(floor: floor)
                                        if !jmapManager.isUserExploringMap{
                                            jmapManager.isUserExploringMap = true         // this is for stop app forcing to show the current floor, user can explore the map
                                            ToastManager.show(message: "Follow me function disabled")
                                        }
                                    }
                                }
                            } label: {
                                ZStack {
                                    HStack {
                                        Text(jmapManager.pubSelectedFloor?.name ?? "No Name")
                                            .font(.system(size: 25))
                                            .bold()
                                            .foregroundStyle(Color.white)
                                        
                                        Spacer().frame(width: 10)
                                        Image(systemName: "arrowtriangle.down.fill")
                                            .resizable()
                                            .renderingMode(.template)
                                            .foregroundColor( Color.white )
                                            .frame(width: 20, height: 10)
                                    }.padding(.horizontal, 10)
                                        .zIndex(2)
                                    
                                    HStack { Spacer() }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color.main)
                                                .frame(height: 45)
                                        ).zIndex(1)
                                }
                            }
                            
                        } else {
                            ZStack {
                                HStack {
                                    if let selectedFloor = jmapManager.pubSelectedFloor {
                                        Text(selectedFloor.name ?? "No Name")
                                            .font(.system(size: 25))
                                            .bold()
                                            .foregroundStyle(floors.count > 1 ? Color.white : Color.main)
                                    } else {
                                        Text("")
                                            .font(.system(size: 25))
                                            .bold()
                                            .foregroundStyle(Color.main)
                                    }
                                }
                                .zIndex(2)
                                
                                HStack { Spacer() }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(floors.count > 1 ? Color.main : Color.clear)
                                            .frame(height: 45)
                                    )
                                    .zIndex(1)
                            }
                        }
                    }.zIndex(2)
                    Spacer()
                    /// Search Button
                    VStack{
                        Button(action: {
                            indoor.pubPresentSearchPanel = true
                            jmapManager.searchDestinations(searchText: "")
                        }, label: {
                            Image(systemName: "magnifyingglass.circle.fill").resizable().frame(width:45, height:45).foregroundColor(Color.main)
                        })
                    }.zIndex(2)
                }
                .frame(height: 50)
                .padding(.horizontal)
                if jmapManager.pubPresentDirectionPanel {
                    Spacer().frame(height: 50)
                }
                HStack{
                    Image("ic_label")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(.leading, 20)
                    
                    Toggle(isOn: Binding<Bool>(
                        get:{
                            return self.jmapManager.pubIsShowMapLabels
                        },
                        set:{
                            self.jmapManager.pubIsShowMapLabels = $0
                            if $0 {
                                jmapManager.toggleMapLabels(true)
                            }else{
                                jmapManager.toggleMapLabels(false)
                            }
                        }
                    ), label: {
                        TextLabel("Map Labels", .semibold, .callout)
                            .foregroundStyle(Color.black)
                    })
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 20))
                    .frame(width: ScreenSize.width() - (40 + 25)) // Custom size
                    
                }
                .frame(width: ScreenSize.width() - 30, height: 40)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                Spacer()
            }.zIndex(2)
            
            if jmapManager.pubIsLoadingMap {
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer().frame(height:20)
                    HStack{
                        Spacer()
                        Text("Loading Floor ..").font(.system(size: 15)).foregroundStyle(Color.gray)
                        Spacer()
                    }
                    Spacer()
                }.zIndex(3)
            }
            
            
            JMapCanvasView().edgesIgnoringSafeArea(.all).zIndex(1)
            
            if jmapManager.pubPresentDirectionPanel {
                IndoorDirectionView().edgesIgnoringSafeArea(.all).zIndex(4)
            }

            if self.indoor.pubPresentSearchPanel {
                IndoorNavigationSearchPanel().edgesIgnoringSafeArea(.all).zIndex(4)
            }
            
            if jmapManager.pubPresentStepsPanel {
                IndoorNavigationStepsView().edgesIgnoringSafeArea(.all).zIndex(5)
            }
            if self.indoor.pubPresentIndoorExitDirectionDialog{
                IndoorExitDirectionDialog().edgesIgnoringSafeArea(.all).zIndex(6)
            }
            
            if IndoorGenericDialogManager.shared.pubPresentIndoorGenericDialog {
                IndoorGenericDialog().edgesIgnoringSafeArea(.all).zIndex(7)
            }
            
            VStack{
                Spacer()
                // Locate Me Button
                HStack{
                    Spacer()
                    Button(action: {
                        JMapManager.shared.locateMe()
                    }, label: {
                        HStack{
                            Image(systemName:"scope" ).resizable().foregroundColor(Color.white).frame(width:30, height:30).padding(5)
                        }
                        .frame(width:45, height:45)
                        .background(JMapManager.shared.isUserExploringMap ? Color.gray : Color.main)
                        .cornerRadius(10)
                    })
                    Spacer().frame(width:20)
                }
                Spacer().frame(height: ScreenSize.safeBottom() + 20)
            }.zIndex(2)
            
        }
        .background(Color.white)
        .edgesIgnoringSafeArea([.bottom, .horizontal])
    }
}
