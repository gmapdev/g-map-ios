//
//  IndoorNavigationManager.swift
//

import Foundation
import SwiftUI

class IndoorNavigationManager: NSObject,ObservableObject {
    
    @Published var pubEnabledIndoorLog = false
    @Published var pubPresentSearchPanel = false
    @Published var pubPresentIndoorNavigationView = false
    @Published var pubPresentIndoorNavDialog = false
    @Published var pubSimulateIndoorNavigation = false
    @Published var pubPresentIndoorDeviationDialog = false
    @Published var pubPresentIndoorExitDirectionDialog = false
    @Published var pubIndoorExitDialogBoxMessage : String?
    // This will updated by Triggerable/Detected loctions and will pass to JMap SDK to Re-Initialize
    @Published var pubJMapVenueId: Int32 = 2450 // Defualt GJAC
    
    @Published var pubPresentIndoorEntranceDialog = false
    @Published var pubIndoorEntranceDialogTitle: String?
    @Published var pubIndoorEntranceDialogMessage: String?
    
    @Inject var auth0Provider: LoginAuthProvider
    
    let indoorExitDialogBoxMessage = "It appears you have arrived at a building exit. Please choose from the following:"
    var indoorExitEntranceDialogPresented = false
    var originFocused: Bool = false
    var destinationFocused: Bool = true
    var extend: Extend?
    
    /// Shared.
    /// - Parameters:
    ///   - IndoorNavigationManager: Parameter description
    public static var shared: IndoorNavigationManager = {
        let mgr = IndoorNavigationManager()
        return mgr
    }()
    
    /// Start indoor extends s d k
    /// Starts indoor extends sdk.
    public func startIndoorExtendsSDK(){
        let key = FeatureConfig.shared.extends_sdk_key_ios
        let url = FeatureConfig.shared.extends_sdk_url
        self.extend = Extend.sharedExtend(withKey: key, url: url, delegate: IndoorNavigationManager.shared)
    }
    
    /// Stop indoor extends s d k
    /// Stops indoor extends sdk.
    public func stopIndoorExtendsSDK(){
        self.extend?.stop()
        self.extend = nil
    }
    
    /// Open saved trips
    /// Opens saved trips.
    func openSavedTrips(){
        self.stopIndoorExtendsSDK()
        self.pubPresentIndoorNavigationView = false
        JMapManager.shared.stopUniversalTimer()
        auth0Provider.getUserInfo {
            DispatchQueue.main.async {
                ProfileManager.shared.pubShowProcessing = false
                if let _ = AppSession.shared.loginInfo {
                    if LoginFlowManager.shared.pageState == .verifyEmail ||
                        LoginFlowManager.shared.pageState == .launchSetup {
                        LoginFlowManager.shared.pubPresentLoginPage = true
                    }else{
                        ProfileManager.shared.pubPageState = .trips
                        ProfileManager.shared.pubShowTripList = true
                        TabBarMenuManager.shared.currentViewTab = .myTrips
                        TabBarMenuManager.shared.currentItemTab = .myTrips
                    }
                }else{
                    LoginFlowManager.shared.pageState = .login
                    LoginFlowManager.shared.pubPresentLoginPage = true
                }
            }
        }
    }
}


extension IndoorNavigationManager: OnExtendDelegate {
    /// On ready.
    /// - Parameters:
    ///   - _: Parameter description
    /// Handles ready.
    func onReady(_ ready: Bool) {
        OTPLog.log(level: .info, info: "Indoor Navigation Ready:\(ready)")
    }
    
    /// On key validation.
    /// - Parameters:
    ///   - _: Parameter description
    /// Handles key validation.
    func onKeyValidation(_ validated: Bool) {
        OTPLog.log(level: .info, info: "Indoor Navigation Velidation Ready:\(validated)")
        if validated {
            // If key is validate start Extends SDK.
            /// Initializes a new instance.
            self.extend?.setVicinityEnabled(true)
            self.extend?.start()
        }
    }
    
    //MARK: - This Function will called by SDK - 32Hz (1/32 seconds)
    /// Handles navigation update.
    /// - Parameters:
    ///   - navOutput: TDNavOutput
    func onNavigationUpdate(_ navOutput: TDNavOutput) {

        if !pubSimulateIndoorNavigation {
            // Updating the Current Location on Indoor Map
            JMapManager.shared.updateUserLocation(lat: navOutput.latitude, lon: navOutput.longitude, floor: Int(navOutput.floor))
        }
    }
    
    /// On facility update name.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - onFacilityUpdate: Parameter description
    ///   - onFacilityUpdateFloorPlans: Parameter description
    ///   - onFacilityUpdateCategories: Parameter description
    func onFacilityUpdateName(_ name: String?, onFacilityUpdate location: Location?, onFacilityUpdate region: Region?, onFacilityUpdateFloorPlans plans: [Any]?, onFacilityUpdateCategories categories: [Any]?) {
        // Note in Use
        OTPLog.log(level: .info, info: "onFacilityUpdateName() called from Extends SDK ")
    }
    
    // For Logging feature
    
    /// Enable logs.
    /// - Parameters:
    ///   - enabled: Parameter description
    func enableLogs(enabled: Bool = false){
        extend?.setLogWriting(enabled)
    }
    
    /// Upload logs
    /// Upload logs.
    func uploadLogs() {
        extend?.uploadLogs()
    }
    
    /// Delete logs
    /// Deletes logs.
    func deleteLogs() {
        extend?.deleteLogs()
    }
}
