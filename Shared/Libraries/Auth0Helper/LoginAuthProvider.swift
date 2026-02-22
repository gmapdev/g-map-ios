//
//  LoginAuthProvider.swift
//

import Foundation
import SwiftUI
import Auth0
import Lock

public class LoginAuthProvider {
	
	@Inject var userAccountProvider: UserAccountProvider
	@Inject var pushServiceProvider: PushServiceProvider
	
	var username : String? {
		get{
			let token : String? = PreferenceManager.object(forKey: StoredValueKeys.username.rawValue)
			return token
		}
		set{
			if let value = newValue{
				PreferenceManager.set(value, forKey: StoredValueKeys.username.rawValue)
			}
		}
	}
	var password : String? {
		get{
			let token : String? = PreferenceManager.object(forKey: StoredValueKeys.password.rawValue)
			return token
		}
		set{
			if let value = newValue{
				PreferenceManager.set(value, forKey: StoredValueKeys.password.rawValue)
			}
		}
	}
	var accessToken : String? {
		get{
			let token : String? = PreferenceManager.object(forKey: StoredValueKeys.accessToken.rawValue)
			return token
		}
		set{
			if let value = newValue{
				PreferenceManager.set(value, forKey: StoredValueKeys.accessToken.rawValue)
			}
		}
	}
	var expiresIn : Double? {
		get {
			let expireTime : Double? = PreferenceManager.object(forKey: StoredValueKeys.expireIn.rawValue)
			return expireTime
		}
		set{
			if let value = newValue{
				let expireTime = Date().timeIntervalSince1970 + value
				PreferenceManager.set(expireTime, forKey: StoredValueKeys.expireIn.rawValue)
			}
		}
	}
	//  This will crash unless auth0 .plist values are set up correctly
	var manager = CredentialsManager(authentication: Auth0.authentication())
	
	private var credentials: Credentials?
	
 /// Get user info.
 /// - Parameters:
 ///   - callBack: Parameter description
 /// - Returns: Void)
	func getUserInfo(callBack: @escaping () -> Void){
		if !(self.accessToken == nil) && !(self.accessToken == ""){
			if !checkTokenExpires(){
				if let accessToken = self.accessToken{
					self.getAuth0UserInfo(token: accessToken) { success, errMsg, userInfo in
						if success{
							if let userInfo = userInfo{
								self.retrieveUserInfo(userInfo: userInfo) {
									callBack()
								}
							}
						}else{
							callBack()
							OTPLog.log(level: .error, info: "Request failed, something went wrong, \(errMsg)")
							return
						}
					}
				}
				else{
					callBack()
				}
			}else{
				if let username = self.username, let password = self.password{
					self.getAuth0AccessToken(username: username, password: password) { success, errMsg, _ in
						if success{
							self.getUserInfo {}
						}else{
							callBack()
						}
					}
				}else{
					callBack()
				}
			}
		}
		else{
			callBack()
		}
	}
	
 /// Get token
 /// - Returns: String?
 /// Retrieves token.
	func getToken() -> String? {
		return self.accessToken
	}
	
 /// Check token expires
 /// - Returns: Bool
 /// Checks token expires.
	func checkTokenExpires() -> Bool{
		if let expireTime = self.expiresIn{
			if Date().timeIntervalSince1970 - 60 > expireTime{
				return true
			}else{
				return false
			}
		}
		return false
	}
	
 /// Logout
 /// Logout.
	public func logout() {
		self.accessToken = ""
		self.expiresIn = 0.0
		self.username = ""
		self.password = ""
	}
	
 /// Notification type index.
 /// - Parameters:
 ///   - type: Parameter description
 /// - Returns: Int
	public func notificationTypeIndex(type: String) -> Int {
		switch type.lowercased() {
		case "email": return 0
		case "sms": return 1
		case "": return 2
		default: return 0
		}
	}
	
