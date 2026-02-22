//
//  LoginViewer.swift
//

import UIKit
import SwiftUI

struct LoginViewer: View {
	
	@ObservedObject var loginFlowManager = LoginFlowManager.shared
    @ObservedObject var profileManager = ProfileManager.shared
	
	@State var resetEmail = ""
	@State var loginTitle = FeatureConfig.shared.login_page_title
    @State var pageBottomButtonTitle = "Next".localized()
	@State var infoText = ""

	
	@Inject var authProvider: LoginAuthProvider
	@Inject var userAccountProvider: UserAccountProvider
    @Inject var pushServiceProvider: PushServiceProvider
	
	
 /// Present account complete
 /// Presents account complete.
	func presentAccountComplete(){
		loginFlowManager.pageState = .accountComplete
		loginTitle = FeatureConfig.shared.login_page_title
        pageBottomButtonTitle = "Finish".localized()
        self.infoText = ""
    }
    
    /// Present launch setup
    /// Presents launch setup.
    func presentLaunchSetup(){
        loginFlowManager.pageState = .launchSetup
        loginTitle = FeatureConfig.shared.login_page_title
        pageBottomButtonTitle = "Next".localized()
        self.infoText = ""
        loginFlowManager.pubPresentLoginPage = true
    }
    
    /// Present notification
    /// Presents notification.
    func presentNotification(){
        loginFlowManager.pageState = .notification
        loginTitle = FeatureConfig.shared.login_page_title
        pageBottomButtonTitle = "Next".localized()
        self.infoText = ""
        loginFlowManager.pubPresentLoginPage = true
    }
    /// Present questionnaire
    /// Presents questionnaire.
    func presentQuestionnaire(){
        loginFlowManager.pageState = .questionnaire
        loginTitle = "Accessibility Profile"
        pageBottomButtonTitle = "Next".localized()
        self.infoText = ""
        loginFlowManager.pubPresentLoginPage = true
    }
    
    /// Present location
    /// Presents location.
    func presentLocation() {
        loginFlowManager.pageState = .manageFavoritePlaces
        pageBottomButtonTitle = "Next".localized()
        self.infoText = ""
        loginFlowManager.pubPresentLoginPage = true
    }
    
    /// Cross clicked
    /// Cross clicked.
    func crossClicked(){
        if loginFlowManager.pageState == .login || loginFlowManager.pageState == .signup {
            loginFlowManager.pubPresentLoginPage = false
        }
        else if loginFlowManager.pageState == .verifyEmail {
            self.loginFlowManager.pubPresentLoginPage = false
            self.loginFlowManager.confirmSkip()
        }
        else if loginFlowManager.pageState == .manageFavoritePlaces {
            self.loginFlowManager.pubPresentLoginPage = false
        }
        else if loginFlowManager.pageState == .launchSetup {
            self.loginFlowManager.pubPresentLoginPage = false
        }
        else if loginFlowManager.pageState == .notification {
            self.loginFlowManager.pubPresentLoginPage = false
        }
        else if loginFlowManager.pageState == .accountComplete {
            self.loginFlowManager.pubPresentLoginPage = false
        }
        TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
    }
    
    /// Back clicked
    /// Back clicked.
    func backClicked(){
        if loginFlowManager.pageState == .manageFavoritePlaces {
            presentNotification()
        }
        else if loginFlowManager.pageState == .questionnaire{
            presentLaunchSetup()
        }
        else if loginFlowManager.pageState == .notification {
            if FeatureConfig.shared.enable_mobile_questionairs{
                presentQuestionnaire()
            }else{
                presentLaunchSetup()
            }
        }
        else if loginFlowManager.pageState == .accountComplete {
            presentLocation()
        }
        loginFlowManager.pubPresentPhoneNumberError = true
    }
    
    /// Get available notification methods.
    /// - Parameters:
    ///   - configString: Parameter description
    /// - Returns: [String]
    func getAvailableNotificationMethods(configString: String) -> [String] {
        let array = configString.components(separatedBy: ",")
        return array
    }
    
