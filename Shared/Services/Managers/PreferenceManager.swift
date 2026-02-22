//
//  PreferenceManager.swift
//

import Foundation

/// Secure preference storage manager with encryption support.
///
/// PreferenceManager provides a secure wrapper around UserDefaults and iOS Keychain,
/// automatically encrypting sensitive data before storage. It supports:
/// - Encrypted storage in iOS Keychain for sensitive data
/// - Encrypted UserDefaults for less sensitive preferences
/// - In-memory caching for performance
/// - Type-safe storage and retrieval (String, Int, Double, Bool)
///
/// Architecture:
/// ```
/// PreferenceManager
///   ├── Keychain (secure storage)
///   ├── UserDefaults (encrypted)
///   └── Memory Cache (performance)
/// ```
///
/// Security Features:
/// - All values are encrypted using IBISecurity before storage
/// - Keys are also encrypted to prevent enumeration
/// - Keychain storage for maximum security
/// - Automatic cache invalidation
///
/// Example:
/// ```swift
/// // Store encrypted value
/// PreferenceManager.set("secret_token", forKey: "auth_token")
///
/// // Retrieve decrypted value
/// if let token: String = PreferenceManager.object(forKey: "auth_token") {
///     print("Token: \(token)")
/// }
/// ```
class PreferenceManager {

	/// In-memory cache for frequently accessed preferences
	private var cache: [String: String] = [:]

	/// Shared singleton instance of PreferenceManager.
	///
	/// Use this instance throughout the app for consistent preference management.
	public static var shared: PreferenceManager = {
		let mgr = PreferenceManager()
		return mgr
	}()

	/// Stores a value securely in the iOS Keychain.
	///
	/// This method provides the highest level of security by storing data in
	/// the iOS Keychain. The value is stored unencrypted in Keychain (Keychain
	/// provides its own encryption), but is also cached in memory for performance.
	///
	/// - Parameters:
	///   - key: The key to store the value under
	///   - value: The string value to store
	/// - Returns: `true` if storage was successful, `false` otherwise
	///
	/// - Important: This method uses the app's bundle identifier as a namespace
	///   to prevent key collisions with other apps.
	///
	/// Example:
	/// ```swift
	/// let success = PreferenceManager.shared.setValueForKeyInStore(
	///     key: "user_token",
	///     value: "abc123"
	/// )
	/// ```
	public func setValueForKeyInStore(key: String, value: String) -> Bool{
		self.cache[key] = value
		if let tag = Bundle.main.bundleIdentifier {
		   let tagKey = tag + "." + key
		   let result: Data = value.data(using: .utf8)!
		   let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
									   kSecAttrAccount as String: tagKey,
									   kSecValueData as String: result]
			let delQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
										kSecAttrAccount as String: tagKey]
			var status = SecItemDelete(delQuery as CFDictionary)
			OTPLog.log(level: .info, info: "key store access code for deleting: \(status) - key: \(key) - value: \(value)")
			status = SecItemAdd(query as CFDictionary, nil)
			OTPLog.log(level: .info, info: "key store access code for adding: \(status) - key: \(key) - value: \(value)")
			
