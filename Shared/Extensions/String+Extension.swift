//
//  String+Extension.swift
//

import Foundation

private let characterEntities : [ Substring : Character ] = [
	// XML predefined entities:
	"&quot;"    : "\"",
	"&amp;"     : "&",
	"&apos;"    : "'",
	"&lt;"      : "<",
	"&gt;"      : ">",
	"&ndash;"    : "-",
	
	// HTML character entity references:
	"&nbsp;"    : "\u{00a0}",
	// ...
	"&diams;"   : "♦",
]


public extension String {
    /// Is numeric.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isNumeric: Bool {
      return !(self.isEmpty) && self.allSatisfy { $0.isNumber }
    }
    
   /// Slice.
   /// - Parameters:
   ///   - from: Parameter description
   ///   - to: Parameter description
   /// - Returns: String?
   func slice(from: String, to: String) -> String? {
	   guard let rangeFrom = range(of: from)?.upperBound else { return nil }
	   guard let rangeTo = self[rangeFrom...].range(of: to)?.lowerBound else { return nil }
	   return String(self[rangeFrom..<rangeTo])
   }
   
   subscript(_ range: CountableRange<Int>) -> String {
	   let start = index(startIndex, offsetBy: max(0, range.lowerBound))
	   let end = index(start, offsetBy: min(self.count - range.lowerBound,
											range.upperBound - range.lowerBound))
	   return String(self[start..<end])
   }

   subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
	   let start = index(startIndex, offsetBy: max(0, range.lowerBound))
		return String(self[start...])
   }
   
    /// Url.
    /// - Parameters:
    ///   - URL: Parameter description
	   var url: URL {
	   guard let url = URL(string: self) else {
		   assertionFailure("Invalid URL format")
		   return URL(fileURLWithPath: "")
	   }
	   return url
   }
   
   /// Query string.
   /// - Parameters:
   ///   - _: Parameter description
   /// - Returns: String
   func queryString(_ params: [String: String]) -> String {
	   guard !params.isEmpty else { return self }
	   var queryString = ""
	   for key in params.keys {
		   if queryString.count > 0 {
			   queryString += "&"
		   }
		   if let value = params[key] {
			   queryString += key + "=\(value)"
		   }
	   }
	   
	   var newRequestUrl = self
	   if self.contains("?") {
		   if let _ = self.lastIndex(of: "?") {
			   newRequestUrl += queryString
		   }else{
			   newRequestUrl += "&" + queryString
		   }
	   }else {
		   newRequestUrl += "?" + queryString
	   }
	   return newRequestUrl
   }
   
   /// Url.
   /// - Parameters:
   ///   - baseUrl: Parameter description
   ///   - params: Parameter description
   /// - Returns: URL
   func url(baseUrl: String, params: [String: String]? = nil) -> URL {
	   let urlStringWithParams = (baseUrl + self).queryString(params ?? [:])
	   guard let url = URL(string: urlStringWithParams) else {
		   preconditionFailure("Invalid URL format")
	   }
	   return url
   }
   
   /// Percent encoded
   /// - Returns: String
   /// Percent encoded.
   func percentEncoded() -> String {
	   var allowedQueryParamAndKey = NSCharacterSet.urlQueryAllowed
	   allowedQueryParamAndKey.remove(charactersIn: ";/?:@&=+$,() ")
	   return self.addingPercentEncoding(withAllowedCharacters: allowedQueryParamAndKey) ?? self
   }
   
 /// Remove prefix.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String
	func removePrefix(_ prefix: String) -> String {
	   guard self.hasPrefix(prefix) else { return self }
	   return String(dropFirst(prefix.count))
   }
   
   /// Creates an Codable instance with a given JSON file name = self.json
   /// - Parameter generic Codable
   /// - Returns: generic Codable
   func jsonDecode<T: Codable>() -> T {
	   guard let url = Bundle.main.url(forResource: self,
									   withExtension: "json"), let data = try? Data(contentsOf: url) else {
		   fatalError("jsonDecode: JSON file \(self).json doesn't exist")
	   }
	   let decoder = JSONDecoder()
	   do {
		   return try decoder.decode(T.self, from: data)
	   } catch DecodingError.keyNotFound(let key, let context) {
		   fatalError("jsonDecode: Failed to decode \(self).json: Missing key \(key.stringValue):  \(context.debugDescription)")
	   } catch DecodingError.typeMismatch(let type, let context) {
		   fatalError("jsonDecode: Failed to decode \(self).json: \(context.debugDescription), \(type)")
	   } catch DecodingError.valueNotFound(let type, let context) {
		   fatalError("jsonDecode: Failed to decode \(self).json: Missing \(type) value – \(context.debugDescription)")
	   } catch DecodingError.dataCorrupted(let error) {
           fatalError("jsonDecode: Failed to decode \(self).json: Invalid JSON, \(error)")
	   } catch {
		   fatalError("jsonDecode: Failed to decode \(self).json")
	   }
   }
   
   /// Capitalizing first letter
   /// - Returns: String
   /// Capitalizing first letter.
   func capitalizingFirstLetter() -> String {
	   return prefix(1).capitalized + dropFirst()
   }

   /// Capitalize first letter
   /// Capitalize first letter.
   mutating func capitalizeFirstLetter() {
	   self = self.capitalizingFirstLetter()
   }
	
 /// Url encode
 /// - Returns: String
 /// Url encode.
	func urlEncode() -> String {
		return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
	}
	
 /// Url decode
 /// - Returns: String
 /// Url decode.
	func urlDecode() -> String{
		return self.removingPercentEncoding ?? self
	}
	
 /// Chunck characters
 /// - Returns: String
 /// Chunck characters.
	func chunckCharacters() -> String {
		var processedString = ""
		for c in self {
			processedString += "\(c) "
		}
		return processedString
	}
    
    /// Remove stop i d prefix.
    /// - Parameters:
    ///   - String: Parameter description
    var removeStopIDPrefix: String{
        let components = self.components(separatedBy: ":")
        return components.last ?? ""
    }
    
    /// Is int.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isInt: Bool {
        return Int(self) != nil
    }
	
 /// Localized.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - languageBundle: Parameter description
 /// - Returns: String
	func localized(_ arguments: Any..., languageBundle: Bundle = Bundle.main, _ comment: String = "") -> String {
		let localizedString = NSLocalizedString(self, tableName: SettingsManager.shared.appLanguage.rawValue, bundle: languageBundle, value: self, comment: comment)
		var formatedString = localizedString
        if arguments.count > 1{
            for i in 0..<(arguments.count) {
                let item = "\(arguments[i])"
                formatedString = formatedString.replaceFirstOccurance(target: "%\(i+1)", replaceString: item)
            }
        }else {
            for argument in arguments {
                let item = "\(argument)"
                formatedString = formatedString.replaceFirstOccurance(target: "%1", replaceString: item)
            }
        }
		formatedString = formatedString.replaceDifferentSpelling()
        return formatedString
	}
	
 /// Replace different spelling
 /// - Returns: String
 /// Replace different spelling.
	public func replaceDifferentSpelling() -> String{
		var origin = self
		let unit = "imperial"
		var processedOrigin = origin
		if unit == "metric" {
			processedOrigin = processedOrigin.replacingOccurrences(of: "Favorite", with: "Favourite")
			processedOrigin = processedOrigin.replacingOccurrences(of: "favorite", with: "favourite")
		}
		else if unit == "imperial" {
			processedOrigin = processedOrigin.replacingOccurrences(of: "Favourite", with: "Favorite")
			processedOrigin = processedOrigin.replacingOccurrences(of: "favourite", with: "favorite")
		}
		return processedOrigin
	}
	
 /// Replace first occurance.
 /// - Parameters:
 ///   - target: Parameter description
 ///   - replaceString: Parameter description
 /// - Returns: String
	func replaceFirstOccurance(target: String, replaceString: String) -> String {
		if let range = self.range(of: target) {
			return self.replacingCharacters(in: range, with: replaceString)
		}
		return self
	}
    
    /// Map mode name aliase
    /// - Returns: String
    /// Map mode name aliase.
    func mapModeNameAliase() -> String {
        if self == "Tram"{
            return "Streetcar"
        }
        
        if self == "Water_Taxi"{
            return "Water Taxi"
        }
        if self == "Link"{
            return "Link Light Rail"
        }
        if self == "Rail"{
            return "Sounder"
        }
        if self == "Subway"{
            return "MARTA Rail"
        }
        return self
    }
    
    /// Convert to time interval
    /// - Returns: TimeInterval
    /// Converts to time interval.
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval:Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval
    }
	
		
	/// Get Swift used index from a given position of string
 /// Index.
 /// - Parameters:
 ///   - from: Int
 /// - Returns: Index
	func index(from: Int) -> Index {
		return self.index(startIndex, offsetBy: from)
	}

	/// Substring a given string from a position
 /// Substring.
 /// - Parameters:
 ///   - from: Int
 /// - Returns: String
	func substring(from: Int) -> String {
		let fromIndex = index(from: from)
		return String(self[fromIndex...])
	}

	/// Substring a given string from 0 to a given position
 /// Substring.
 /// - Parameters:
 ///   - to: Int
 /// - Returns: String
	func substring(to: Int) -> String {
		let toIndex = index(from: to)
		return String(self[..<toIndex])
	}

	/// Substring a given in a range. eg. `str.substring(with: 7..<11)`
 /// Substring.
 /// - Parameters:
 ///   - r: Range<Int>
 /// - Returns: String
	func substring(with r: Range<Int>) -> String {
		let startIndex = index(from: r.lowerBound)
		let endIndex = index(from: r.upperBound)
		return String(self[startIndex..<endIndex])
	}
	
 /// Tile polyline filter text.
 /// - Parameters:
 ///   - String: Parameter description
	var tilePolylineFilterText: String {
		var text = self
		text = text.replacingOccurrences(of: "to", with: "-")
		text = text.replacingOccurrences(of: "hours", with: "hr")
		return text
	}
	
 /// Width of string.
 /// - Parameters:
 ///   - usingFont: Parameter description
 /// - Returns: CGFloat
	func widthOfString(usingFont font: UIFont) -> CGFloat {
	  let fontAttributes = [NSAttributedString.Key.font: font]
	  let size = self.size(withAttributes: fontAttributes)
	  return size.width
	}
	
 /// Length.
 /// - Parameters:
 ///   - Int: Parameter description
	var length: Int {
		return count
	}

	subscript (i: Int) -> String {
		return self[i ..< i + 1]
	}

	
	/// Returns a new string made by replacing in the `String`
	/// all HTML character entity references with the corresponding
	/// character.
	var stringByDecodingHTMLEntities : String {
		
  /// Decode numeric.
  /// - Parameters:
  ///   - string: Substring
  ///   - base: Int
  /// - Returns: Character?
		func decodeNumeric(_ string : Substring, base : Int) -> Character? {
			guard let code = UInt32(string, radix: base),
				let uniScalar = UnicodeScalar(code) else { return nil }
			return Character(uniScalar)
		}
  /// Decode.
  /// - Parameters:
  ///   - entity: Substring
  /// - Returns: Character?
		func decode(_ entity : Substring) -> Character? {
			
			if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
				return decodeNumeric(entity.dropFirst(3).dropLast(), base: 16)
			} else if entity.hasPrefix("&#") {
				return decodeNumeric(entity.dropFirst(2).dropLast(), base: 10)
			} else {
				return characterEntities[entity]
			}
		}
		
		// ===== Method starts here =====
		
		var result = ""
		var position = startIndex
		
		// Find the next '&' and copy the characters preceding it to `result`:
		while let ampRange = self[position...].range(of: "&") {
			result.append(contentsOf: self[position ..< ampRange.lowerBound])
			position = ampRange.lowerBound
			
			// Find the next ';' and copy everything from '&' to ';' into `entity`
			guard let semiRange = self[position...].range(of: ";") else {
				// No matching ';'.
				break
			}
			let entity = self[position ..< semiRange.upperBound]
			position = semiRange.upperBound
			
			if let decoded = decode(entity) {
				// Replace by decoded character:
				result.append(decoded)
			} else {
				// Invalid entity, copy verbatim:
				result.append(contentsOf: entity)
			}
		}
		// Copy remaining characters to `result`:
		result.append(contentsOf: self[position...])
		return result
		
	}
	
 /// Base64
 /// - Returns: String
 /// Base 64.
	func base64() -> String{
		let utf8str = self.data(using: .utf8)
		if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
			return base64Encoded
		}
		return ""
	}
	
}
