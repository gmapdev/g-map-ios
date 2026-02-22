//
//  SceneDelegate.swift
//

import UIKit
import SwiftUI
import MapKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
	
    /// Scene.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - willConnectTo: Parameter description
    ///   - options: Parameter description
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		AppConfig.shared.requestAndLoadConfigFromServer { isUpdated in

			AppConfig.shared.initialization()

			AppSession.shared.pubDisplaySplashScreen = true

			// Setup the environment to prepare all the possible resources.
			Env.shared.setup()

			// Register the delegate for get the notification


			// Ask Bluetooth Permissions and starting the accessing Bluetooth
			BluetoothManager.shared.startScan()
			
			if let response = connectionOptions.notificationResponse {
				if let userInfo = response.notification.request.content.userInfo as? [String: Any] {
					let secAfter = 5.0
					DispatchQueue.main.asyncAfter(deadline: .now() + secAfter) {
						ProfileManager.shared.openSavedTripItemByPush(userInfo)
					}
				}
			}
			
			DispatchQueue.main.async {
				if let windowScene = scene as? UIWindowScene {
					let window = UIWindow(windowScene: windowScene)
					window.rootViewController = UIHostingController(rootView: HomeView())
					self.window = window
					window.makeKeyAndVisible()

					// Initialize tab bar after a short delay to ensure proper rendering
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						Task { @MainActor in
							let isLoggedIn = AppSession.shared.loginInfo != nil
							TabBarMenuManager.shared.configureTabs(isLoggedIn: isLoggedIn)
							OTPLog.log(level: .info, info: "SceneDelegate: Initial tab configuration completed, availableTabs count=\(TabBarMenuManager.shared.availableTabs.count)")
						}
					}
				}
			}
		}
    }

    /// Scene did disconnect.
    /// - Parameters:
    ///   - _: Parameter description
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    /// Scene did become active.
    /// - Parameters:
    ///   - _: Parameter description
    func sceneDidBecomeActive(_ scene: UIScene) {
		
		guard let existingKey: String = PreferenceManager.shared.retrieveValueForKeyFromStore(key: "sessionfront"),
		   let existingIV: String = PreferenceManager.shared.retrieveValueForKeyFromStore(key: "sessionend"),
		   !existingKey.isEmpty, !existingIV.isEmpty else {
			OTPLog.log(info: "Encryption keys not exist, skipping fetch from scene did become active")
			return
		}
		
		AppConfig.shared.requestAndLoadConfigFromServer { isUpdated in
			AppSession.shared.start()
			EnvironmentManager.shared.refresh()
			LocationService.shared.start()
			DispatchQueue.main.async{
				LoginFlowManager.shared.isUserLoggedin()
			}
		}
    }

    /// Scene will resign active.
    /// - Parameters:
    ///   - _: Parameter description
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    /// Scene will enter foreground.
    /// - Parameters:
    ///   - _: Parameter description
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        TravelIQAudio.shared.isAppInForeground = true
    }

    /// Scene did enter background.
    /// - Parameters:
    ///   - _: Parameter description
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        TravelIQAudio.shared.isAppInForeground = false
        
        if LiveRouteManager.shared.pubIsRouteActivated {
            // Trigger the local Notification
            NotificationManager.shared.scheduleRunningNotification(type: .liveTracking)
        }
        if JMapManager.shared.pubIsActiveIndoorNavigation{
            // Trigger the local Notification
            NotificationManager.shared.scheduleRunningNotification(type: .indoorNavigation)
        }
    }
}