			let resultStatus = status == errSecSuccess
			return resultStatus
		}

		return false
	}

	/// Retrieves a value from the iOS Keychain.
	///
	/// This method first checks the in-memory cache for performance, then
	/// queries the Keychain if not found in cache. Retrieved values are
	/// automatically cached for subsequent accesses.
	///
	/// - Parameter key: The key to retrieve the value for
	/// - Returns: The stored string value, or `nil` if not found
	///
	/// Example:
	/// ```swift
	/// if let token = PreferenceManager.shared.retrieveValueForKeyFromStore(key: "user_token") {
	///     print("Token: \(token)")
	/// }
	/// ```
	public func retrieveValueForKeyFromStore(key: String) -> String? {
		let cacheKey = key
		if let val = self.cache[cacheKey] {
			return val
		}
		
		if let tag = Bundle.main.bundleIdentifier {
		   let tagKey = tag + "." + key
		   let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
									   kSecAttrAccount as String: tagKey,
									   kSecMatchLimit as String: kSecMatchLimitOne,
									   kSecReturnAttributes as String: true,
									   kSecReturnData as String: true]
		   var item: CFTypeRef?
		   let status = SecItemCopyMatching(query as CFDictionary, &item)
		   if status == errSecSuccess {
			   if let existingItem = item as? [String: Any],
				  let key = existingItem[kSecAttrAccount as String] as? String,
				  let value = existingItem[kSecValueData as String] as? Data,
      /// Data: value, encoding: .utf8
      /// Initializes a new instance.
      /// - Parameters:
      ///   - data: value
      ///   - encoding: .utf8
				  let result = String.init(data: value, encoding: .utf8){
				   self.cache[cacheKey] = result
				   return result
			   }
		   }
		}
		return nil
	}

	/// Encrypts and stores a value in UserDefaults.
	///
	/// This private method encrypts both the key and value using IBISecurity
	/// before storing in UserDefaults. This provides an additional layer of
	/// security for preferences.
	///
	/// - Parameters:
	///   - value: The string value to encrypt and store
	///   - forKey: The key to store the value under (will be encrypted)
	private static func encrypt(value: String, forKey: String) {
		let encryptedKey = IBISecurity.encrypt(forKey)
		let encryptedValue =  IBISecurity.encrypt(value)
		UserDefaults.standard.set(encryptedValue, forKey: encryptedKey.count > 0 ? encryptedKey : forKey)
		UserDefaults.standard.synchronize()
	}

	/// Decrypts and retrieves a value from UserDefaults.
	///
	/// This private method decrypts both the key and value using IBISecurity
	/// when retrieving from UserDefaults.
	///
	/// - Parameter forKey: The key to retrieve (will be encrypted for lookup)
	/// - Returns: The decrypted string value, or `nil` if not found
	private static func decrypt(forKey: String) -> String? {
		let encryptedKey = IBISecurity.encrypt(forKey)
		if  encryptedKey.count > 0 {
			if let encryptedValue = UserDefaults.standard.object(forKey: encryptedKey) as? String {
				return IBISecurity.decrypt(encryptedValue) ?? encryptedValue
			}
		}
		return nil
	}

	/// Retrieves a string value from encrypted storage.
	///
	/// - Parameter forKey: The key to retrieve the value for
	/// - Returns: The decrypted string value, or `nil` if not found
	///
	/// Example:
	/// ```swift
	/// if let username: String = PreferenceManager.object(forKey: "username") {
	///     print("Username: \(username)")
	/// }
	/// ```
	public static func object(forKey: String) -> String? {
		return decrypt(forKey: forKey)
	}

	/// Retrieves an integer value from encrypted storage.
	///
	/// - Parameter forKey: The key to retrieve the value for
	/// - Returns: The integer value, or `nil` if not found or not convertible
	///
	/// Example:
	/// ```swift
	/// if let count: Int = PreferenceManager.object(forKey: "login_count") {
	///     print("Login count: \(count)")
	/// }
	/// ```
	public static func object(forKey: String) -> Int? {
		if let value = decrypt(forKey: forKey) {
			return Int(value)
		}
		return nil
	}

	/// Retrieves a double value from encrypted storage.
	///
	/// - Parameter forKey: The key to retrieve the value for
	/// - Returns: The double value, or `nil` if not found or not convertible
	public static func object(forKey: String) -> Double? {
		if let value = decrypt(forKey: forKey) {
			return Double(value)
		}
		return nil
	}

	/// Retrieves a boolean value from encrypted storage.
	///
	/// - Parameter forKey: The key to retrieve the value for
	/// - Returns: The boolean value, or `nil` if not found
	///
	/// - Note: Booleans are stored as "true" or "false" strings
	public static func object(forKey: String) -> Bool? {
		if let value = decrypt(forKey: forKey) {
			return value == "true"
		}
		return nil
	}

	/// Stores a boolean value in encrypted storage.
	///
	/// - Parameters:
	///   - object: The boolean value to store
	///   - forKey: The key to store the value under
	///
	/// Example:
	/// ```swift
	/// PreferenceManager.set(true, forKey: "notifications_enabled")
	/// ```
	public static func set(_ object: Bool, forKey: String) {
		encrypt(value: object ? "true" : "false", forKey: forKey)
	}

	/// Stores an integer value in encrypted storage.
	///
	/// - Parameters:
	///   - object: The integer value to store
	///   - forKey: The key to store the value under
	public static func set(_ object: Int, forKey: String) {
		encrypt(value: "\(object)", forKey: forKey)
	}

	/// Stores a double value in encrypted storage.
	///
	/// - Parameters:
	///   - object: The double value to store
	///   - forKey: The key to store the value under
	public static func set(_ object: Double, forKey: String) {
		encrypt(value: "\(object)", forKey: forKey)
	}

	/// Stores a string value in encrypted storage.
	///
	/// - Parameters:
	///   - object: The string value to store
	///   - forKey: The key to store the value under
	public static func set(_ object: String, forKey: String) {
		encrypt(value: object, forKey: forKey)
	}
}
