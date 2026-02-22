//
//  APIManager.swift
//

import Foundation
import UIKit

/// The server returns the object as below, need to parse it
public struct RouteCandidateItem {
	public var isFavorite: Bool? = false			// This is used to show/hide the star button when the user successfully saved the route. every time, if there is new search, the flag will be false
	public var legsInstructions: [String]?
	public var legsLengthsKM: [Double]?
	public var lengthKM: Double?
	public var polylines: [String]?
	public var travelTimeMins: Double?
	public var travelTimeMinsNoTraffic: Double?
	
	// route closure used parameters
	public var numOfRoadClosureMatchDirection: Int?
	public var numOfRoadClosureNotMatchDirection: Int?
	
	public var start_lat: Double?
	public var start_lon: Double?
	public var start_address: String?
	
	public var end_lat: Double?
	public var end_lon: Double?
	public var end_address: String?
	
	
	// route payload for holding extra object for later use. it owns a copy of this Route Candidate Item, it only take effect for IBI Route Search
	var payload: [String: Any]?
}

public struct RouteSearchItem: Codable{
	public var no_tolls = false
	public var no_hwys = false
	public var start_lat: Double?
	public var start_lng: Double?
	public var start_address: String?
	public var end_lat: Double?
	public var end_lng: Double?
	public var end_address:String?
	public var mode: String?
	public var provider = "here"
	public var languageCode: String?
	public var unit: String?
	public var way_points:[[Double]]
}

/// List all the errors that will or may happens during the runtime
internal enum OTPAPIError: Error {
	
	/// Error List
	case noAPIKey
	
	/// Can not parse URL
	case notValidURL
	
	/// Url response is empty
	case responseIsEmpty
	
	/// If the server request failed. we can use this one
	case requestFailed
	
	/// Unknown response type of the request
	case unknownResponseType
	
	/// URL Session is not created.
	case urlSessionIsNotInitialized
	
	/// Get the localized message
	var localizedMessage: String {
		switch (self) {
			case .noAPIKey:
				return "APIKey can not be empty"
			case .notValidURL:
				return "URL is not valid"
			case .responseIsEmpty:
				return "Response data is empty"
			case .requestFailed:
				return "Server request failed"
			case .unknownResponseType:
				return "Unknown response and status code"
			case .urlSessionIsNotInitialized:
    /// Initializes a new instance.
				return "Session manager is not initialzied"
		}
	}
}


	
/** Callback function for the network request
 - parameter Data?: raw response object in data format
 - parameter Error?: error object, if the request is failed.
 - parameter URLResponse?: the response object from the server
 */
public typealias APICallback = (Data?, Error?, URLResponse?) -> Void

/// This is used to make the network request for all the TravelIQ related APIs
class OTPAPIRequest: NSObject, URLSessionDelegate {
	
	/// Standard RESTFul API method
	public enum RequestMethod: String
	{
		/// GET Method
		case get = "GET"
		
		/// POST Method
		case post = "POST"
		
		/// DELETE Method
		case delete = "DELETE"
		
		/// PUT Method
		case put = "PUT"
		
		/// PATCH Method
		case patch = "PATCH"
	}
	
	/// Define the parameters format when send the request to the server
	public enum ParameterFormat: String
	{
		/// PATH Paramters
		case PathParameter = "PathParameter"
		
		/// JSON Body Parameters
		case JSON = "JSON"
		
		/// Encoded form url parameters
		case FormURLEncoded = "FormURLEncoded"
	}
	
	/// Pre-defined header fields, we can put the predefined values, in this place.
	#if !targetEnvironment(macCatalyst)
	public var globalHeaders = ["device_id":AppConfig.shared.deviceId(),
								"Locale":OTPUtils.languageCode(),
								"device_os":"iOS_\(UIDevice.current.systemVersion)"]
	#else
	public var globalHeaders = ["device_id":AppConfig.shared.deviceId(),
								"Locale":OTPUtils.languageCode(),
								"device_os":"iOS_Mac_\(UIDevice.current.systemVersion)"]
	#endif
	
