//
//  ProfileViewer.swift
//

import Foundation
import SwiftUI

struct ProfileViewer: View {
    @Inject var auth0Provider: LoginAuthProvider
    @Inject var userAccountProvider: UserAccountProvider
    @Inject var pushServiceProvider: PushServiceProvider
    @ObservedObject var profileManager = ProfileManager.shared
	@ObservedObject var mobileQuestionnair = MobileQuestionnairViewModel.shared
    @State var pageTitle = FeatureConfig.shared.login_page_title
    @State var showContent = true
    
    var callBack: (() -> Void)?
    let isLargeFontSize = AccessibilityManager.shared.pubIsLargeFontSize
    let imageSize = CGFloat(AccessibilityManager.shared.pubIsLargeFontSize ? 50 : 30)
    
    /// Back clicked
    /// Back clicked.
    func backClicked(){
        if profileManager.pubViewState == .editHome || profileManager.pubViewState == .editWork || profileManager.pubViewState == .addNewPlace {
            profileManager.pubViewState = .view
            showContent = true
        } else {
            if profileManager.isAccountSettingsUpdated() {
                profileManager.pubShowCloseAlert = true
            }else{
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    TabBarMenuManager.shared.seletedTab = TabBarItem(type: .user)
                    self.profileManager.pubPresentProfilePage = false
                    TabBarMenuManager.shared.pubShowProfilePopUp = true
                } else {
                    TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
                    self.profileManager.pubPresentProfilePage = false
                }
            }
        }
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
			
