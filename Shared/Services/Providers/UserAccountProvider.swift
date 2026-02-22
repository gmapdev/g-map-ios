//
//  UserAccountProvider.swift
//

import Foundation
import Combine
import Auth0


struct FavouriteLocation: Codable, Hashable {
    var id = UUID()
	var address: String
	var icon: String
	var lat: Double
	var lon: Double
	var name: String
	var type: String
    
    /// Hash.
    /// - Parameters:
    ///   - into: Parameter description
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
	
	private enum CodingKeys: String, CodingKey {
		case address, icon, lat, lon, name, type
	}
}

struct OTPUserInfoResponse: Codable {
	var auth0UserId: String
	var dateCreated: Int64
	var email: String
	var hasConsentedToTerms: Bool
	var id: String
	var isDataToolsUser: Bool
	var isPhoneNumberVerified: Bool
	var lastUpdated: Int64
	var notificationChannel: String
	var phoneNumber: String
	var savedLocations: [FavouriteLocation]?
	var storeTripHistory: Bool
    var pushDevices: Int
    var mobilityProfile : OTPUserMobilityProfile?
    var relatedUsers : [RelatedUser]?
    var dependents: [String]?
}

struct OTPUserInfo: Codable {
	var id: String?
	var auth0UserId: String
	var email: String
	var hasConsentedToTerms: Bool
	var notificationChannel: String
	var phoneNumber: String
	var savedLocations: [FavouriteLocation]?
	var storeTripHistory: Bool
    var isPhoneNumberVerified: Bool
    var mobilityProfile : OTPUserMobilityProfile?
    var relatedUsers : [RelatedUser]?
}

struct VerificationInfo: Codable {
	var created_at: String
	var id: String
	var status: String
	var type: String
}

struct RelatedUser : Codable{
    var email : String?
    var status : String?
    var acceptKey: String?
    var nickname : String?
}

struct DependentUser : Codable {
    let userId : String
    let mobilityMode : String
    let email : String
    let name : String?
}

class UserAccountProvider: BaseProvider {
	
	@Inject var loginAuthProvider: LoginAuthProvider
	
