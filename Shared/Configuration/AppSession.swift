//
//  AppSession.swift
//

import Foundation
import SwiftUI

/// Represents user authentication and profile information.
///
/// This struct contains all user-related data obtained from Auth0 authentication
/// and the backend API. It includes:
/// - Authentication credentials (email, token, expiration)
/// - User profile information (name, phone, preferences)
/// - Verification status (email, phone)
/// - Saved locations and trip history settings
///
/// Example:
/// ```swift
/// let loginInfo = LoginInfo(
///     email: "user@example.com",
///     token: "jwt_token_here",
///     expire: Date().timeIntervalSince1970 + 3600,
///     emailIsVerified: true,
///     phoneVerified: false,
///     name: "John Doe",
///     auth0UserId: "auth0|123456"
/// )
/// ```
struct LoginInfo : Equatable{
    /// User's email address used for authentication
    var email: String

    /// JWT authentication token for API requests
    var token: String

    /// Token expiration timestamp (Unix time)
    var expire: Double

    /// Whether the user's email has been verified
    var emailIsVerified: Bool

    /// Whether the user's phone number has been verified
    var phoneVerified: Bool

    /// Auth0 user identifier
    var id: String?

    /// User's display name from Auth0
    var name: String

    /// Whether user has opted in to store trip history
    var storeTripHistory: Bool = false

    /// Whether user has accepted terms and conditions
    var hasConsentedToTerms: Bool = false

    /// Preferred notification channel (email, push, SMS)
    var notificationChannel: String = ""

    /// User's phone number for notifications
    var phoneNumber: String = ""

    /// Number of registered push notification devices
    var pushDevices: Int = 0

    /// User's saved favorite locations
    var savedLocations: [FavouriteLocation]?

    /// Auth0 user ID (format: "auth0|123456")
    var auth0UserId: String

    /// Returns a shortened version of the user's name (first 2 characters).
    ///
    /// If email contains '@', extracts the first 2 characters before '@'.
    /// Otherwise, returns the first 2 characters of the email.
    ///
    /// - Returns: A 2-character string representing the user's initials
    ///
    /// Example:
    /// - "john.doe@example.com" → "jo"
    /// - "johndoe" → "jo"
    func shortName() -> String {
        if email.contains("@") {
            let name = String(email.split(separator: "@")[0])[0..<2]
            return name
        }
        return email[0..<2]
    }

    /// Returns the username portion of the email address.
    ///
    /// If email contains '@', returns everything before the '@' symbol.
    /// Otherwise, returns the entire email string.
    ///
    /// - Returns: The username portion of the email
    ///
    /// Example:
    /// - "john.doe@example.com" → "john.doe"
    /// - "johndoe" → "johndoe"
    func longName() -> String {
        if email.contains("@") {
            let name = String(email.split(separator: "@")[0])
            return name
        }
        return email
    }
}

/// Manages application session state and service providers.
///
/// This class serves as the central hub for:
/// - User authentication state management
/// - Service provider dependency injection
/// - App lifecycle coordination
/// - Session-wide state publishing
///
/// Architecture:
/// - Uses Combine's `@Published` properties for reactive state updates
/// - Implements dependency injection via ServiceContainer
/// - Provides singleton access pattern
/// - Integrates with Auth0 for authentication
///
/// Service Providers:
/// The session manages multiple service providers:
/// - `LoginAuthProvider`: Auth0 authentication
/// - `UserAccountProvider`: User profile management
/// - `NotificationProvider`: Push notifications
/// - `TripProvider`: Trip planning and management
/// - `BusInfoProvider`: Real-time transit information
/// - `ImageProvider`: Image loading and caching
/// - `PushServiceProvider`: Push notification registration
/// - `LogServiceProvider`: Analytics and logging
///
/// Example:
/// ```swift
/// // Access session
/// let session = AppSession.shared
///
/// // Check login status
/// if let loginInfo = session.loginInfo {
///     print("User logged in: \(loginInfo.email)")
/// }
///
/// // Access service providers
/// let authProvider: LoginAuthProvider = session.serviceContainer.resolve()
/// ```
class AppSession: ObservableObject {

    /// Published timestamp for triggering UI updates.
    ///
    /// Update this property to force views observing AppSession to refresh.
    /// Useful for triggering UI updates after state changes.
	@Published var pubStateLastUpdated = Date().timeIntervalSince1970

    /// Controls the display of the splash screen.
    ///
    /// Set to `true` to show the splash screen, `false` to hide it.
    @Published var pubDisplaySplashScreen: Bool = false

    /// Current user login information.
    ///
    /// - `nil` when user is not logged in
    /// - Contains authentication token and user profile when logged in
    ///
    /// Observe this property to react to login/logout events.
	@Published var loginInfo: LoginInfo?

