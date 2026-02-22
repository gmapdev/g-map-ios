//
//  NotificationManager.swift
//

import Foundation
import SwiftUI
import UserNotifications

enum LocalNotificationCategory: String {
    case liveTracking = "live.tracking"
    case indoorNavigation = "indoor.navigation"
    
}

/// This is used to manage the notification related callback function.
class NotificationManager: ObservableObject {
	
	/// Used to notify the oberver, now the data is updated
	@Published var pubIsEnabledPushNotification = false
	
    private let center = UNUserNotificationCenter.current()
    private let runningNotificationID = "local.activity.running"
    private let runningCategoryID = "activity.running"
	/// Notification Manager shared instance
	public static var shared: NotificationManager = {
		let mgr = NotificationManager()
		return mgr
	}()
	
 /// Register and subscribe a p n s
 /// Registers and subscribe apns.
	public func registerAndSubscribeAPNS(){
		let center = UNUserNotificationCenter.current()
		center.getNotificationSettings(completionHandler: { settings in
				DispatchQueue.main.async {
					center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in if granted {
						OTPLog.log(level: .info, info: "User gives notification permission to the app")
					}else {
						OTPLog.log(level: .info, info: "User refuse to give notification permission to the app")
					}
				}
				UIApplication.shared.registerForRemoteNotifications()
			}
		})
	}
	
 /// Check notification permission
 /// Checks notification permission.
	public func checkNotificationPermission(){
		let center = UNUserNotificationCenter.current()
		center.getNotificationSettings(completionHandler: { settings in
			DispatchQueue.main.async {
				let authorizationStatus = settings.authorizationStatus
				if authorizationStatus == .authorized || authorizationStatus == .provisional {
					self.pubIsEnabledPushNotification = true
				}
				else if authorizationStatus == .denied{
					self.pubIsEnabledPushNotification = false
				}
				else if authorizationStatus == .notDetermined {
					self.pubIsEnabledPushNotification = false
				}
				else{
					self.pubIsEnabledPushNotification = false
				}
			}
		})
	}
    
    /// Get category identifier.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: String
    func getCategoryIdentifier(for type: LocalNotificationCategory) -> String{
        return runningCategoryID + ".\(type.rawValue)"
    }
    
    /// Schedule running notification.
    /// - Parameters:
    ///   - type: Parameter description
    func scheduleRunningNotification(type : LocalNotificationCategory) {
            // De-dupe
            cancelRunningNotification()
        
            let content = UNMutableNotificationContent()
            content.body  = "Tap to return to your active G-Map trip."
            content.categoryIdentifier = getCategoryIdentifier(for: type)

            // Fast “as soon as we background” delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

            let request = UNNotificationRequest(
                identifier: runningNotificationID,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        /// Cancel running notification
        /// Cancels running notification.
        func cancelRunningNotification() {
            center.removePendingNotificationRequests(withIdentifiers: [runningNotificationID])
            center.removeDeliveredNotifications(withIdentifiers: [runningNotificationID])
        }
    
    /// Handle local notification.
    /// - Parameters:
    ///   - response: Parameter description
    ///   - _: Parameter description
    func handleLocalNotification(response: UNNotificationResponse,_ application:UIApplication) {
        
        let triggeredCategory = response.notification.request.content.categoryIdentifier
        
        // To do specific Action when User Tapped on the Notification.
        if getCategoryIdentifier(for: .liveTracking) == triggeredCategory {
            // Open current Running LiveTracking
        } else if getCategoryIdentifier(for: .indoorNavigation) == triggeredCategory {
            // Open current Running Indoor Navigation
        }
    }
}