 /// Delete o t p user info.
 /// - Parameters:
 ///   - completion: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)
	func deleteOTPUserInfo(completion:@escaping (Bool, String?)->Void) {
		let userId = loginUserId()
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.deleteUserInfo.url().endpoint.replacingOccurrences(of: ":userId", with: userId)
		let requestMethod = UserAccountEndPoint.deleteUserInfo.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<OTPUserInfoResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
				switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "delete otp user info failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				completion(result.success, "Unknown error")
			}
			.store(in: &anyCancellables)
		}
	}
	
 /// Retrieve o t p user info.
 /// - Parameters:
 ///   - completion: Parameter description
 ///   - OTPUserInfoResponse?: Parameter description
 /// - Returns: Void)
	func retrieveOTPUserInfo(completion:@escaping (Bool, OTPUserInfoResponse?)->Void){
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.retrieveUserInfo.url().endpoint
		let requestMethod = UserAccountEndPoint.retrieveUserInfo.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			if let loginInfo = AppSession.shared.loginInfo, !loginInfo.emailIsVerified{
				request.addValue("Bearer " + (AppSession.shared.loginInfo?.token ?? ""), forHTTPHeaderField: "Authorization")
			}
			let publisher:AnyPublisher<APIAccessResponse<OTPUserInfoResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "Retrieve User failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				completion(result.success, result.value)
			}
			.store(in: &anyCancellables)
		}
	}
	
 /// Update o t p user info.
 /// - Parameters:
 ///   - userInfo: Parameter description
 ///   - forCreation: Parameter description
 ///   - completion: Parameter description
 ///   - OTPUserInfoResponse?: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)?)
	func updateOTPUserInfo(userInfo: OTPUserInfo, forCreation: Bool = false, completion:((Bool, OTPUserInfoResponse?, String?)->Void)?){
		let apiAccessProvider = APIAccessProvider()
		var requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.updateUserInfo.url().endpoint.replacingOccurrences(of: ":userId", with: userInfo.id ?? "")
		var requestMethod = UserAccountEndPoint.updateUserInfo.url().method
		if forCreation {
			requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.createUserInfo.url().endpoint
			requestMethod = UserAccountEndPoint.createUserInfo.url().method
		}
		
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			var reqJSONData: Data? = nil
			do {
				reqJSONData = try JSONEncoder().encode(userInfo)
			}
			catch{
				let errorMessage = "\(error)"
				completion?(false, nil, errorMessage)
				return
			}
			request.httpBody = reqJSONData
			if let loginInfo = AppSession.shared.loginInfo, !loginInfo.emailIsVerified{
				request.addValue("Bearer " + (AppSession.shared.loginInfo?.token ?? ""), forHTTPHeaderField: "Authorization")
			}
			
			let publisher:AnyPublisher<APIAccessResponse<String>, Error> = apiAccessProvider.runForPlainText(request)
			
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "Retrieve User failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
					
					if let jsonResult = result.value,
						let jsonObj: [String: Any] = DataHelper.convertToObject(jsonString: jsonResult){
						var auth0UserId = jsonObj["auth0UserId"] as? String ?? ""
						if(auth0UserId.count <= 0){
							auth0UserId = jsonObj["sub"] as? String ?? ""
						}
						let dateCreated = jsonObj["dateCreated"] as? Int64 ?? 0
						let email = jsonObj["email"] as? String ?? ""
						let hasConsentedToTerms = jsonObj["hasConsentedToTerms"] as? Bool ?? false
						let id = jsonObj["id"] as? String ?? ""
						let isDataToolsUser = jsonObj["isDataToolsUser"] as? Bool ?? false
						let isPhoneNumberVerified = jsonObj["isPhoneNumberVerified"] as? Bool ?? false
						let lastUpdated = jsonObj["lastUpdated"] as? Int64 ?? 0
						let notificationChannel = jsonObj["notificationChannel"] as? String ?? ""
						let phoneNumber = jsonObj["phoneNumber"] as? String ?? ""
						let storeTripHistory = jsonObj["storeTripHistory"] as? Bool ?? false
                        let pushDevices = jsonObj["pushDevices"] as? Int ?? 0
						
                        let userInfo = OTPUserInfoResponse(auth0UserId: auth0UserId, dateCreated: dateCreated, email: email, hasConsentedToTerms: hasConsentedToTerms, id: id, isDataToolsUser: isDataToolsUser, isPhoneNumberVerified: isPhoneNumberVerified, lastUpdated: lastUpdated, notificationChannel: notificationChannel, phoneNumber: phoneNumber, storeTripHistory: storeTripHistory, pushDevices: pushDevices, mobilityProfile: MobileQuestionnairViewModel.shared.selectedMobilityProfile)
						completion?(result.success, userInfo, nil)
					}else{
						completion?(false, nil, nil)
					}

			}
			.store(in: &anyCancellables)
		}
	}
	
 /// Resent verification.
 /// - Parameters:
 ///   - email: Parameter description
	func resentVerification(email: String){
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.verificationEmail.url().endpoint
		let requestMethod = UserAccountEndPoint.verificationEmail.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			if let loginInfo = AppSession.shared.loginInfo, !loginInfo.emailIsVerified{
				request.addValue("Bearer " + (AppSession.shared.loginInfo?.token ?? ""), forHTTPHeaderField: "Authorization")
			}
			let publisher:AnyPublisher<APIAccessResponse<VerificationInfo>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "Retrieve User failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				if result.success {
					AlertManager.shared.presentAlert(message: "The email verification message has been resent.")
				}else{
                    AlertManager.shared.presentAlert(message: "Failed to resent verification code. Please try again".localized())
				}
			}
			.store(in: &anyCancellables)
		}
	}
	
 /// Verify email.
 /// - Parameters:
 ///   - completion: Parameter description
 ///   - String: Parameter description
 /// - Returns: Void)
	func verifyEmail(completion:@escaping (Bool, String)->Void){
		guard let accessToken = loginAuthProvider.getToken() else {
			completion(false, "no access token")
			return
		}
        loginAuthProvider.getAuth0UserInfo(token: accessToken) { success, errMsg, info in
            if success{
                if let userInfo = info{
                    let loginInfo = LoginInfo(email: userInfo.email ?? userInfo.nickname ?? "",
                                              token: accessToken,
                                              expire: self.loginAuthProvider.expiresIn ?? 0,
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
                    completion(userInfo.emailVerified ?? false, "")
                }
            } else{
                completion(false, errMsg)
            }
        }
	}
	
 /// Store user info to server.
 /// - Parameters:
 ///   - completion: Parameter description
 /// - Returns: Void)? = nil)
	func storeUserInfoToServer(completion:((Bool)->Void)? = nil){
		guard var loginInfo = AppSession.shared.loginInfo else {
			completion?(false)
			return
		}
        loginInfo.notificationChannel = ProfileManager.shared.pubNotificationType.joined(separator: ",")
		
		loginInfo.phoneNumber = ProfileManager.shared.pubNotificationPhoneNumber
        
        let mobilityProfile = FeatureConfig.shared.enable_mobile_questionairs ? MobileQuestionnairViewModel.shared.selectedMobilityProfile : nil
        
        let relatedUser = TravelCompanionsViewModel.shared.pubCompanions
        
		let newOTPUser = OTPUserInfo(id:loginInfo.id,
									 auth0UserId: loginInfo.auth0UserId,
									 email: loginInfo.email,
									 hasConsentedToTerms: loginInfo.hasConsentedToTerms,
									 notificationChannel: loginInfo.notificationChannel,
									 phoneNumber: loginInfo.phoneNumber,
									 savedLocations: loginInfo.savedLocations,
                                     storeTripHistory: loginInfo.storeTripHistory,
                                     isPhoneNumberVerified: loginInfo.phoneVerified,
                                     mobilityProfile: mobilityProfile,
                                     relatedUsers: relatedUser)
		var forCreation = true
		if let userId = loginInfo.id, userId.count > 0 { forCreation = false }
		 
		updateOTPUserInfo(userInfo: newOTPUser, forCreation: forCreation) { success, otpUserResponse, errorMessage in
			if success {
				AppSession.shared.loginInfo?.id = otpUserResponse?.id
				DispatchQueue.main.async {
					completion?(true)
				}
			}else{
                AlertManager.shared.presentAlert(message: "Failed to save user information. %1".localized((errorMessage ?? "")))
				completion?(false)
			}
		}
    }
    /// Get dependents mobility profile.
    /// - Parameters:
    ///   - dependentIds: Parameter description
    ///   - completion: Parameter description
    ///   - [DependentUser]?: Parameter description
    /// - Returns: Void)
    func getDependentsMobilityProfile(dependentIds: String, completion:@escaping (Bool, [DependentUser]?)->Void){
        let apiAccessProvider = APIAccessProvider()
        let requestURL = apiAccessProvider.baseURL + UserAccountEndPoint.getDependentsMobilityProfile.url().endpoint + dependentIds
        let requestMethod = UserAccountEndPoint.retrieveUserInfo.url().method
        if let requestUrl = URL(string: requestURL) {
            var request = URLRequest(url: requestUrl)
            request.httpMethod = requestMethod
            if let loginInfo = AppSession.shared.loginInfo, !loginInfo.emailIsVerified{
                request.addValue("Bearer " + (AppSession.shared.loginInfo?.token ?? ""), forHTTPHeaderField: "Authorization")
            }
            let publisher:AnyPublisher<APIAccessResponse<[DependentUser]>, Error> = apiAccessProvider.run(request)
            publisher.sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    OTPLog.log(level: .error, info: "Retrieve User failed: \(error)")
                case .finished:
                    OTPLog.log(level: .info, info: "Complete Sink")
                    break
                }
            }) { (result) in
                completion(result.success, result.value)
            }
            .store(in: &anyCancellables)
        }
    }
    
}