    /// Temporary storage for login info during server synchronization.
    ///
    /// Used to compare local user data with server data and detect changes
    /// that need to be synchronized.
    var tempLoginInfo: LoginInfo?

    /// Push notification device token data.
    ///
    /// Stored after successful APNS registration, used for subscribing
    /// to push notifications on the backend.
	var pushDeviceTokenData: Data?

    /// Haptic feedback style for user interactions.
    ///
    /// Configured from BrandConfig, determines the intensity of haptic
    /// feedback throughout the app (.success, .warning, .error).
    var hapticFeedbackStyle: UINotificationFeedbackGenerator.FeedbackType = BrandConfig.shared.ios_haptic_feedback_type

	// Service providers (private instances)
	private var auth0Provider = LoginAuthProvider()
	private var userAccountProvider = UserAccountProvider()
	private var notificationProvider = NotificationProvider()
	private var pushServiceProvider = PushServiceProvider()
	private var tripProvider = TripProvider()
    private var routingErrorProvider = RoutingErrorsProvider()
    private var busInfoProvider = BusInfoProvider()
    private var imageProvider = ImageProvider()
    private var modeCombinationProvider = ModeCombinationProvider()
    private var modeMappingProvider = ModeMappingProvider()
    private var logServiceProvider = LogServiceProvider()

    /// Dependency injection container for service providers.
    ///
    /// Use this container to resolve service provider dependencies throughout
    /// the app. The container is built using a result builder pattern.
    ///
    /// Example:
    /// ```swift
    /// let authProvider: LoginAuthProvider = AppSession.shared.serviceContainer.resolve()
    /// authProvider.login(username: "user", password: "pass")
    /// ```
    public var serviceContainer = ServiceContainer {
        ServiceProvider { shared.auth0Provider }
        ServiceProvider { shared.userAccountProvider }
        ServiceProvider { shared.notificationProvider}
        ServiceProvider { shared.tripProvider }
        ServiceProvider { shared.busInfoProvider }
        ServiceProvider { shared.imageProvider }
        ServiceProvider { shared.pushServiceProvider }
        ServiceProvider { shared.logServiceProvider }
    }

    /// Keys for storing session-related data in UserDefaults.
    public enum UserDefaultKey: String {
        /// User's preferred app language code (e.g., "en", "es", "fr")
        case app_language = "app_language"
    }

    /// Shared singleton instance of AppSession.
    ///
    /// This instance is lazily initialized and automatically registers
    /// for push notifications during initialization.
    ///
    /// - Important: Always use this shared instance to maintain consistent
    ///   session state across the app.
    static var shared: AppSession = {
        let instance = AppSession()
        NotificationManager.shared.registerAndSubscribeAPNS()
        return instance
    }()

    /// Initializes the app session and loads essential data.
    ///
    /// This method should be called during app startup to:
    /// 1. Configure accessibility settings (text size, larger text mode)
    /// 2. Load route data (sorted routes, GraphQL routes)
    /// 3. Fetch mode combinations for trip planning
    /// 4. Load routing error mappings
    /// 5. Fetch banned route list
    /// 6. Initialize indoor navigation (JMapManager)
    ///
    /// Call this method in your AppDelegate or SceneDelegate after
    /// configuration has been loaded.
    ///
    /// Example:
    /// ```swift
    /// func application(_ application: UIApplication,
    ///                  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ///     AppConfig.shared.requestAndLoadConfigFromServer { _ in
    ///         AppSession.shared.start()
    ///     }
    ///     return true
    /// }
    /// ```
    func start() {
        AccessibilityManager.shared.isLargerTextEnabled()
        AccessibilityManager.shared.getFontSize()
        RouteViewerModel.shared.fetchSortedRoutes()
        RouteViewerModel.shared.fetchGraphQLRoutes()
        modeCombinationProvider.fetchModeCombinations()
        routingErrorProvider.fetchErrorMappingList()
        modeMappingProvider.fetchBannedRouteList()
        let _ = JMapManager.shared
	}

    /// Logs out the current user and resets session state.
    ///
    /// This method performs the following cleanup:
    /// 1. Clears login information from memory
    /// 2. Calls Auth0 logout to clear authentication state
    /// 3. Resets login flow to login page
    /// 4. Closes profile popup if open
    /// 5. Triggers UI update via published property
    ///
    /// - Important: This method must be called on the main actor as it
    ///   updates UI-related state.
    ///
    /// Example:
    /// ```swift
    /// Task { @MainActor in
    ///     AppSession.shared.logout()
    /// }
    /// ```
 	@MainActor func logout(){
		self.loginInfo = nil
		self.auth0Provider.logout()
		LoginFlowManager.shared.pageState = .login
		TabBarMenuManager.shared.pubShowProfilePopUp = false
		DispatchQueue.main.async {
			AppSession.shared.pubStateLastUpdated = Date().timeIntervalSince1970
		}
	}
}
