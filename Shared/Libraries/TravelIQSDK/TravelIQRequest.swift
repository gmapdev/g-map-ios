//
//  TravelIQRequest.swift
//

import Foundation
import UIKit

/// This is used to make the network request for all the TravelIQ related APIs
open class TravelIQRequest: NSObject, URLSessionDelegate {
    
	let id: String = UUID().uuidString
	
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
    public var globalHeaders = ["device_id":"-", "device_os":"iOS_\(UIDevice.current.systemVersion)"]
	#else
	public var globalHeaders = ["device_id":"-", "device_os":"iOS_Mac_\(UIDevice.current.systemVersion)"]
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
		let configuration = URLSessionConfiguration.default
		configuration.timeoutIntervalForRequest = 300
		configuration.timeoutIntervalForResource = 300
		let urlSM = URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue())
		let dataTask = urlSM.dataTask(with: request) { data, response, error in
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
            callback(nil, TravelIQError.notValidURL, nil)
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
                            OTPLog.log(level: .error, info: "multipart/form-data; response is empty, status code: \(status)", parameters: ["url":path])
                            callback(nil, TravelIQError.responseIsEmpty, response)
                        }
                    }else{
                        OTPLog.log(level: .error, info: "multipart/form-data; request failed, status code: \(status)", parameters: ["url":path])
                        callback(data, TravelIQError.requestFailed, response)
                    }
                }else{
                    OTPLog.log(level: .error, info: "multipart/form-data; Unknown response type", parameters: ["url":path])
                    callback(nil, TravelIQError.unknownResponseType, response)
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
            OTPLog.log(level: .error, info: "multipart/form-data; Url is not initialized.", parameters: ["url":path])
            callback(nil, TravelIQError.urlSessionIsNotInitialized, nil)
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
        
        guard let url = URL(string: path) else {
            OTPLog.log(level: .error, info: "can not convert the path to url \(path)")
            callback(nil, TravelIQError.notValidURL, nil)
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
                            OTPLog.log(level: .error, info: "response is empty, status code: \(status)", parameters: ["url":path])
                            callback(nil, TravelIQError.responseIsEmpty, response)
                        }
                    }else{
                        OTPLog.log(level: .error, info: "request failed, status code: \(status)", parameters: ["url":path])
                        callback(data, TravelIQError.requestFailed, response)
                    }
                }else{
                    OTPLog.log(level: .error, info: "Unknown response type", parameters: ["url":path])
                    callback(nil, TravelIQError.unknownResponseType, response)
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
            OTPLog.log(level: .error, info: "Url is not initialized.", parameters: ["url":path])
            callback(nil, TravelIQError.urlSessionIsNotInitialized, nil)
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
