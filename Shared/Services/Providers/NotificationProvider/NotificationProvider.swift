//
//  NotificationProvider.swift
//

import Foundation
import Combine
import SwiftUI

class NotificationProvider: BaseProvider {
	
 /// Verify s m s code.
 /// - Parameters:
 ///   - smsCode: Parameter description
 ///   - completion: Parameter description
 ///   - String: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)
	func verifySMSCode(smsCode: String, completion:@escaping (Bool, String, String?)->Void) {
		let userId = loginUserId()
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.verifySMSCode.url().endpoint
						.replacingOccurrences(of: ":userId", with: userId)
						 .replacingOccurrences(of: ":smsCode", with: smsCode)
		let requestMethod = NotificationEndPoint.verifySMSCode.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<SMSVerificationResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "verify SMS Code failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				completion(result.success, result.value?.status ?? "pending", "Request Error")
			}
			.store(in: &anyCancellables)
		}
	}

 /// Send s m s verification code.
 /// - Parameters:
 ///   - phonenumber: Parameter description
 ///   - completion: Parameter description
 ///   - String?: Parameter description
 /// - Returns: Void)
	func sendSMSVerificationCode(phonenumber: String, completion:@escaping (Bool, String?)->Void) {
		let userId = loginUserId()
		let finalPhonenumber = phonenumber.urlEncode().replacingOccurrences(of: "+", with: "%2B")
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.sendVerificationCode.url().endpoint
						.replacingOccurrences(of: ":userId", with: userId)
						 .replacingOccurrences(of: ":phonenumber", with: finalPhonenumber)
		let requestMethod = NotificationEndPoint.sendVerificationCode.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<SMSVerificationResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "send SMS verification code failed: \(error)")
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
	
 /// Remove trip item.
 /// - Parameters:
 ///   - tripId: Parameter description
 ///   - completion: Parameter description
 /// - Returns: Void)
	func removeTripItem(tripId:String, completion:@escaping (Bool)->Void){
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.deleteTripItem.url().endpoint + "/" + tripId
		let requestMethod = NotificationEndPoint.deleteTripItem.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<TripNotificationResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "delete trip notification failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				completion(result.success)
			}
			.store(in: &anyCancellables)
		}
	}
	
 /// Retrieve my trip list.
 /// - Parameters:
 ///   - offset: Parameter description
 ///   - completion: Parameter description
 ///   - TripRequestResponse?: Parameter description
 /// - Returns: Void)
	func retrieveMyTripList(offset:Int, completion:@escaping (Bool, TripRequestResponse?)->Void){
		let apiAccessProvider = APIAccessProvider()
		let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.retrieveTripNotification.url().endpoint + "?offset=\(offset)"
		let requestMethod = NotificationEndPoint.retrieveTripNotification.url().method
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
			let publisher:AnyPublisher<APIAccessResponse<TripRequestResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "retrieve trip notification failed: \(error)")
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
	
    /// Update notification.
    /// - Parameters:
    ///   - tripNotification: Parameter description
    ///   - forCreation: Parameter description
    ///   - completion: Parameter description
    ///   - String?: Parameter description
    /// - Returns: Void)
    func updateNotification(tripNotification: [String: Any], forCreation: Bool = false,  completion:@escaping (Bool, String?)->Void){
		let apiAccessProvider = APIAccessProvider()
		var requestURL = apiAccessProvider.baseURL + NotificationEndPoint.updateTripNotification.url().endpoint + "/" + (tripNotification["id"] as? String ?? "")
		var requestMethod = NotificationEndPoint.updateTripNotification.url().method
		if forCreation {
			requestURL = apiAccessProvider.baseURL + NotificationEndPoint.createTripNotification.url().endpoint
			requestMethod = NotificationEndPoint.createTripNotification.url().method
		}
		if let requestUrl = URL(string: requestURL) {
			var request = URLRequest(url: requestUrl)
			request.httpMethod = requestMethod
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			do{
                let requestData = try JSONSerialization.data(withJSONObject: tripNotification, options: .prettyPrinted)
				request.httpBody = requestData
			}catch{
				OTPLog.log(level: .error, info: "No request payload can be found \(error)")
				completion(false, "No request payload can be found")
			}
			
			let publisher:AnyPublisher<APIAccessResponse<TripNotificationResponse>, Error> = apiAccessProvider.run(request)
			publisher.sink(receiveCompletion: { result in
					switch result {
					case .failure(let error):
						OTPLog.log(level: .error, info: "update notification failed: \(error)")
					case .finished:
						OTPLog.log(level: .info, info: "Complete Sink")
						break
					}
				}) { (result) in
				var errorMessage: String? = nil
				if !(result.success) {
					errorMessage = "Operation Failed! Unkown error"
					do {
						if let data = result.rawData,
						   let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
						   let message = jsonObject["message"] as? String {
							errorMessage = message
						}
					}catch{
						OTPLog.log(level: .error, info: "failed to \(forCreation ? "create" : "update") the trip item \(error)")
					}
				}
				completion(result.success, errorMessage)
			}
			.store(in: &anyCancellables)
		}
	}
    
    /// Check itinerary.
    /// - Parameters:
    ///   - tripNotificationResponse: Parameter description
    ///   - completion: Parameter description
    ///   - CheckItineraryResponse?: Parameter description
    /// - Returns: Void)
    func checkItinerary(tripNotificationResponse: TripNotificationResponse, completion:@escaping (Bool, CheckItineraryResponse?)->Void){
        let apiAccessProvider = APIAccessProvider()
        let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.checkItinerary.url().endpoint
        let requestMethod = NotificationEndPoint.checkItinerary.url().method
        if let requestUrl = URL(string: requestURL) {
            var request = URLRequest(url: requestUrl)
            request.httpMethod = requestMethod
            do{
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(tripNotificationResponse)
                request.httpBody = jsonData
            }catch{
                OTPLog.log(level: .error, info: "No request payload can be found \(error)")
                completion(false, nil)
            }
            
            let publisher:AnyPublisher<APIAccessResponse<CheckItineraryResponse>, Error> = apiAccessProvider.run(request)
            publisher.sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        OTPLog.log(level: .error, info: "update notification failed: \(error)")
                    case .finished:
                        OTPLog.log(level: .info, info: "Complete Sink")
                        break
                    }
                }) { (result) in
                if !(result.success) {
                    do {
                        if let data = result.rawData,
                           let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                           let message = jsonObject["message"] as? String {
                        }
                    }catch{
                        OTPLog.log(level: .error, info: "failed to check itinerary the trip item \(error)")
                    }
                }
                completion(result.success, result.value)
            }
            .store(in: &anyCancellables)
        }
        
    }
    
    /// Check days availibility.
    /// - Parameters:
    ///   - jsonItinerary: Parameter description
    ///   - completion: Parameter description
    ///   - CheckItineraryResponse?: Parameter description
    /// - Returns: Void)
    func checkDaysAvailibility(jsonItinerary: [String: Any], completion:@escaping (Bool, CheckItineraryResponse?)->Void){
        let apiAccessProvider = APIAccessProvider()
        let requestURL = apiAccessProvider.baseURL + NotificationEndPoint.checkItinerary.url().endpoint
        let requestMethod = NotificationEndPoint.checkItinerary.url().method
        if let requestUrl = URL(string: requestURL) {
            var request = URLRequest(url: requestUrl)
            request.httpMethod = requestMethod
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do{
                let requestData = try JSONSerialization.data(withJSONObject: jsonItinerary, options: .prettyPrinted)
                request.httpBody = requestData
            }catch{
                OTPLog.log(level: .error, info: "No request payload can be found \(error)")
                completion(false, nil)
            }
            
            let publisher:AnyPublisher<APIAccessResponse<CheckItineraryResponse>, Error> = apiAccessProvider.run(request)
            publisher.sink(receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        OTPLog.log(level: .error, info: "update notification failed: \(error)")
                    case .finished:
                        OTPLog.log(level: .info, info: "Complete Sink")
                        break
                    }
                }) { (result) in
                if !(result.success) {
                    do {
                        if let data = result.rawData,
                           let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                           let message = jsonObject["message"] as? String {
                        }
                    }catch{
                        OTPLog.log(level: .error, info: "failed to check itinerary the trip item \(error)")
                    }
                }
                completion(result.success, result.value)
            }
            .store(in: &anyCancellables)
        }
        
    }
}
