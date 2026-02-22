//
//  DataExtension.swift
//

import Foundation

extension Data {
 /// To hex string
 /// - Returns: String
 /// To hex string.

 /// - Returns: String
	func toHexString() -> String {
		return self.reduce("", {$0 + String(format: "%02X", $1)})
	}
}

extension Double {
 /// Format.
 /// - Parameters:
 ///   - f: Parameter description
 /// - Returns: String
 /// Formats.
	func format(f: String) -> String {
		return String(format: "%\(f)f", self)
	}
	
 /// Round to decimal.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Double
	func roundToDecimal(_ fractionDigits: Int) -> Double {
		let multiplier = pow(10, Double(fractionDigits))
		return Darwin.round(self * multiplier) / multiplier
	}
}

extension UserDefaults {
    /// Bool.
    /// - Parameters:
    ///   - forKey: Parameter description
    ///   - defaultValue: Parameter description
    /// - Returns: Bool
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        return object(forKey: key) as? Bool ?? defaultValue
    }
}
