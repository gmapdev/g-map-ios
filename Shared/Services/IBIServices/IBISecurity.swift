//
//  IBISecurity.swift
//

import Foundation
import CommonCrypto


public class IBISecurity {
	
	let key = "93bcead916b779be26d69fb61a33d9a7f51c027805f46bda71a94bcf00000000"
	let iv = "47ae599c354da66c2fa14abfc87b126a"
	
 /// Shared.
 /// - Parameters:
 ///   - IBISecurity: Parameter description
	public static var shared: IBISecurity = {
		let _shared = IBISecurity()
		return _shared
	}()
	
 /// Shift.
 /// - Parameters:
 ///   - value: Parameter description
 /// - Returns: Data
	private func shift(value: String) -> Data {
		var data = Data(capacity: value.count/2)
		do {
			let regex = try NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
			regex.enumerateMatches(in: value, range: NSRange(value.startIndex..., in: value)) { match, _, _ in
				let byteString = (value as NSString).substring(with: match!.range)
				if let num = UInt8(byteString, radix: 16) {
					data.append(num)
				}
			}
		}
		catch{
			OTPLog.log(level: .error, info: "Failed to shift the data for the value: \(error)")
			return Data()
		}
		return data
	}
	
 /// Process.
 /// - Parameters:
 ///   - data: Parameter description
 ///   - option: Parameter description
 /// - Returns: Data?
	private func process(data: Data?, option: CCOperation) -> Data? {
		guard let data = data else { return nil }
		let processedLength = data.count + kCCBlockSizeAES128
		var processedData   = Data(count: processedLength)
		let preParameter = shift(value: self.key)
		let nxtParameter = shift(value: self.iv)
		let options   = CCOptions(kCCOptionPKCS7Padding)
		var bytesLength = Int(0)
		let status = processedData.withUnsafeMutableBytes { proDataBytes in
			data.withUnsafeBytes { dataBytes in
				nxtParameter.withUnsafeBytes { nxtBytes in
					preParameter.withUnsafeBytes { preBytes in
						CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, preBytes.baseAddress, preParameter.count, nxtBytes.baseAddress, dataBytes.baseAddress, data.count, proDataBytes.baseAddress, processedLength, &bytesLength)
					}
				}
			}
		}
		guard UInt32(status) == UInt32(kCCSuccess) else {
			debugPrint("Error: Failed to crypt data. Status \(status)")
			return nil
		}
		processedData.removeSubrange(bytesLength..<processedData.count)
		return processedData
	}
	
 /// Encrypt data.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String
	public func encryptData(_ originalContent: String) -> String {
		if let base64Content = originalContent.data(using: .utf8)?.base64EncodedString() {
			if let encrypted = IBISecurity.shared.process(data: base64Content.data(using: .utf8), option: CCOperation(kCCEncrypt)) {
				let finalEncrypted = encrypted.map{ String(format:"%02x", $0)}.joined()
				return finalEncrypted
			}
		}
		return ""
	}
	
 /// Decrypt data.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String?
	public func decryptData(_ encryptedContent: String) -> String? {
		var encryptedData = Data(capacity: encryptedContent.count/2)
		let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
		regex.enumerateMatches(in: encryptedContent, range: NSRange(encryptedContent.startIndex..., in: encryptedContent)) { match, _, _ in
			let byteString = (encryptedContent as NSString).substring(with: match!.range)
			let num = UInt8(byteString, radix: 16)!
			encryptedData.append(num)
		}
		if let decrpted = IBISecurity.shared.process(data: encryptedData, option: CCOperation(kCCDecrypt)) {
			if let base64Data = Data(base64Encoded: decrpted) {
				let base64DecodedContent = String(data: base64Data, encoding: .utf8)
				return base64DecodedContent
			}
		}
		return ""
	}
	
 /// Encrypt.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String
	public static func encrypt(_ originalContent: String) -> String {
		return shared.encryptData(originalContent)
	}

 /// Decrypt.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String?
	public static func decrypt(_ encryptedContent: String) -> String? {
		return shared.decryptData(encryptedContent)
	}
}
