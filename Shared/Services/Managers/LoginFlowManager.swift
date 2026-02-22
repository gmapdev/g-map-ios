//
//  LoginFlowManager.swift
//

import Foundation
import SwiftUI

/// Represents the current page/state in the authentication flow.
///
/// The login flow consists of multiple screens that users navigate through
/// during account creation, login, and profile setup. This enum tracks
/// which screen is currently active.
///
/// Flow Sequence (typical):
/// 1. `.login` → User enters credentials
/// 2. `.verifyEmail` → Email verification required
/// 3. `.questionnaire` → User answers profile questions
/// 4. `.travelCompanion` → User adds travel companions
/// 5. `.manageFavoritePlaces` → User saves favorite locations
/// 6. `.notification` → User configures notification preferences
/// 7. `.accountComplete` → Setup complete
///
/// Alternative flows:
/// - `.signup` → New account creation
/// - `.resetPassword` → Password recovery
/// - `.launchSetup` → Initial app setup
public enum LoginPageState: String {
	/// Login screen (email/password entry)
	case login

	/// Sign up screen (new account creation)
	case signup

	/// Password reset screen
	case resetPassword

	/// Email verification screen
	case verifyEmail

	/// Favorite places management screen
	case manageFavoritePlaces

	/// Initial app launch setup
	case launchSetup

	/// Notification preferences screen
	case notification

	/// Account setup completion screen
	case accountComplete

	/// User questionnaire screen
    case questionnaire

	/// Travel companion setup screen
    case travelCompanion
}

/// Manages the authentication flow and login state.
///
/// LoginFlowManager orchestrates the multi-step authentication process including:
/// - Login/signup navigation
/// - Email verification tracking
/// - Auth0 integration
/// - Page state management
/// - Skip functionality for optional steps
///
/// The manager uses Auth0 for authentication and coordinates with
/// LoginAuthProvider for actual authentication operations.
///
/// Example:
/// ```swift
/// let manager = LoginFlowManager.shared
/// manager.pageState = .login
/// manager.pubPresentLoginPage = true
///
/// // Check if user is logged in
/// manager.isUserLoggedin()
/// ```
public class LoginFlowManager: ObservableObject {

	/// Injected Auth0 authentication provider
    @Inject var authProvider: LoginAuthProvider

	/// Controls whether the login page is presented
	@Published public var pubPresentLoginPage: Bool = false

	/// Controls whether the logged-in user menu is shown
    @Published var pubShowLoggedMenu: Bool = false

	/// Whether phone number errors should be displayed
    @Published public var pubPresentPhoneNumberError: Bool = true

	/// Whether phone number error popup should be shown
    @Published public var pubPresentPhoneNumberErrorPopUp: Bool = false

	/// Current page in the login flow
    public var pageState: LoginPageState = .login

	/// Auth0 domain URL from configuration
    let auth0URL = BrandConfig.shared.auth0_domain

	/// Auth0 client ID from configuration
    let auth0ClientId = BrandConfig.shared.auth0_client_id

	/// Auth0 client secret from configuration
    let auth0ClientSecret = BrandConfig.shared.auth0_client_secret

	/// Shared singleton instance of LoginFlowManager.
	///
	/// Use this instance throughout the app for consistent login flow management.
	public static var shared: LoginFlowManager = {
		let mgr = LoginFlowManager()
		return mgr
	}()

	/// Marks email verification as skipped by the user.
	///
	/// When users choose to skip email verification, this preference is
	/// stored so they aren't prompted again during the current session.
	///
	/// Example:
	/// ```swift
	/// LoginFlowManager.shared.confirmSkip()
	/// ```
    func confirmSkip(){
        UserDefaults.standard.set(true, forKey: "isEmailVerificationSkipped")
        UserDefaults.standard.synchronize()
    }

	/// Checks whether the user has previously skipped email verification.
	///
	/// - Returns: `true` if email verification was skipped, `false` otherwise
	///
	/// Example:
	/// ```swift
	/// if LoginFlowManager.shared.needToSkip() {
	///     // Skip verification step
	/// }
	/// ```
    func needToSkip() -> Bool{
        return UserDefaults.standard.bool(forKey: "isEmailVerificationSkipped")
    }

	/// Clears the email verification skip preference.
	///
	/// Call this when the user completes email verification or when
	/// resetting the login flow state.
	///
	/// Example:
	/// ```swift
	/// LoginFlowManager.shared.removeSkip()
	/// ```
    func removeSkip(){
        UserDefaults.standard.removeObject(forKey: "isEmailVerificationSkipped")
        UserDefaults.standard.synchronize()
    }

	/// Checks if a user is currently logged in and retrieves their info.
	///
	/// This method delegates to the Auth0 provider to check authentication
	/// status and fetch user information if logged in. The completion handler
	/// is called when the check completes.
	///
	/// Example:
	/// ```swift
	/// LoginFlowManager.shared.isUserLoggedin()
	/// // Auth provider will update AppSession.shared.loginInfo if logged in
	/// ```
    func isUserLoggedin(){
        authProvider.getUserInfo {}
    }
}