 /// Get auth0 access token.
 /// - Parameters:
 ///   - username: Parameter description
 ///   - password: Parameter description
 ///   - completion: Parameter description
 ///   - String: Parameter description
 ///   - Token?: Parameter description
 /// - Returns: Void)
	func getAuth0AccessToken(username: String, password: String, completion: @escaping(Bool, String, Token?) -> Void){
		if !Env.shared.isNetworkConnected {
			completion(false, "No Internet connection", nil)
		}
		let api = OTPAPIRequest()
		let url = BrandConfig.shared.auth0_domain + "/oauth/token"
		let param : [String : Any] = [
			"grant_type" : "password",
			"audience" : "https://otp-middleware",
			"scope" : "openid profile email otp-user",
			"username": username,
			"password": password,
			"client_id" : BrandConfig.shared.auth0_client_id,
			"client_secret" : BrandConfig.shared.auth0_client_secret
		]
		api.request(method: .post, path: url, params: param, headers: [:], format: .JSON) { data, error, response in
			
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot receive the token response from auth0")
				completion(false, "cannot receive the token response from auth0", nil)
				return
			}
			
			if let err = error {
				var errMsg = "Something Went Wrong. Please Try again later."
				if let errorData = DataHelper.object(data) as? [String: Any]{
					if let desc = errorData["error_description"] as? String{
						errMsg = desc
						completion(false, errMsg, nil)
						return
					}
				}else{
					OTPLog.log(level:.warning, info:"response from auth0 server for token is failed, invalid error json data")
				}
				OTPLog.log(level:.warning, info:"response from auth0 server for token is failed, \(err.localizedDescription)")
				completion(false,errMsg , nil)
				return
			}
			
			do{
				let token = try JSONDecoder().decode(Token.self, from: data)
				if let accessToken = token.accessToken, let expireTime = token.expiresIn{
					self.accessToken = accessToken
					self.expiresIn = Double(expireTime)
					self.username = username
					self.password = password
				}
				completion(true, "", token)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the auth0 token, \(error)")
				completion(false, "can not decode the auth0 token", nil)
			}
		}
	}
	
 /// Get auth0 user info.
 /// - Parameters:
 ///   - token: Parameter description
 ///   - completion: Parameter description
 ///   - String: Parameter description
 ///   - AuthUserInfo?: Parameter description
 /// - Returns: Void)
	func getAuth0UserInfo(token: String, completion: @escaping(Bool, String ,AuthUserInfo?) -> Void){
		let api = OTPAPIRequest()
		let url = BrandConfig.shared.auth0_domain + "/userinfo"
		let headers: [String : String] = ["Authorization": "Bearer \(token)"]
		
		api.request(method: .get, path: url, headers: headers) { data, error, response in
			
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot receive the userInfo response from auth0")
				completion(false, "cannot receive the userInfo response from auth0", nil)
				return
			}
			
			if let err = error {
				var errMsg = "Something Went Wrong. Please Try again later."
				if let errorData = DataHelper.object(data) as? [String: Any]{
					if let desc = errorData["error_description"] as? String{
						errMsg = desc
						completion(false, errMsg, nil)
						return
					}
				}else{
					OTPLog.log(level:.warning, info:"response from auth0 server for userInfo is failed, invalid error json data")
				}
				OTPLog.log(level:.warning, info:"response from auth0 server for userInfo is failed, \(err.localizedDescription)")
				completion(false,errMsg , nil)
				return
			}
			
			do{
				let userInfo = try JSONDecoder().decode(AuthUserInfo.self, from: data)
				completion(true, "", userInfo)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the auth0 userInfo, \(error)")
				completion(false, "can not decode the auth0 userInfo", nil)
			}
		}
	}
	
 /// Retrieve user info.
 /// - Parameters:
 ///   - userInfo: Parameter description
 ///   - callBack: Parameter description
 /// - Returns: Void)? = nil)
	public func retrieveUserInfo(userInfo: AuthUserInfo, callBack: (() -> Void)? = nil) {
		guard let accessToken = self.accessToken else {
			return
		}
		guard let expiresIn = self.expiresIn else {
			return
		}
		let loginInfo = LoginInfo(email: userInfo.email ?? userInfo.nickname ?? "",
								  token: accessToken,
								  expire: expiresIn,
								  emailIsVerified: userInfo.emailVerified ?? false,
								  phoneVerified: userInfo.phoneNumberVerified ?? false,
								  id:nil,
								  name:  userInfo.name ?? "",
								  storeTripHistory: false,
								  hasConsentedToTerms: false,
								  notificationChannel: "email",
                                phoneNumber: userInfo.phoneNumber ?? "", pushDevices: 0,
								  savedLocations: [],
								  auth0UserId: userInfo.sub)
		
		AppSession.shared.loginInfo = loginInfo
        AppSession.shared.tempLoginInfo = loginInfo
		
		
		// Prepare the otp-middleware user information
		self.userAccountProvider.retrieveOTPUserInfo { success, otpUserInfoResponse in
			if success {
				if let user = otpUserInfoResponse {
					guard let info = AppSession.shared.loginInfo else {
						assertionFailure("login info is not available, something went wrong")
						return
					}
					var newLoginInfo = info
					newLoginInfo.id = user.id
					newLoginInfo.auth0UserId = userInfo.sub
					newLoginInfo.email = user.email
					newLoginInfo.hasConsentedToTerms = user.hasConsentedToTerms
					newLoginInfo.notificationChannel = user.notificationChannel
					newLoginInfo.phoneNumber = user.phoneNumber
					newLoginInfo.phoneVerified = user.isPhoneNumberVerified
					newLoginInfo.savedLocations = user.savedLocations
					newLoginInfo.storeTripHistory = user.storeTripHistory
                    newLoginInfo.pushDevices = user.pushDevices
					
					AppSession.shared.loginInfo = newLoginInfo
                    AppSession.shared.tempLoginInfo = newLoginInfo
                    
                    MobileQuestionnairViewModel.shared.selectedMobilityProfile = user.mobilityProfile
                    MobileQuestionnairViewModel.shared.serverMobilityProfile = user.mobilityProfile
					
                    TravelCompanionsViewModel.shared.pubCompanions.removeAll()
                    if let companions = user.relatedUsers{
                        TravelCompanionsViewModel.shared.pubCompanions = companions
                        ProfileTripModel.shared.pubCompanionDropdownItem = TravelCompanionsViewModel.shared.getCompanionList()
                        
                    }
                    TravelCompanionsViewModel.shared.pubDependents.removeAll()
                    if let dependents = user.dependents, !(dependents.isEmpty){
                        let allDependents = dependents.joined(separator: ",")
                        self.userAccountProvider.getDependentsMobilityProfile(dependentIds: allDependents) { success, dependentsList in
                            if success, let dependents = dependentsList{
                                TravelCompanionsViewModel.shared.pubDependents = dependents
                                ProfileTripModel.shared.pubObserversDropdownitem = TravelCompanionsViewModel.shared.getCompanionList()
                            }
                            TravelCompanionsViewModel.shared.getDependentsMobilityProfileList()
                        }
                    }
                    
					if let deviceTokenData = AppSession.shared.pushDeviceTokenData {
						self.pushServiceProvider.subscribeRemoteNotification(deviceToken: deviceTokenData, completion: nil)
					}
				}
			}
			
			DispatchQueue.main.async {
                if let notificationChannel = AppSession.shared.loginInfo?.notificationChannel {
                    ProfileManager.shared.pubNotificationType = notificationChannel.components(separatedBy: ",")
                }
				ProfileManager.shared.pubNotificationPhoneNumber = AppSession.shared.loginInfo?.phoneNumber ?? ""
				ProfileManager.shared.pubHasConsentedToTerms = AppSession.shared.loginInfo?.hasConsentedToTerms ?? false
				ProfileManager.shared.pubStoreTripHistory = AppSession.shared.loginInfo?.storeTripHistory ?? false
				
				if TabBarMenuManager.shared.currentViewTab != .myTrips {
                    if !LiveRouteManager.shared.pubIsRouteActivated {
                        let previousTab = TabBarMenuManager.shared.previousItemTab
                        TabBarMenuManager.shared.currentViewTab = previousTab
                        TabBarMenuManager.shared.currentItemTab = previousTab
                    }
				}
				
				if let loginInfo = AppSession.shared.loginInfo, !loginInfo.emailIsVerified {
					// Present the login page for verify email
                    if !LoginFlowManager.shared.needToSkip(){
                        LoginFlowManager.shared.pubPresentLoginPage = true
                        LoginFlowManager.shared.pageState = .verifyEmail
					}
				}
				else if let loginInfo = AppSession.shared.loginInfo, !loginInfo.hasConsentedToTerms {
					LoginFlowManager.shared.pageState = .launchSetup
					AppSession.shared.pubStateLastUpdated = Date().timeIntervalSince1970
				}
				else{
					// Update ui to notify pages, the user successfully login
                    LoginFlowManager.shared.pageState = .login
					AppSession.shared.pubStateLastUpdated = Date().timeIntervalSince1970
					LoginFlowManager.shared.removeSkip()
				}
                callBack?()
			}
		}
	}
	
 /// Sign up auth0.
 /// - Parameters:
 ///   - username: Parameter description
 ///   - password: Parameter description
 ///   - completion: Parameter description
 ///   - String: Parameter description
 ///   - SignupResponse?: Parameter description
 /// - Returns: Void)
	func signUpAuth0(username: String, password: String, completion: @escaping(Bool, String, SignupResponse?) -> Void){
		if !Env.shared.isNetworkConnected {
			completion(false, "No Internet connection", nil)
		}
		let api = OTPAPIRequest()
		let url = BrandConfig.shared.auth0_domain + "/dbconnections/signup"
		
		let param : [String : Any] = [
			"email": username,
			"password": password,
			"client_id" : BrandConfig.shared.auth0_client_id,
			"connection" : "Username-Password-Authentication"
		]
		api.request(method: .post, path: url, params: param, headers: [:], format: .JSON) { data, error, response in
			
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot receive the token response from auth0")
				completion(false, "cannot receive the token response from auth0", nil)
				return
			}
			
			if let err = error {
				var errMsg = "Something Went Wrong. Please Try again later."
				if let errorData = DataHelper.object(data) as? [String: Any]{
					if let desc = errorData["description"] as? String{
						errMsg = desc
						completion(false, errMsg, nil)
						return
					}
				}else{
					OTPLog.log(level:.warning, info:"response from auth0 server for signup is failed, invalid error json data")
				}
				OTPLog.log(level:.warning, info:"response from auth0 server for signup is failed, \(err.localizedDescription)")
				completion(false, errMsg, nil)
				return
			}
			
			do{
				let signUpResponse = try JSONDecoder().decode(SignupResponse.self, from: data)
				completion(true, "", signUpResponse)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the auth0 token, \(error)")
				completion(false, "can not decode the auth0 token", nil)
			}
		}
	}
	
 /// Reset password.
 /// - Parameters:
 ///   - username: Parameter description
 ///   - completion: Parameter description
 ///   - String: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)
	func resetPassword(username: String, completion: @escaping(Bool, String, String?) -> Void){
		if !Env.shared.isNetworkConnected {
			completion(false, "No Internet connection", nil)
		}
		let api = OTPAPIRequest()
		let url = BrandConfig.shared.auth0_domain + "/dbconnections/change_password"
		
		let param : [String : Any] = [
			"email": username,
			"client_id" : BrandConfig.shared.auth0_client_id,
			"connection" : "Username-Password-Authentication"
		]
		api.request(method: .post, path: url, params: param, headers: [:], format: .JSON) { data, error, response in
			
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot receive the token response from auth0")
				completion(false, "cannot receive the token response from auth0", nil)
				return
			}
			
			if let err = error {
				var errMsg = "Something Went Wrong. Please Try again later."
				if let errorData = DataHelper.object(data) as? [String: Any]{
					if let desc = errorData["description"] as? String{
						errMsg = desc
						completion(false, errMsg, nil)
						return
					}
				}else{
					OTPLog.log(level:.warning, info:"response from auth0 server for reset password is failed, invalid error json data")
				}
				OTPLog.log(level:.warning, info:"response from auth0 server for reset password is failed, \(err.localizedDescription)")
				completion(false, errMsg, nil)
				return
			}
			var response = "we have just sent an email, for reset password."
   /// Data: data, encoding: .utf8
   /// Initializes a new instance.
   /// - Parameters:
   ///   - data: data
   ///   - encoding: .utf8
			if let responseString = String.init(data: data, encoding: .utf8){
				response = responseString
			}
			completion(true, "", response)
		}
	}
}
