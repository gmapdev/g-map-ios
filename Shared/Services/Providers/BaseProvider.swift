//
//  BaseProvider.swift
//

import Foundation
import Combine
import SwiftUI

class BaseProvider {
	
	var anyCancellables = [AnyCancellable]()
	
 /// Login user id
 /// - Returns: String
 /// Login user id.
	func loginUserId() -> String {
		if let loginInfo = AppSession.shared.loginInfo, let userId = loginInfo.id {
			return userId
		}
		return ""
	}
}
