//
//  AuthView.swift
//

import SwiftUI
import Auth0
import Lock

public struct AuthView: UIViewControllerRepresentable {
	
	public var provider: LoginAuthProvider
	
 /// Provider:  login auth provider
 /// Initializes a new instance.
 /// - Parameters:
 ///   - provider: LoginAuthProvider
	public init(provider: LoginAuthProvider) {
		self.provider = provider
	}
	
 /// Make u i view controller.
 /// - Parameters:
 ///   - context: Parameter description
 /// - Returns: LockViewController
	public func makeUIViewController(context: Context) -> LockViewController {
		return Lock
			.classic()
			.withConnections{ connections in
				connections.database(name: "Username-Password-Authentication", requiresUsername: false)
		}
		.withStyle {
            $0.title = FeatureConfig.shared.login_page_title
			$0.headerCloseIcon = nil
            $0.logo = UIImage(named: "customer_logo_icon")?.resizeImage(FeatureConfig.shared.login_logo_width, FeatureConfig.shared.login_logo_height)
            $0.headerColor = UIColor.main
			$0.titleColor = UIColor.white
			$0.primaryColor = UIColor.main ?? UIColor.blue
		}
		.withOptions {
			$0.closable = true
			$0.oidcConformant = true
			$0.scope = "openid profile email otp-user"
			$0.audience = "https://otp-middleware"
		}
		.onAuth { credentials in
			DispatchQueue.main.async {
                TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
				LoginFlowManager.shared.pubPresentLoginPage = false
			}
		}
		.onSignUp(callback: { email, attributes in
			OTPLog.log(level: .info, info: "User signed up: \(email)")
			OTPLog.log(level: .info, info: "Attributes: \(attributes)")
		})
		.onError(callback: { (error) in
			OTPLog.log(level: .error, info: "Auth0 error: \(error)")
		})
		.controller
	}
	
 /// Update u i view controller.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - context: Parameter description
	public func updateUIViewController(_ uiViewController: LockViewController, context: Context) {}
}
