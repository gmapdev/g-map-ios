//
//  OTPUtils.swift
//

import Foundation
import CryptoKit
import MapKit

/// OTP related Utils functionality
@objc public class OTPUtils: NSObject {
	
	/// This function will convert the timestamp to the local time based on the format that is given.
	/// by default it will convert to yyyy-MM-dd HH:mm:ss
	/// if the time format is set to 'h:mm a' we can setup the am/pm symbol
 /// Converts timestamp to local.
 /// - Parameters:
 ///   - utcTimestamp: Double
 ///   - toFormat: String = "yyyy-MM-dd HH:mm:ss"
 ///   - withAMSymbol: String = "AM"
 ///   - withPMSymbol: String = "PM"
 /// - Returns: String
	@objc public static func convertTimestampToLocal(_ utcTimestamp: Double, toFormat:String = "yyyy-MM-dd HH:mm:ss", withAMSymbol: String = "AM", withPMSymbol: String = "PM") -> String {
		var utcTimestampInSecs = utcTimestamp
		let validateTimestampString = "\(utcTimestamp)"
		let comps = validateTimestampString.components(separatedBy: ".")
		if "\(comps[0])".count > 10 {
			utcTimestampInSecs = utcTimestampInSecs/1000
		}
		
		let srcDate = Date(timeIntervalSince1970: utcTimestampInSecs)
		let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
		dateFormatter.dateFormat = toFormat
		let srcPrettyDate = dateFormatter.string(from: srcDate)
		return srcPrettyDate
	}
	
	
	/// This is used to convert a string to a sha256 string
 /// Sha 256.
 /// - Parameters:
 ///   - content: String
 /// - Returns: String
	@objc public static func sha256(content: String) -> String {
		let data = Data(content.utf8)
		let hashed = SHA256.hash(data: data)
		let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
		return hashString
	}
	
	
	/// This function is used to delete and remove the folder/file in a given path in the document folder.
 /// Removes item in doc path.
 /// - Parameters:
 ///   - itemPath: String
 /// - Returns: Bool
	@objc public static func removeItemInDocPath(_ itemPath: String) -> Bool{
		let fileManager = FileManager.default
		let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
		if let documentDirectory: URL = urls.first {
			let entirePath = "\(documentDirectory.path)/\(itemPath)"
			if fileManager.fileExists(atPath: entirePath){
				do {
					try fileManager.removeItem(atPath:entirePath)
				}
				catch {
					assertionFailure("Can not remove the folder from path: \(entirePath). \(error.localizedDescription)")
					return false
				}
			}else{
				OTPLog.log(info: "No need to delete/remove folder, folder is original not exited")
				return true
			}
		}
		return true
	}
	
	/// This function is used to create the folder in the documentation path.
 /// Creates folder in doc path if needed.
 /// - Parameters:
 ///   - folderPath: String
 /// - Returns: Bool
	@objc public static func createFolderInDocPathIfNeeded(_ folderPath: String) -> Bool{
		let fileManager = FileManager.default
		let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
		if let documentDirectory: URL = urls.first {
			var directory: ObjCBool = ObjCBool(false)
			let entirePath = "\(documentDirectory.path)/\(folderPath)"
			let folderExisted = fileManager.fileExists(atPath: entirePath, isDirectory: &directory)
			if folderExisted && directory.boolValue {} else {
				do {
					try fileManager.createDirectory(atPath: entirePath, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					assertionFailure("Can not create documents folder for the TravelIQ. \(error.localizedDescription)")
					return false
				}
			}
			return true
		}
		else{
			assert(false, "Couldn't get general documents directory")
			return false
		}
	}
	
	
	/// This function is used to get the documation folder path of the app
 /// Doc path.
 /// - Parameters:
 ///   - withAppendedPath: String = ""
 /// - Returns: URL
	@objc public static func docPath(_ withAppendedPath: String = "") -> URL {
		let fileManager = FileManager.default
		let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
		if let documentDirectory: URL = urls.first {
			var directory: ObjCBool = ObjCBool(false)
			let folderExisted = fileManager.fileExists(atPath: documentDirectory.path, isDirectory: &directory)
			if folderExisted && directory.boolValue {} else {
				do {
					try fileManager.createDirectory(atPath: documentDirectory.path, withIntermediateDirectories: true, attributes: nil)
				}
				catch {
					assertionFailure("Can not create documents folder for the TravelIQ. \(error.localizedDescription)")
					return URL(fileURLWithPath: "")
				}
			}
			let path = documentDirectory.appendingPathComponent(withAppendedPath)
			return path
		}
		else{
			assert(false, "Couldn't get general documents directory")
		}
		return URL(fileURLWithPath: "")
	}
	
	/// This function is used to convert an swift object to json string
 /// Obj to json string.
 /// - Parameters:
 ///   - object: Any
 /// - Returns: String
	@objc public static func objToJSONString(object:Any) -> String{
		if let data = try? JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed) {
			if let jsonString = String(data: data, encoding: .utf8) {
				return jsonString
			}
		}
		assert(false, "Convert object to json failed")
		return ""
	}
	
