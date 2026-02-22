//
//  DataHelper.swift
//

import Foundation

class DataHelper {
    
    /// Decode to data.
    /// - Parameters:
    ///   - json: String
    /// - Returns: T? where T: Codable
    static func decodeToData<T>(json: String)->T? where T: Codable {
        do{
            if let data = json.data(using: .utf8) {
                let object = try JSONDecoder().decode(T.self, from: data)
                return object
            }
        }catch{
            OTPLog.log(level: .error, info: "Can not decode json string to object. \(error)")
        }
        return nil
    }
    
    /// Encode to data.
    /// - Parameters:
    ///   - object: T
    /// - Returns: Data? where T: Codable
    static func encodeToData<T>(object: T)->Data? where T: Codable {
        do{
            let data = try JSONEncoder().encode(object)
            return data
        }catch{
           OTPLog.log(level: .error, info: "Can not encode object to json data. \(error)")
        }
        return nil
    }
    
    /// Converts to json string.
    /// - Parameters:
    ///   - object: T
    /// - Returns: String?
    static func convertToJSONString<T>(object: T)->String? {
        if let data = convertToData(object: object),
           /// Data: data, encoding: .utf8
           /// Initializes a new instance.
           /// - Parameters:
           ///   - data: data
           ///   - encoding: .utf8
           let jsonString = String.init(data: data, encoding: .utf8){
            return jsonString
        }
        return nil
    }
    
    /// Converts to data.
    /// - Parameters:
    ///   - object: T
    /// - Returns: Data?
    static func convertToData<T>(object: T)->Data?{
        do{
            let data = try JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)
            return data
        }catch{
           OTPLog.log(level: .error, info: "Can not parse object to data. \(object), \(error)")
        }
        return nil
    }
    
    /// Converts to object.
    /// - Parameters:
    ///   - jsonString: String
    /// - Returns: T?
    static func convertToObject<T>(jsonString: String)->T?{
        do{
            if let data = jsonString.data(using: .utf8) {
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? T
                return object
            }
            return nil
        }catch{
            OTPLog.log(level: .error, info: "Can not parse json string to object. \(jsonString), \(error)")
        }
        return nil
    }

    /// This function is used to convert the data from the response to a json object
    /// Object.
    /// - Parameters:
    ///   - data: Data
    /// - Returns: Any?
    public static func object(_ data: Data) -> Any?{
        var obj: Any?
        do{
            obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }catch let error as NSError {
            OTPLog.log(level: .error, info: "json serialization error: \(error)")
        }
        return obj
    }
    
    /// Time text.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: (String, Double)
    public static func timeText(for timeInterval: String) -> (String, Double) {
        var timeString = timeInterval.convertToTimeInterval().format()
        // return time in seconds
        if timeString.contains("sec"){
            return (timeString, timeInterval.convertToTimeInterval())
        }
        else{
            timeString = timeString.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " min", with: "")
            
            //return time in hr, min format
            if let minutes = Int(timeString), minutes >= 60 {
                let hours: Int = minutes / 60
                let leftMinutes: Int = minutes % 60
                return ("%1 hr, %2 min".localized(hours, leftMinutes), timeInterval.convertToTimeInterval())
            }
            //return time in minutes
            return ("%1 min".localized(timeString), timeInterval.convertToTimeInterval())
        }
    }
    
    // Function to convert an Encodable object to a dictionary
    /// Converts to dictionary.
    /// - Parameters:
    ///   - object: T
    /// - Returns: [String: Any]
    /// - Throws: Error if operation fails
    static func convertToDictionary<T: Encodable>(object: T) throws -> [String: Any] {
        let jsonData = try JSONEncoder().encode(object)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        
        if let dictionary = jsonObject as? [String: Any] {
            return dictionary
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }
    }
	
 /// Compose t n r with preview step id.
 /// - Parameters:
 ///   - oldTNRs: Parameter description
 /// - Returns: [TripNotificationResponse]
	static func composeTNRWithPreviewStepId(oldTNRs: [TripNotificationResponse]) -> [TripNotificationResponse]{
		var newTNRs = [TripNotificationResponse]()
		for tnr in oldTNRs {
			var newTNR = tnr.copy()
			if let legs = newTNR.itinerary.legs {
				for i in 0..<legs.count {
					newTNR.itinerary.legs?[i].previewStepId = UUID().uuidString
				}
			}
			newTNRs.append(newTNR)
		}
		return newTNRs
	}
    

}