			if mobileQuestionnair.pubOpenMobileQuestionnairs {
                MobileQuestionnairView(isRegistrationFlow: false).zIndex(101).edgesIgnoringSafeArea(.all).background(Color.white)
			}else{
                ZStack{
                    VStack(spacing: 0){
                        if isLargeFontSize {
                            topViewAODA
                        } else {
                            topView
                        }
                        settingsView()
                    }.zIndex(100).edgesIgnoringSafeArea(.all)
                    if profileManager.pubShowCloseAlert{
                        CustomAlertView(titleMessage: "You have unsaved changes", primaryButton: "Keep editing", secondaryButton: "Discard changes",primaryAction: {
                            profileManager.pubShowCloseAlert = false
                        }, secondaryAction: {
                            AppSession.shared.loginInfo = AppSession.shared.tempLoginInfo
                            userAccountProvider.storeUserInfoToServer { success in }
                            if AccessibilityManager.shared.pubIsLargeFontSize {
                                TabBarMenuManager.shared.seletedTab = TabBarItem(type: .user)
                                self.profileManager.pubPresentProfilePage = false
                                TabBarMenuManager.shared.pubShowProfilePopUp = true
                            } else {
                                TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
                                self.profileManager.pubPresentProfilePage = false
                            }
                            profileManager.pubShowCloseAlert = false
                        }).zIndex(101)
                        .accessibility(addTraits: [.isModal])
                    }
                }
			}
        }.background(Color.white)
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
                        if profileManager.pubViewState == .view {
                            HStack{
                                Button(action: {
                                    UIApplication.shared.dismissKeyboard()
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
                        } else {
                            Spacer().frame(width: imageSize, height: imageSize)
                                .padding(.leading, 10)
                        }
                        Spacer().frame(maxWidth: 5)
                        HStack{
                            Spacer()
                            TextLabel("My Settings".localized(),.semibold, .title2).foregroundColor(Color.white)
                                .accessibilityAddTraits(.isHeader)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        HStack{
                            Spacer().frame(width: imageSize)
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
                        if profileManager.pubViewState == .view {
                            HStack{
                                Button(action: {
                                    UIApplication.shared.dismissKeyboard()
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
                        } else {
                            Spacer().frame(width: imageSize, height: imageSize)
                                .padding(.leading, 10)
                        }
                        Spacer().frame(maxWidth: 5)
                        HStack{
                            Spacer()
                            TextLabel("My Settings".localized(), .semibold, .title2).foregroundColor(Color.white)
                                .accessibilityAddTraits(.isHeader)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        HStack{
                            Spacer().frame(width: imageSize - 15)
                        }
                    }
                }
                Spacer()
            }
            .background(Color.main)
        }
    }
    
    /// Settings view
    /// - Returns: some View
    /// Settings view.
    func settingsView() -> some View {
        ScrollView{
            ScrollViewReader{ reader in
                VStack{
                    ProfileFavoritePlaceView(action: { value in
                        showContent = value
                    }, title: "Favorite Places".localized(), spacing: 0).padding(.top)
                    if showContent{
                        ProfileNotificationView(title: "Notifications".localized(), spacing: 0, sendTextCallBack: {
                            if !AccessibilityManager.shared.pubIsLargeFontSize {
                                withAnimation {
                                    reader.scrollTo(10)
                                }
                            }
                        }, changeNumberCallBack: {
                            if !AccessibilityManager.shared.pubIsLargeFontSize {
                                withAnimation {
                                    reader.scrollTo(10)
                                }
                            }
                        }).padding(.horizontal)
                        
                        TravelCompanionsView()
                        
                        LaunchDisclaimerView(title: "Terms".localized(), spacing: 0)
                            .padding(.top, 10)
                            .id(10)
						
						
                        VStack{
							
							if FeatureConfig.shared.enable_mobile_questionairs {
								Button(action: {
                                    mobileQuestionnair.pubOpenMobileQuestionnairs = true
								}, label: {
									HStack{
										Spacer()
										TextLabel("Review Accessibility Questions".localized()).font(.body).foregroundColor(Color.main).padding(20)
										Spacer()
									}
								})
								.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.main, lineWidth: 2))
								Spacer().frame(height:10)
							}
							
                            Button(action: {
                                if profileManager.pubHasConsentedToTerms {
                                    AppSession.shared.loginInfo?.hasConsentedToTerms = profileManager.pubHasConsentedToTerms
                                    AppSession.shared.loginInfo?.storeTripHistory = profileManager.pubStoreTripHistory
                                    AppSession.shared.pubStateLastUpdated = Date().timeIntervalSince1970
                                    if let deviceTokenData = AppSession.shared.pushDeviceTokenData, profileManager.isPushNotificationOpen {
                                        self.pushServiceProvider.subscribeRemoteNotification(deviceToken: deviceTokenData, completion: nil)
                                    }
                                    userAccountProvider.storeUserInfoToServer { success in
                                        if success {
                                            AlertManager.shared.presentAlert(message: "Your preferences have been saved.".localized())
                                        }else{
                                            AlertManager.shared.presentAlert(message: "Failed to save preferences.".localized())
                                        }
                                    }
                                    LoginAuthProvider().getUserInfo {}
                                }
                            }, label: {
                                HStack{
                                    Spacer()
                                    TextLabel("Save Preferences".localized()).font(.body).foregroundColor(Color.white).padding(20)
                                    Spacer()
                                }
                                .background(profileManager.pubHasConsentedToTerms ? Color.main : Color.gray)
                            })
                            .disabled(!profileManager.pubHasConsentedToTerms)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            Spacer().frame(height:10)
                            
                            Button(action: {
                                AlertManager.shared.presentConfirm(title: "", message: "Are you sure you would like to delete your user account? Once you do so, it cannot be recovered.".localized(), primaryButtonText: "Yes".localized(), secondaryButtonText: "No".localized()) { buttonText in
                                    if buttonText == "Yes".localized() {
                                        self.userAccountProvider.deleteOTPUserInfo() { success, errorMessage in
                                            if success {
                                                AlertManager.shared.presentAlert(title: "", message: "Your account has been deleted".localized())
                                                self.profileManager.pubPresentProfilePage = false
                                                AppSession.shared.logout()
                                            }else{
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                    AlertManager.shared.presentAlert(title: "", message: "Delete User Account Failed.  %1".localized(errorMessage ?? ""))
                                                }
                                            }
                                        }
                                    }
                                }
                            }, label: {
                                HStack{
                                    TextLabel("Delete my account".localized()).font(.body).foregroundColor(Color.red)
                                }
                            })
                            .padding(.top, 20)
                            
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
                .onAppear {
                    guard let login = AppSession.shared.loginInfo else { return }
                    profileManager.pubHasConsentedToTerms = login.hasConsentedToTerms
                    profileManager.pubStoreTripHistory = login.storeTripHistory
                }
            }
        }
        .gesture(DragGesture().onChanged({ _ in
            UIApplication.shared.dismissKeyboard()
        }))
        
    }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    /// Reduce.
    /// - Parameters:
    ///   - value: Parameter description
    ///   - nextValue: Parameter description
    /// - Returns: CGFloat)
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct ProfileViewer_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    public static var previews: some View {
        ProfileViewer()
    }
}