    /// Response click action
    /// Responds click action.
    func responseClickAction(){
        let availableMethods = getAvailableNotificationMethods(configString: FeatureConfig.shared.available_notification_methods)
        switch loginFlowManager.pageState {
        case .login, .signup, .resetPassword:
            // This is handled by auth0 SDK
            break
        case .launchSetup:
            if AppSession.shared.loginInfo != nil{
                if profileManager.pubHasConsentedToTerms {
                    AppSession.shared.loginInfo?.hasConsentedToTerms = profileManager.pubHasConsentedToTerms
                    AppSession.shared.loginInfo?.storeTripHistory = profileManager.pubStoreTripHistory
                    AppSession.shared.pubStateLastUpdated = Date().timeIntervalSince1970
                    self.userAccountProvider.storeUserInfoToServer { success in
                        if success {
                            if FeatureConfig.shared.enable_mobile_questionairs{
                                self.presentQuestionnaire()
                            }else{
                                self.presentNotification()
                            }
                        }
                    }
                }else{
                    AlertManager.shared.presentAlert(message: "You must agree to the terms of service to continue.")
                }
            }
            break
            // MARK: Needs to adjust Questionnaire, conditions later
        case .questionnaire:
            self.presentNotification()
            break
            
        case .notification:
            if availableMethods.contains("SMS") {
                if loginFlowManager.pubPresentPhoneNumberError {
                    if let loginInfo = AppSession.shared.loginInfo, !loginInfo.phoneVerified {
                        loginFlowManager.pubPresentPhoneNumberErrorPopUp = true
                        break
                    }
                }
            }
            if let deviceTokenData = AppSession.shared.pushDeviceTokenData, profileManager.isPushNotificationOpen {
                self.pushServiceProvider.subscribeRemoteNotification(deviceToken: deviceTokenData, completion: nil)
            }
            self.userAccountProvider.storeUserInfoToServer { success in
                if success {
                    self.presentLocation()
                }
            }
            break
        case .manageFavoritePlaces:
            self.userAccountProvider.storeUserInfoToServer { success in
                if success {
                    self.presentAccountComplete()
                }
            }
            break;
        case .accountComplete:
            AlertManager.shared.presentAlert(message: "Your preferences have been saved.".localized())
            loginFlowManager.pubPresentLoginPage = false
            loginFlowManager.pageState = .login
        default:
            loginFlowManager.pageState = .login
        }
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
            VStack{
                Spacer().frame(height: ScreenSize.safeTop()).background(Color.red)
                HStack{
                    if loginFlowManager.pageState != .login &&
                       loginFlowManager.pageState != .signup &&
                       loginFlowManager.pageState != .verifyEmail &&
                       loginFlowManager.pageState != .launchSetup{
                        Spacer().frame(width:10)
                        Button(action: {
                            self.backClicked()
                        }, label: {
                            VStack{
                                Spacer()
                                HStack{
                                    Spacer()
                                    Image("ic_leftarrow").renderingMode(.template).resizable()
                                        .foregroundColor( Color.white).frame(width:15, height: 20, alignment: .center)
                                    Spacer()
                                }
                                Spacer()
                                    
                            }
                            .frame(width:30, height:30)
                            .padding(.top, 10)
                            .accessibilityElement(children: .combine)
                            .addAccessibility(text: "Back Button, double tap to go back".localized())
                        })
                    }
                    
                    Spacer()
                    if loginFlowManager.pageState == .login || loginFlowManager.pageState == .signup {
                        Spacer()
                        Button(action: {
                            self.crossClicked()
                        }, label: {
                            VStack{
                                Spacer()
                                HStack{
                                    Spacer()
                                    Image(systemName: "xmark").resizable()
                                        .foregroundColor( Color.white).frame(width:15, height: 15, alignment: .center)
                                    Spacer()
                                }
                                Spacer()
                                    
                            }
                            .frame(width:30, height:30)
                            .padding(.top, 10)
                        })
                        Spacer().frame(width:20)
                    }
                }
                Spacer()
            }.zIndex(100)
            
            if loginFlowManager.pageState == .login || loginFlowManager.pageState == .signup {
                if AccessibilityManager.shared.pubIsLargeFontSize{
                    LoginSignUpViewAODA().zIndex(99)
                }else{
                    LoginSignUpView().zIndex(99)
                }
            }
            else{
                GeometryReader{ reader in
                    VStack{
                        HStack{
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(Color.white)
                    
                    VStack(spacing: 0){
                        HStack{
                            Spacer().frame(height:ScreenSize.safeTop()).background(Color.main)
                        }
                        HStack{
                            Spacer().background(Color.main)
                            ZStack{
                                if loginFlowManager.pageState == .verifyEmail{
                                        VStack{
                                            HStack{
                                                Spacer()
                                                Button(action: {
                                                    crossClicked()
                                                }, label: {
                                                    TextLabel("SKIP".localized(), .bold, .subheadline).foregroundColor(Color.white)
                                                }).frame(width: 50, height: 30, alignment: .center).padding(.trailing, 10)
                                            }
                                            Spacer()
                                        }
                                }
                                VStack{
                                    
                                    Spacer()
                                    Image("customer_logo_icon").resizable().frame(width: FeatureConfig.shared.login_logo_width, height: FeatureConfig.shared.login_logo_height, alignment: .center)
                                    TextLabel(loginTitle).font(.title2).foregroundColor(Color.white)
                                    Spacer()
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityHidden(true)
                                
                            }
                            Spacer()
                        }
                        .background(Color.main)
                        .frame(height:100)
                        .zIndex(999)
                        
                        if infoText.count > 0 {
                            HStack(spacing:0){
                                Spacer()
                                TextLabel(infoText).lineLimit(nil).multilineTextAlignment(.center).font(.subheadline).foregroundColor(Color.white).padding(10)
                                Spacer()
                            }
                            /// Hex:"#058305")
                            /// Initializes a new instance.
                            /// - Parameters:

                            ///   - Color.init(hex: "#058305"
                            .background(Color.init(hex:"#058305"))
                            .padding(0)
                            .padding(.top, 8)
                        }
                        
                        ScrollView {
                            if loginFlowManager.pageState == .verifyEmail {
                                verifyEmail()
                            }
                            else if loginFlowManager.pageState == .manageFavoritePlaces {
                                ProfileFavoritePlaceView()
                                    .padding([.horizontal, .vertical], 15)
                            }
                            else if loginFlowManager.pageState == .launchSetup{
                                LaunchDisclaimerView()
                            }
                            else if loginFlowManager.pageState == .notification{
                                ProfileNotificationView()
                                    .KeyboardAwarePadding()
                            }else if loginFlowManager.pageState == .questionnaire{
                                MobileQuestionnairView(isRegistrationFlow: true)
                            }
                            else if loginFlowManager.pageState == .accountComplete{
                                accountSetupCompletion()
                            }
                        }
                            
                        if ![LoginPageState.verifyEmail].contains(loginFlowManager.pageState) {
                            
                            Button(action: {
                                self.responseClickAction()
                            }, label: {
                                HStack{
                                    Spacer()
                                    VStack{
                                        Spacer()
                                        TextLabel(self.pageBottomButtonTitle).font(.title2).foregroundColor(Color.white)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .frame(height:100)
                                .background(Color.main)
                            })
                        }
                    }
                }
                .zIndex(99)
            }
            
            if loginFlowManager.pubPresentPhoneNumberErrorPopUp {
                CustomMessageView(titleMessage: "Please complete the verification process in order to set up SMS notifications.", boldMessage: "", primaryAction: {
                    loginFlowManager.pubPresentPhoneNumberErrorPopUp = false
                    loginFlowManager.pubPresentPhoneNumberError = false
                })
                .accessibility(addTraits: [.isModal])
                .zIndex(999)
            }
            
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    /// Account setup completion
    /// - Returns: some View
    /// Account setup completion.
    func accountSetupCompletion() -> some View {
        VStack{
            Spacer().frame(height:50)
            VStack{
                HStack{
                    TextLabel("Account setup complete!".localized()).font(.title).foregroundColor(Color.black)
                    Spacer()
                }
                .padding(.bottom, 20)
                
                HStack{
                    TextLabel("You are ready to start planning your trips.".localized()).font(.subheadline).lineLimit(nil).foregroundColor(Color.black)
                    Spacer()
                }
                
                Spacer()
            }
            .padding(20)
            Spacer()
        }
    }
    
    /// Verify email
    /// - Returns: some View
    /// Verify email.
    func verifyEmail() -> some View {
        VStack{
            Spacer().frame(height:50)
            VStack{
                HStack{
                    TextLabel("Verify your email address".localized(), .bold, .title2).foregroundColor(Color.black)
                    Spacer()
                }
                .padding(.bottom, 20)
                
                HStack{
                    TextLabel("Please check your email inbox and follow the link in the message to verify your email address before finishing your account setup.\n\nOnce you're verified, click the button below to continue.\n\nYou can plan trips and return to this page anytime to continue setting up your account.".localized()).font(.subheadline).lineLimit(nil).foregroundColor(Color.black)

                    Spacer()
                }

                HStack{
                    Button(action: {
                        self.userAccountProvider.verifyEmail(){ success, errorMessage in
                            if success {
                                self.userAccountProvider.storeUserInfoToServer { success in
                                    if success {
                                        LoginAuthProvider().getUserInfo {}
                                        LoginFlowManager.shared.removeSkip()
                                        profileManager.pubHasConsentedToTerms = false
                                        profileManager.pubStoreTripHistory = false
                                        DispatchQueue.main.async {
                                            self.presentLaunchSetup()
                                        }
                                    }
                                }
                            }else{
                                AlertManager.shared.presentAlert(message: "Email is not verified yet, Please go to your inbox and verify your email. %1".localized(errorMessage))
                            }
                        }
                    }, label: {
                        HStack{
                            Spacer()
                            TextLabel("My email is verified".localized()).font(.body).foregroundColor(.white).padding(15)
                            Spacer()
                        }
                        .background(Color.main)
                        .cornerRadius(10)
                        /// Corner radius: 10)
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - RoundedRectangle.init(cornerRadius: 10
                        .clipShape(RoundedRectangle.init(cornerRadius: 10))
                    })
                }
                .padding(.bottom, 30)
                .padding(.top, 30)
                
                Button(action: {
                    if let loginInfo = AppSession.shared.loginInfo {
                        self.userAccountProvider.resentVerification(email: loginInfo.email)
                    }
                }, label: {
                    HStack{
                        TextLabel("Resend verification email".localized()).font(.subheadline).foregroundColor(Color.main)
                        Spacer()
                    }
                })
                
                Spacer()
            }
            .padding(20)
            Spacer()
        }
    }
    
    /// Password rule description.
    /// - Parameters:
    ///   - color: Parameter description
    ///   - text: Parameter description
    ///   - withIcon: Parameter description
    ///   - indent: Parameter description
    /// - Returns: some View
    func passwordRuleDescription(color:Color, text: String, withIcon: String = "", indent: Bool = false) -> some View {
        HStack{
            Spacer().frame(width: indent ? 20 : 0)
            ZStack{
                Circle().fill(color).frame(width:15, height:15)
                if withIcon.count > 0 {
                    Image(systemName:withIcon).resizable().renderingMode(.template).aspectRatio(contentMode: .fit).foregroundColor(Color.white).frame(width:10, height:10)
                }
            }
            .padding(.trailing, 2)
            TextLabel(text).font(.caption).foregroundColor(color)
            Spacer()
        }
    }
    
    /// Area.
    /// - Parameters:
    ///   - forSysIcon: Parameter description
    /// - Returns: some View
    func area(forSysIcon: String) -> some View {
        HStack{
            Spacer()
            VStack{
                Spacer()
                Image(systemName: forSysIcon).renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width:20, height:20).foregroundColor(Color.gray)
                Spacer()
            }
            Spacer()
        }.frame(width:50, height:50)
    }
}

public struct LoginViewer_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    public static var previews: some View {
        LoginViewer()
    }
}