	/// Detaul timeout for all the request in seconds
	public var defaultTimeout: Double = 60
	
	/// Apple build session manager for download.
	var urlSessionManager: URLSession?
	
	/// Indicate whether we want to ignore and disable the ssl certificate for the request
	public var urlIgnoreSSLCertificate: Bool = false
	
	/// Request queues to hold the request, and make the operation sequential.
	var requestQueue = OperationQueue()
	
 /// Initializes a new instance.

	/// Setup the parameters and initialize the class
	public override init()
	{
		super.init()
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = defaultTimeout
		configuration.timeoutIntervalForResource = defaultTimeout
		urlSessionManager = URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: requestQueue)
	}
	
	/**
	 Centuralized function call: most individual REST api call will be go through this function, this is used to download the resource from remote. It includes the image compression as well. if we specify the withJPGCompress parameters
	 - parameter fromURL: The URI where we want to download the file.
	 - parameter toLocalPath: The path where we are going to store the file to the app.
	 - parameter withJPGCompress: This indicates whether we want to treat the download file as a image and compress it. if it is false, the result will keep the original form
	 - Returns: (Bool)->Void
	 */
 /// Download file.
 /// - Parameters:
 ///   - fromURL: Parameter description
 ///   - toLocalPath: Parameter description
 ///   - withJPGCompress: Parameter description
 ///   - completion: Parameter description
 /// - Returns: Void)?)
	public func downloadFile(fromURL: String, toLocalPath: String, withJPGCompress: Bool = false, completion:((Bool)->Void)?) {
		guard let url = URL(string: fromURL) else {
			OTPLog.log(level: .error, info: "can not convert the fromURL to \(fromURL)")
			completion?(false)
			return
		}
		
		var request = URLRequest(url: url)
		for (key, value) in globalHeaders {
			request.addValue(value, forHTTPHeaderField: key)
		}
		
		if let urlSessionManager = urlSessionManager {
			let dataTask = urlSessionManager.dataTask(with: request) { (data, response, error) in
				if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode>=200 &&  httpResponse.statusCode<300 {
					if let data = data, data.count > 0 {
						do{
							let toURL = URL(fileURLWithPath: toLocalPath)
							var writableData = data
							if withJPGCompress {
								if let image = UIImage(data: data), let compressedData = image.jpegData(compressionQuality: 0.5) {
									writableData = compressedData
								}else{
									completion?(false)
									return
								}
							}
							
							try writableData.write(to: toURL)
							completion?(true)
							return
						}catch let error as NSError {
							OTPLog.log(level: .error, info: "copy file from temp area to destination failed, \(error.description)")
						}
					}
				}
				completion?(false)
			}
			dataTask.resume()
		}
		else
		{
			OTPLog.log(level: .error, info: "url session manager is nil. request can not be made")
			completion?(false)
		}
	}
	
	/// This function is used to convert the data from the response to a json object
 /// Object.
 /// - Parameters:
 ///   - data: Data
 /// - Returns: Any?
	public func object(_ data: Data) -> Any?{
		var obj: Any?
		do{
			obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
		}catch let error as NSError {
			OTPLog.log(level: .error, info: "json serialization error: \(error.description)")
		}
		return obj
	}
	

 /// Request.
 /// - Parameters:
 ///   - method: Parameter description
 ///   - path: Parameter description
 ///   - headers: Parameter description
 ///   - format: Parameter description
 ///   - queue: Parameter description
 ///   - timeout: Parameter description
 ///   - callback: Parameter description
	public func request(method: RequestMethod, path:String, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) {
		let _ :[String]? = self.requestRestAPI(method: method, path: path, params: nil, headers: headers, format:format, queue: queue, timeout: timeout) { (data, error, response) in
			callback(data, error, response)
		}
	}
	
 /// Request.
 /// - Parameters:
 ///   - method: Parameter description
 ///   - path: Parameter description
 ///   - params: Parameter description
 ///   - headers: Parameter description
 ///   - format: Parameter description
 ///   - queue: Parameter description
 ///   - timeout: Parameter description
 ///   - callback: Parameter description
	public func request(method: RequestMethod, path:String, params: [String]?, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) {
		let _ :[String]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format:format, queue: queue, timeout: timeout) { (data, error, response) in
			callback(data, error, response)
		}
	}
	
 /// Request.
 /// - Parameters:
 ///   - method: Parameter description
 ///   - path: Parameter description
 ///   - params: Parameter description
 ///   - headers: Parameter description
 ///   - format: Parameter description
 ///   - queue: Parameter description
 ///   - timeout: Parameter description
 ///   - callback: Parameter description
	public func request(method: RequestMethod, path:String, params: [String: Any]?, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) {
		let _ :[String: Any]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format:format, queue: queue, timeout: timeout) { (data, error, response) in
			callback(data, error, response)
		}
	}
	
 /// Request.
 /// - Parameters:
 ///   - method: Parameter description
 ///   - path: Parameter description
 ///   - params: Parameter description
 ///   - headers: Parameter description
 ///   - format: Parameter description
 ///   - queue: Parameter description
 ///   - timeout: Parameter description
 ///   - callback: Parameter description
	public func request(method: RequestMethod, path:String, params: [[String: Any]]?, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) {
		let _ :[[String:Any]]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format:format, queue: queue, timeout: timeout) { (data, error, response) in
			callback(data, error, response)
		}
	}
	
 /// Multipart request.
 /// - Parameters:
 ///   - method: Parameter description
 ///   - path: Parameter description
 ///   - fileName: Parameter description
 ///   - file: Parameter description
 ///   - params: Parameter description
 ///   - headers: Parameter description
 ///   - queue: Parameter description
 ///   - timeout: Parameter description
 ///   - callback: Parameter description
	public func multipartRequest(method: RequestMethod, path: String, fileName: String?, file: Data?, params:[String: Any]?, headers: [String: String]?, queue: DispatchQueue = DispatchQueue.global(), timeout: Double? = nil, callback: @escaping APICallback){

		guard let url = URL(string: path) else {
			OTPLog.log(level: .error, info: "can not convert the path to url \(path) for multipart request")
			callback(nil, OTPAPIError.notValidURL, nil)
			return
		}
		
		// Prepare the headers for the request
		var request = URLRequest(url: url)
		for (key, value) in globalHeaders {
			request.addValue(value, forHTTPHeaderField: key)
		}
		if let reqHeaders = headers {
			for (key, value) in reqHeaders {
				request.addValue(value, forHTTPHeaderField: key)
			}
		}
		
		// Prepare the request method
		var requestMethod = "GET"
		switch (method){
			case .delete:
				requestMethod = "DELETE"
			case .patch:
				requestMethod = "PATCH"
			case .post:
				requestMethod = "POST"
			case .put:
				requestMethod = "PUT"
			default:
				requestMethod = "GET"
		}
		request.httpMethod = requestMethod
		
		// Multipart form preparsion
		let boundary = "-- IBIGroup Mobile Team --"
		let contentType = "multipart/form-data;boundary=\(boundary)"
		request.addValue(contentType, forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		
		var body = Data()
		
		// File Body
		if let fileData = file {
			var file_name = "upload_file"
			if let name = fileName {file_name = name}
			if let paramData = "\r\n--\(boundary)\r\n".data(using: .utf8) { body.append(paramData) }
			if let paramData = "Content-Disposition: form-data; name=\"file\"; filename=\"\(file_name)\"\r\n".data(using: .utf8) { body.append(paramData) }
			if let paramData = "Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8) { body.append(paramData) }
			body.append(fileData)
		}
		
		// Extra Parameters
		if let parameters = params {
			for key in parameters.keys {
				
				if let paramData = "\r\n--\(boundary)\r\n".data(using: .utf8) { body.append(paramData) }
				
				var value = ""
				
				if let fieldValue = parameters[key] as? String {
					value = fieldValue
				}
				
				if let paramData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: .utf8) { body.append(paramData) }
			}
		}
		
		// End of the form
		if let paramData = "\r\n--\(boundary)--\r\n".data(using: .utf8) { body.append(paramData) }
		request.httpBody = body
		request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
		
		if let urlSessionManager = urlSessionManager {
			let dataTask = urlSessionManager.dataTask(with: request) { (data, response, error) in
				if let httpResponse = (response as? HTTPURLResponse) {
					let status = httpResponse.statusCode
					if status < 400 && status >= 200 {
						if let data = data {
							callback(data, nil, response)
						}else{
							OTPLog.log(level: .error,info: "multipart/form-data; response is empty, status code: \(status)")
							callback(nil, OTPAPIError.responseIsEmpty, response)
						}
					}else{
						OTPLog.log(level: .error,info: "multipart/form-data; request failed, status code: \(status)")
						callback(data, OTPAPIError.requestFailed, response)
					}
				}else{
					OTPLog.log(level: .error,info: "multipart/form-data; Unknown response type")
					callback(nil, OTPAPIError.unknownResponseType, response)
				}
			}
			dataTask.resume()
		}
		else
		{
   /// Initializes a new instance.
   /// - Parameters:
   ///   - level: .error

   ///   - info: "multipart/form-data; Url is not initialized."
			OTPLog.log(level: .error,info: "multipart/form-data; Url is not initialized.")
			callback(nil, OTPAPIError.urlSessionIsNotInitialized, nil)
		}
	}
	
	/**
	 centuralized function call: most individual REST api call will be go through this function
	 - parameter method: RESTFul API http request method
	 - parameter path: URI for the resource
	 - parameter params: the parameters that we want to pass to the request. either [String], or [String: Any] or [[String:Any]]
	 - parameter format: define what kind of parameter formats, we want to send to the server
	 - parameter queue: decide which queue need to use for the request.
	 - parameter timeout: use to control the timeout for only this request, if this value is not assigned, use the default timeout property value.
	 - Returns: (APIResult,APIError), original parameters
	 */
 /// Requests rest api.
 /// - Parameters:
 ///   - method: RequestMethod
 ///   - path: String
 ///   - params: T?
 ///   - headers: [String: String]?
 ///   - format: ParameterFormat = ParameterFormat.PathParameter
 ///   - queue: DispatchQueue = DispatchQueue.global(
 /// - Returns: T?
	private func requestRestAPI<T>(method: RequestMethod, path:String, params: T?, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) -> T? {

		guard let url = URL(string: path.trimmingCharacters(in: .whitespaces)) else {
			OTPLog.log(level: .error, info: "can not convert the path to url \(path)")
			callback(nil, OTPAPIError.notValidURL, nil)
			return nil
		}
		
		// Prepare the headers for the request
		var request = URLRequest(url: url)
		for (key, value) in globalHeaders {
			request.addValue(value, forHTTPHeaderField: key)
		}
		if let reqHeaders = headers {
			for (key, value) in reqHeaders {
				request.addValue(value, forHTTPHeaderField: key)
			}
		}
		
		// Prepare the request method
		var requestMethod = "GET"
		switch (method){
			case .delete:
				requestMethod = "DELETE"
			case .patch:
				requestMethod = "PATCH"
			case .post:
				requestMethod = "POST"
			case .put:
				requestMethod = "PUT"
			default:
				requestMethod = "GET"
		}
		request.httpMethod = requestMethod
		
		// Prepare the body parameter or url path parameter
		var bodyData: Data? = nil
		switch(format){
			case .JSON:
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				if let paramVals = params {
					do{
						bodyData = try JSONSerialization.data(withJSONObject: paramVals, options: .prettyPrinted)
					}catch{
						OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(paramVals)")
					}
				}
			
			case .FormURLEncoded:
				request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
				if let keyValPair = params as? [String: Any] {
					let result = keyValPair.map{ "\($0)=\($1)" }.joined(separator: "&")
					bodyData = result.data(using: .utf8)
				}
			
			case .PathParameter:
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				if let keyValPair = params as? [String: Any] {
					let result = keyValPair.map{ "\($0)=\($1)" }.joined(separator: "&")
					if result.count > 0 {
						let newURL = path + "?" + result
						request.url = URL(string: newURL)
					}
				}
		}
		request.httpBody  = bodyData
		if let bodyData = bodyData {
			request.setValue("\(bodyData.count)", forHTTPHeaderField: "Content-Length")
		}
		
		request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
		
		if let tout = timeout {
			request.timeoutInterval = tout
		}else{
			request.timeoutInterval = defaultTimeout
			urlSessionManager?.configuration.timeoutIntervalForRequest = defaultTimeout
			urlSessionManager?.configuration.timeoutIntervalForResource = defaultTimeout
		}
		
		if let urlSessionManager = urlSessionManager {
			let dataTask = urlSessionManager.dataTask(with: request) { (data, response, error) in
				if let httpResponse = (response as? HTTPURLResponse) {
					let status = httpResponse.statusCode
					if status < 400 && status >= 200 {
						if let data = data {
							callback(data, nil, response)
						}else{
							OTPLog.log(level: .error,info: "response is empty, status code: \(status)")
							callback(nil, OTPAPIError.responseIsEmpty, response)
						}
					}else{
						OTPLog.log(level: .error,info: "request failed, status code: \(status)")
						callback(data, OTPAPIError.requestFailed, response)
					}
				}else{
					OTPLog.log(level: .error,info: "Unknown response type")
					callback(nil, OTPAPIError.unknownResponseType, response)
				}
			}
			dataTask.resume()
		}
		else
		{
   /// Initializes a new instance.
   /// - Parameters:
   ///   - level: .error

   ///   - info: "Url is not initialized."
			OTPLog.log(level: .error,info: "Url is not initialized.")
			callback(nil, OTPAPIError.urlSessionIsNotInitialized, nil)
		}
		return nil
	}
	
	
	// MARK: URL Session Delegate
 /// Url session.
 /// - Parameters:
 ///   - session: URLSession
 ///   - challenge: URLAuthenticationChallenge
 ///   - completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?
 /// - Returns: Void)
	public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		if urlIgnoreSSLCertificate {
			if let trust = challenge.protectionSpace.serverTrust {
				let credential = URLCredential(trust: trust)
				completionHandler(.useCredential, credential)
			}else{
				completionHandler(.performDefaultHandling, nil)
			}
		}else{
			completionHandler(.performDefaultHandling, nil)
		}
	}
	
 /// Url session did finish events.
 /// - Parameters:
 ///   - forBackgroundURLSession: Parameter description
	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {}
 /// Url session.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - didBecomeInvalidWithError: Parameter description
	public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {}
}

