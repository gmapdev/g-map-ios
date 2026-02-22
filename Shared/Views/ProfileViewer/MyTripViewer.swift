//
//  MyTripViewer.swift
//

import Foundation
import SwiftUI

struct MyTripViewer: View {
    @Inject var userAccountProvider: UserAccountProvider
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var tabBarMenuManager = TabBarMenuManager.shared
    let isLargeFontSize = AccessibilityManager.shared.pubIsLargeFontSize
    
    
    let imageSize = CGFloat(AccessibilityManager.shared.pubIsLargeFontSize ? 50 : 30)
    @State var pageTitle = "My Trips".localized()
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack(spacing: 0){
                if isLargeFontSize {
                    topViewAODA
                } else {
                    topView
                }
                ProfileTripViewer()
            }
            .onAppear(perform: {
				self.profileManager.refreshTripList(){
					var item: TripNotificationResponse?
					if self.profileManager.redirectSavedTripForPushByTripId.count > 0 {
						for element in self.profileManager.tripNotificationList {
							if element.id == self.profileManager.redirectSavedTripForPushByTripId {
								item = element
								break
							}
						}
					}
					self.profileManager.redirectSavedTripForPushByTripId = ""
					if let tripItem = item {
						self.jumpToSavedTripItem(item: tripItem)
					}
				}
            })
            .zIndex(99)
        }.background(profileManager.pubShowTripList ? Color.main : Color.white)
            .edgesIgnoringSafeArea(.all)
    }
	
    /// Jump to saved trip item.
    /// - Parameters:
    ///   - item: Parameter description
    func jumpToSavedTripItem(item: TripNotificationResponse){
        let itinerary = item.itinerary
        let itineraries = [itinerary]
        let tripPlan = OTPPlanTrip(itineraries: itineraries)
        ProfileManager.shared.tripManagerState = .update
        ProfileManager.shared.selectedGraphQLTripPlan = tripPlan
        ProfileManager.shared.selectedItinerary = itinerary
        ProfileManager.shared.selectedOldItinerary = item.itinerary
        ProfileManager.shared.pubPageState = .trips
        ProfileTripModel.shared.updateTripModel(item)
        ProfileTripModel.shared.getRenderData(item: item)
        ProfileManager.shared.pubShowTripList = false
        ProfileManager.shared.pubTripPageTitle = "Edit saved trip".localized()
    }
    
    /// Top view.
    /// - Parameters:
    ///   - some: Parameter description
    var topView: some View {
        VStack(spacing: 0){
            HStack{
                Spacer().frame(height:ScreenSize.safeTop()).background(Color.main)
            }
            HStack{
                Spacer()
                VStack{
                    HStack(spacing: 0){
                        if (!profileManager.pubShowTripList){
                            HStack{
                                Button(action: {
                                    self.backClicked()
                                }, label: {
                                    HStack(){
                                        Image("ic_leftarrow").renderingMode(.template).resizable().foregroundColor(Color.white)
                                            .frame(width: imageSize - 15, height: imageSize - 10, alignment: .center)
                                    }
                                })
                                .frame(width: imageSize, height: imageSize)
                                .padding(.leading, 10)
                                .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
                            }
                            Spacer().frame(maxWidth: 5)
                        }
                        HStack{
                            Spacer()
                            TextLabel(self.profileManager.pubTripPageTitle, .semibold, .title2).foregroundColor(Color.white)
                                .accessibilityAddTraits(.isHeader)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        if (!profileManager.pubShowTripList){
                            HStack{
                                Spacer().frame(width: imageSize)
                            }
                            Spacer().frame(maxWidth: 5)
                        }
                    }
                }
                Spacer()
            }
            .frame(height: 50)
            .background(Color.main)
        }
    }
    
    /// Top view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var topViewAODA: some View {
        VStack(spacing: 0){
            HStack{
                Spacer().frame(height:ScreenSize.safeTop()).background(Color.main)
            }
            HStack{
                Spacer()
                VStack{
                    HStack(spacing: 0){
                        if (!profileManager.pubShowTripList){
                            HStack{
                                Button(action: {
                                    self.backClicked()
                                }, label: {
                                    HStack(){
                                        Image("ic_leftarrow").renderingMode(.template).resizable().foregroundColor(Color.white)
                                            .frame(width: imageSize - 15, height: imageSize - 10, alignment: .center)
                                    }
                                })
                                .frame(width: imageSize, height: imageSize)
                                .padding(.leading, 10)
                                .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
                            }
                            Spacer().frame(maxWidth: 5)
                        }
                        HStack{
                            Spacer()
                            TextLabel(self.profileManager.pubTripPageTitle, .semibold, .title2).foregroundColor(Color.white)
                                .accessibilityAddTraits(.isHeader)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        if (!profileManager.pubShowTripList){
                            HStack{
                                Spacer().frame(width: imageSize - 15)
                            }
                            Spacer().frame(maxWidth: 5)
                        }
                    }
                }
                Spacer()
            }
            .background(Color.main)
        }
    }
    
    /// Back clicked
    /// Back clicked.
    func backClicked(){
        if let groupEntry = TripPlanningManager.shared.pubSelectedGroupEntry {
            if !groupEntry.itineraries.isEmpty {
                self.profileManager.selectedItinerary = groupEntry.itineraries[0]
            }
        }
        self.profileManager.refreshTripList()
        self.profileManager.pubPageState = .trips
        self.profileManager.pubShowTripList = true
        self.profileManager.pubTripPageTitle = "My Trips".localized()
        if profileManager.pubEditTripFromPlanTrip == true{
            tabBarMenuManager.currentViewTab = .planTrip
            tabBarMenuManager.currentItemTab = .planTrip
            profileManager.pubEditTripFromPlanTrip = false
        }
    }
}
