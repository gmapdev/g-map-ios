//
//  AppDelegate.swift
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate  {
    
	@Inject var pushServiceProvider: PushServiceProvider
	
    /// Application.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didFinishLaunchingWithOptions: Parameter description
    /// - Returns: Bool
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    /// Application.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - configurationForConnecting: Parameter description
    ///   - options: Parameter description
    /// - Returns: UISceneConfiguration
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Application.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - didDiscardSceneSessions: Parameter description
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
	
	/// If push notification register failed. then we process it here.
 /// Application.
 /// - Parameters:
 ///   - application: UIApplication
 ///   - error: Error
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		OTPLog.log(level: .error, info: "Failed to register for notifications: \(error.localizedDescription)")
	}
	
	/// Subscribe the notification registration callback function, so that we can get the device token for the push notification
 /// Application.
 /// - Parameters:
 ///   - application: UIApplication
 ///   - deviceToken: Data
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		AppSession.shared.pushDeviceTokenData = deviceToken
		OTPLog.log(level: .info, info: "Push Device Token: \(AppSession.shared.pushDeviceTokenData?.toHexString() ?? "Not Available")")
	}
	
 /// Application.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - didReceiveRemoteNotification: Parameter description
 ///   - fetchCompletionHandler: Parameter description
 /// - Returns: Void)
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		self.handlePushNotification(userInfo, application, forOnlyAlert: true)
	}
	
 /// User notification center.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - didReceive: Parameter description
 ///   - withCompletionHandler: Parameter description
 /// - Returns: Void)
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.trigger is UNPushNotificationTrigger{
            let userInfo = response.notification.request.content.userInfo
            self.handlePushNotification(userInfo, UIApplication.shared)
        }else{
            NotificationManager.shared.handleLocalNotification(response: response,  UIApplication.shared)
        }
	}
	
    /// User notification center.
    /// - Parameters:
    ///   - center: UNUserNotificationCenter
    ///   - notification: UNNotification
    /// - Returns: UNNotificationPresentationOptions
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.alert, .badge, .sound]
    }

	
 /// Handle push notification.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - forOnlyAlert: Parameter description
	func handlePushNotification(_ userInfo: [AnyHashable: Any],_ application:UIApplication, forOnlyAlert: Bool = false){
		ProfileManager.shared.openSavedTripItemByPush(userInfo)
		UIApplication.shared.applicationIconBadgeNumber = 1
		UIApplication.shared.applicationIconBadgeNumber = 0
	}

}