class APIManager {
	
	/// shared is an instance which is used to make the network request
	static let shared : APIManager = {
		let mgr = APIManager()
		return mgr
	}()
	
	/// Stops.
	/// - Parameters:
	///   - minCoordinate: Parameter description
	///   - maxCoordinate: Parameter description
	///   - completion: Parameter description
	///   - _: Parameter description
	/// - Returns: Void)
	func stops(minCoordinate: Coordinate, maxCoordinate: Coordinate, completion: @escaping([Stop], _ error: Error?) -> Void) {
		let url = BrandConfig.shared.base_url + "/otp/routers/default/index/stops"

		guard let url = URL(string: url) else {
			OTPLog.log(level: .error, info: "can not convert the fromURL to \(url)")
			return
		}
		//
		let request = URLRequest(url: url)
		let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				OTPLog.log(level:.error, info: "can not decode the stops data, \(error)")
				completion([], error)
			}
			if let data = data {
				do{
					let stopList = try JSONDecoder().decode([Stop].self, from: data)
					completion(stopList, nil)
				}catch{
					OTPLog.log(level:.error, info: "can not decode the stops data, \(error)")
					completion([], error)
				}
			} else {
				completion([], error)
			}
		}
		dataTask.resume()
	}
	
	/// Force stop tracking.
	/// - Parameters:
	///   - tripId: Parameter description
	///   - completion: Parameter description
	/// - Returns: Void)
	func forceStopTracking(tripId: String, completion:@escaping (String?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/forciblyendtracking​"
		let params = ["tripId": tripId] as? [String: Any]
		var headers: [String : String] = [:]
		if let token = AppSession.shared.loginInfo?.token {
			headers = ["Authorization": "Bearer \(token)"]
		}
		
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"failed to force end report tracking location. no server response ")
				completion("failed to force end report tracking location. no server response ")
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for force ending reporting location is failed, \(err.localizedDescription)")
				guard let _ = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for forcing ending reporting location is failed, invalid error json data")
					completion("response from server for forcing ending reporting location is failed, invalid error json data")
					return
				}
				completion("response from server for forcing ending reporting location is failed, \(err.localizedDescription)")
				return
			}
			
			completion(nil)
		}
	}
	
	/// Stop report tracking.
	/// - Parameters:
	///   - journeyId: Parameter description
	///   - completion: Parameter description
	/// - Returns: Void)
	func stopReportTracking(journeyId: String, completion:@escaping (String?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/endtracking​"
		let params = ["journeyId": journeyId] as? [String: Any]
		var headers: [String : String] = [:]
		if let token = AppSession.shared.loginInfo?.token {
			headers = ["Authorization": "Bearer \(token)"]
		}
		
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"failed to end report tracking location. no server response ")
				completion("failed to end report tracking location. no server response ")
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for ending reporting location is failed, \(err.localizedDescription)")
				guard let _ = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for ending reporting location is failed, invalid error json data")
					completion("response from server for ending reporting location is failed, invalid error json data")
					return
				}
				completion("response from server for ending reporting location is failed, \(err.localizedDescription)")
				return
			}
			
			completion(nil)
		}
	}
	
	/// Request route.
	/// - Parameters:
	///   - tripId: Parameter description
	///   - locations: Parameter description
	///   - completion: Parameter description
	///   - String?: Parameter description
	/// - Returns: Void)
	func requestRoute(tripId: String, locations: [TrackingLocation], completion:@escaping (TrackingLocationResponse?, String?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/reroute"
		var loctionsArr = [[String: Any]]()
		do{
			let decodeData = try JSONEncoder().encode(locations)
			loctionsArr = try JSONSerialization.jsonObject(with: decodeData) as? [[String: Any]] ?? []
			
		}catch{
			OTPLog.log(level:.error, info: "Can not parse the locations information to valid data to send out")
		}
		let params = [
			"tripId": tripId,
			"locations": loctionsArr
		] as? [String: Any]
		var headers: [String : String] =  ["app_version":"V\(Bundle.main.fullVersion)",
										   "app_platform":"iOS_\(UIDevice.current.systemVersion)"]
		
		if let token = AppSession.shared.loginInfo?.token {
			headers["Authorization"] = "Bearer \(token)"
		}
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"reroute request failed. no server response ")
				completion(nil, "failed to get server response")
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for rerouting the trip is failed, \(err.localizedDescription)")
				guard let errResult = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for rerouting the trip is failed, invalid error json data")
					completion(nil, "Server returns error, can not parse error data")
					return
				}
				completion(nil, errResult["message"] as? String ?? "failed to track this trip")
				return
			}
			
			do{
				var trackingLocationRep = try JSONDecoder().decode(TrackingLocationResponse.self, from: data)
				if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
					if let itineraryData = jsonData["itinerary"] as? [String: Any] {
						let decoder = JSONDecoder()
						let itinerary = try decoder.decode(OTPItinerary.self, from: JSONSerialization.data(withJSONObject: itineraryData))
						trackingLocationRep.itinery = itinerary
					}
				}
				completion(trackingLocationRep, nil)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the Tracking Location Response, \(error)")
				completion(nil, "can not parse server response to get journey id")
			}
		}
	}
	
	/// Report location v2.
	/// - Parameters:
	///   - tripId: Parameter description
	///   - locations: Parameter description
	///   - completion: Parameter description
	/// - Returns: Void)
	func reportLocationV2(tripId: String, locations: [TrackingLocation], completion:@escaping (TrackingLocationResponse?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/track​"
		var loctionsArr = [[String: Any]]()
		do{
			let decodeData = try JSONEncoder().encode(locations)
			loctionsArr = try JSONSerialization.jsonObject(with: decodeData) as? [[String: Any]] ?? []
			
		}catch{
			OTPLog.log(level:.error, info: "Can not parse the locations information to valid data to send out")
		}
		let params = [
			"tripId": tripId,
			"locations": loctionsArr
		] as? [String: Any]
		var headers: [String : String] =  ["app_version":"V\(Bundle.main.fullVersion)",
										   "app_platform":"iOS_\(UIDevice.current.systemVersion)"]
		
		if let token = AppSession.shared.loginInfo?.token {
			headers["Authorization"] = "Bearer \(token)"
		}
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"failed to report tracking location. no server response ")
				completion(nil)
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for reporting location is failed, \(err.localizedDescription)")
				guard let _ = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for reporting location is failed, invalid error json data")
					completion(nil)
					return
				}
				completion(nil)
				return
			}
			
			do{
				let trackingLocationRep = try JSONDecoder().decode(TrackingLocationResponse.self, from: data)
				completion(trackingLocationRep)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the Tracking Location Response, \(error)")
				completion(nil)
			}
		}
	}
	
	/// Report location.
	/// - Parameters:
	///   - journeyId: Parameter description
	///   - locations: Parameter description
	///   - completion: Parameter description
	/// - Returns: Void)
	func reportLocation(journeyId: String, locations: [TrackingLocation], completion:@escaping (TrackingLocationResponse?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/updatetracking​"
		var loctionsArr = [[String: Any]]()
		do{
			let decodeData = try JSONEncoder().encode(locations)
			loctionsArr = try JSONSerialization.jsonObject(with: decodeData) as? [[String: Any]] ?? []
			
		}catch{
			OTPLog.log(level:.error, info: "Can not parse the locations information to valid data to send out")
		}
		let params = [
			"journeyId": journeyId,
			"locations": loctionsArr
		] as? [String: Any]
		var headers: [String : String] = [:]
		if let token = AppSession.shared.loginInfo?.token {
			headers = ["Authorization": "Bearer \(token)"]
		}
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"failed to report tracking location. no server response ")
				completion(nil)
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for reporting location is failed, \(err.localizedDescription)")
				guard let _ = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for reporting location is failed, invalid error json data")
					completion(nil)
					return
				}
				completion(nil)
				return
			}
			
			do{
				let trackingLocationRep = try JSONDecoder().decode(TrackingLocationResponse.self, from: data)
				completion(trackingLocationRep)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the Tracking Location Response, \(error)")
				completion(nil)
			}
		}
	}
	
	/// Activate route.
	/// - Parameters:
	///   - tripId: Parameter description
	///   - location: Parameter description
	///   - completion: Parameter description
	///   - String?: Parameter description
	/// - Returns: Void)
	func activateRoute(tripId: String, location: TrackingLocation, completion:@escaping (TrackingLocationResponse?, String?)->Void){
		let api = OTPAPIRequest()
		let path = BrandConfig.shared.base_url + "/api/secure/monitoredtrip/starttracking"
		let params = [
			//"dependentUserId": AppSession.shared.loginInfo?.auth0UserId ?? "n/a",
			"location": [
				"bearing": location.bearing ?? 0,
				"lat": location.lat ?? 0,
				"lon": location.lon ?? 0,
				"speed": location.speed ?? 0,
				"timestamp": location.timestamp ?? 0
			],
			"tripId": tripId
		] as? [String: Any]
		var headers: [String : String] = [:]
		if let token = AppSession.shared.loginInfo?.token {
			headers = ["Authorization": "Bearer \(token)"]
		}
		api.request(method: .post, path: path, params: params, headers: headers, format: .JSON){ data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot start activating route and report. no server response ")
				completion(nil, "failed to get server response")
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for activating the route is failed, \(err.localizedDescription)")
				guard let errResult = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for activating the route is failed, invalid error json data")
					completion(nil, "Server returns error, can not parse error data")
					return
				}
				completion(nil, errResult["message"] as? String ?? "failed to track this trip")
				return
			}
			
			do{
				let trackingLocationRep = try JSONDecoder().decode(TrackingLocationResponse.self, from: data)
				completion(trackingLocationRep, nil)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the Tracking Location Response, \(error)")
				completion(nil, "can not parse server response to get journey id")
			}
		}
	}
	
	/// Load all mode list.
	/// - Parameters:
	///   - url: Parameter description
	///   - completion: Parameter description
	/// - Returns: Void)
	func loadAllModeList(url: String, completion: @escaping([SearchMode]) -> Void){
		let api = OTPAPIRequest()
		api.request(method: .get, path: url, headers: [:]) { data, error, response in
			guard let data = data else {
				OTPLog.log(level:.info, info:"cannot receive the mode list response")
				completion([])
				return
			}
			
			if let err = error {
				OTPLog.log(level:.warning, info:"response from server for mode list is failed, \(err.localizedDescription)")
				guard let _ = DataHelper.object(data) as? [String: Any] else {
					OTPLog.log(level:.warning, info:"response from server for mode list is failed, invalid error json data")
					completion([])
					return
				}
				completion([])
				return
			}
			
			do{
				let searchModes = try JSONDecoder().decode([SearchMode].self, from: data)
				completion(searchModes)
			}catch{
				OTPLog.log(level:.error, info: "can not decode the search modes, \(error)")
				completion([])
			}
		}
	}
	
	/// Object.
	/// - Parameters:
	///   - _: Parameter description
	/// - Returns: Any?
	public func object(_ data: Data) -> Any?{
		var obj: Any?
		do{
			obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
		}catch let error as NSError {
			OTPLog.log(level: .error, info: "json serialization error: \(error.description)")
		}
		return obj
	}
	
	
	func loadAppConfiguration(completion: @escaping([String:Any]?, String?) -> Void){
		do{
			if let bundlePath = Bundle.main.url(forResource: "config", withExtension: "json"){
			    let encryptedConfig = try String(contentsOfFile: bundlePath.path)
				if let appConfig = IBISecurity.decrypt(encryptedConfig),
				   let data = appConfig.data(using: .utf8) {
					guard let respObj = self.object(data) as? [String: Any] else {
						completion(nil, "can not properly parse the data object".localized())
						return
					}
					
					// Update the revision number.
					if let _ = respObj["data"] as? [String:Any]{
						completion(respObj, nil)
					}
					else{
						completion(nil, "configuration is not properly loaded.")
					}
				}else{
					completion(nil, "can not decode the app config data")
				}
			}else{
				completion(nil, "configruation file is not found in app bundle")
			}
		}catch{
			completion(nil, "failed to load configuration, \(error.localizedDescription)")
		}
	}
}
