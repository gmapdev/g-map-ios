//
//  APIEndpointProvider.swift
//

import Foundation


struct APIEndPoint {
	var method: String
	var endpoint: String
}

enum NotificationEndPoint {
	case sendVerificationCode
	case verifySMSCode
	case createTripNotification
	case updateTripNotification
	case retrieveTripNotification
	case deleteTripItem
    case checkItinerary
	
 /// Url
 /// - Returns: APIEndPoint
 /// Url.
	func url() -> APIEndPoint {
		switch self{
		case .sendVerificationCode: return APIEndPoint(method:"GET", endpoint:"/api/secure/user/:userId/verify_sms/:phonenumber")
		case .verifySMSCode: return APIEndPoint(method:"POST", endpoint:"/api/secure/user/:userId/verify_sms/:smsCode")
		case .createTripNotification: return APIEndPoint(method:"POST", endpoint:"/api/secure/monitoredtrip")
		case .updateTripNotification: return APIEndPoint(method:"PUT", endpoint:"/api/secure/monitoredtrip")
		case .retrieveTripNotification: return APIEndPoint(method:"GET", endpoint:"/api/secure/monitoredtrip")
		case .deleteTripItem: return APIEndPoint(method:"DELETE", endpoint:"/api/secure/monitoredtrip")
        case .checkItinerary: return APIEndPoint(method: "POST", endpoint: "/api/secure/monitoredtrip/checkitinerary")
		}
	}
}

enum TripEndPoint {
	case retrieveTripPlan
	case busInfo
    case realTimeBus
    
 /// Url
 /// - Returns: APIEndPoint
 /// Url.
	func url() -> APIEndPoint {
		switch self {
		case .retrieveTripPlan: return APIEndPoint(method:"GET", endpoint:"/otp2/routers/default/plan")
        case .busInfo: return APIEndPoint(method: "GET", endpoint: "/otp2/routers/default/index/routes/{BUS_NUMBER}/vehicles")
        case .realTimeBus: return APIEndPoint(method: "GET", endpoint: "/otp/routers/default/index/graphql")
		}
	}
}

enum UserAccountEndPoint {
	case retrieveUserInfo
	case verificationEmail
	case updateUserInfo
	case createUserInfo
	case deleteUserInfo
    case getDependentsMobilityProfile
	
	
 /// Url
 /// - Returns: APIEndPoint
 /// Url.
	func url() -> APIEndPoint {
		switch self{
		case .retrieveUserInfo: return APIEndPoint(method:"GET", endpoint:"/api/secure/user/fromtoken")
		case .verificationEmail: return APIEndPoint(method: "GET", endpoint: "/api/secure/user/verification-email")
		case .updateUserInfo: return APIEndPoint(method: "PUT", endpoint: "/api/secure/user/:userId")
		case .createUserInfo: return APIEndPoint(method: "POST", endpoint: "/api/secure/user")
		case .deleteUserInfo: return APIEndPoint(method: "DELETE", endpoint: "/api/secure/user/:userId")
        case .getDependentsMobilityProfile : return APIEndPoint(method: "GET", endpoint: "/api/secure/user/getdependentmobilityprofile?dependentuserids=")
		}
	}
}

enum SurveyEndPoint {
    case openPushSurvey
    
    /// Url
    /// - Returns: APIEndPoint
    /// Url.
    func url() -> APIEndPoint {
        switch self {
        case .openPushSurvey: return APIEndPoint(method: "GET", endpoint: "/api/trip-survey/open")
        }
    }
    
}