	/// This is used to convert the degree to radians
 /// Deg to radians.
 /// - Parameters:
 ///   - degree: Double
 /// - Returns: Double
	@objc public static func degToRadians(_ degree: Double) -> Double {
		return degree * .pi / 180
	}
	
	/// This is used to convert the radians to degree
 /// Rad to degree.
 /// - Parameters:
 ///   - radians: Double
 /// - Returns: Double
	@objc public static func radToDegree(_ radians: Double) -> Double {
		return radians * 180 / .pi
	}
	
	/// This is the use to get the angle where the vector is the bearing and the vector between from and to
 /// Heading.
 /// - Parameters:
 ///   - from: CLLocationCoordinate2D
 ///   - to: CLLocationCoordinate2D
 /// - Returns: Double
	@objc public static func heading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)->Double{
		let fLat = degToRadians(from.latitude);
		let fLng = degToRadians(from.longitude);
		let tLat = degToRadians(to.latitude);
		let tLng = degToRadians(to.longitude);
		
		let degree = radToDegree(atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng)));
		
		if (degree >= 0) {
			return degree;
		} else {
			return 360+degree;
		}
	}
	
	/// This funciton is used to cheak the difference of two angles where it uses bearing coordinates
 /// Bearing diff.
 /// - Parameters:
 ///   - angle1: Double
 ///   - angle2: Double
 /// - Returns: Double
	@objc public static func bearingDiff(angle1: Double, angle2: Double) -> Double {
		let maximum = angle1 > angle2 ? angle1 : angle2;
		let minimum = angle1 < angle2 ? angle1 : angle2;
		var referenceAngle = maximum - minimum;
		if(referenceAngle > 180){
			referenceAngle = fabs(360 - referenceAngle);
		}
		return referenceAngle;
	}
	
 /// Create u i color.
 /// - Parameters:
 ///   - hex: Parameter description
 /// - Returns: UIColor
	@objc public static func createUIColor(hex: String) -> UIColor {
		let r, g, b: CGFloat
		if hex.hasPrefix("#") {
			let start = hex.index(hex.startIndex, offsetBy: 1)
			let hexColor = String(hex[start...])
			
			if hexColor.count == 6 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0
				
				if scanner.scanHexInt64(&hexNumber) {
					r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
					g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
					b = CGFloat((hexNumber & 0x0000ff))  / 255
					
     /// Red: r, green: g, blue: b, alpha: 1
     /// Initializes a new instance.
     /// - Parameters:
     ///   - red: r
     ///   - green: g
     ///   - blue: b
     ///   - alpha: 1
					return UIColor.init(red: r, green: g, blue: b, alpha: 1)
				}
			}
		}
		return UIColor.black
	}
	
 /// Read encrypted data.
 /// - Parameters:
 ///   - filePath: Parameter description
 /// - Returns: Data?
	public static func readEncryptedData(filePath: URL) -> Data? {
		do {
			let encryptedData = try String(contentsOf: filePath)
			if let content = IBISecurity.decrypt(encryptedData) {
				let contentData = content.data(using: .utf8)
				return contentData
			}
		}
		catch {
			let error = error.localizedDescription
			OTPLog.log(level: .error, info: "Cannot load the encrypted data from path \(filePath.path)")
			assertionFailure(error)
		}
		return nil
	}
	
 /// Language code
 /// - Returns: String
 /// Language code.
	public static func languageCode() -> String {
		var appLanguage = "en-CA"
		if Locale.preferredLanguages.count > 0 {
			appLanguage = Locale.preferredLanguages[0]
		}
		return appLanguage ?? "en"
	}
}
