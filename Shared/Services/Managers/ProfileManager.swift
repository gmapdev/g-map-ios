//
//  ProfileManager.swift
//

import Foundation

enum ProfilePageState: String {
    case trips
    case settings
}

enum TripManagerViewState {
    case creation
    case update
    
    /// Is creation.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isCreation: Bool{
        switch self{
        case .creation: return true
        case .update : return false
        }
    }
}

class ProfileManager: ObservableObject {
	
    @Published var pubTripNotificationLoading: Bool = false
	@Published var pubPresentProfilePage = false
	@Published var pubPageState = ProfilePageState.settings
	@Published var pubShowTripList = true
    @Published var pubEditTripFromPlanTrip = false
    @Published var pubTripPageTitle: String = "My Trips".localized()
	
	// This is used to store and save the notification type
	@Published var pubNotificationType: [String] = ["email"]
	@Published var pubValidPhoneNumberLimit: Bool = true
    @Published var pubShowSearchLocationView: Bool = false
    @Published var pubHasConsentedToTerms: Bool = false
    @Published var pubStoreTripHistory: Bool = false
    @Published var pubShowProcessing: Bool = false
    @Published var pubShowCloseAlert: Bool = false
    
	@Published var pubNotificationPhoneNumber: String = ""
	
	/// Used to control the paginated trip list
	@Published var pubTripListOffset = 0
	@Published var pubLastTripListUpdate = Date().timeIntervalSince1970
    @Published var pubViewState = ProfileFavoritePlaceState.view
    @Published var isEmailOpen = false
    @Published var isSMSOpen = false
    @Published var isPushNotificationOpen = false
    @Published var isHapticFeedbackOpen = false
    
    // This is used to store Current User's Saved Trip ids, for later use for checking the trips is created by currentUser
    @Published var pubCurrentUsersTripIds: [String] = []     // [tripId1, tripId2,...]
	
	@Inject var notificationProvider:NotificationProvider
	
	// When we open the push in app and we assign this id to it, so that app can automatically open the saved trip page and the trip item
	var redirectSavedTripForPushByTripId = ""
	
    var tripNotificationList = [TripNotificationResponse]()
    var selectedTripNotification: TripNotificationResponse?
    var tripNotificationErrorMessage = ""
    
    var selectedItinerary: OTPItinerary?
    var selectedOldItinerary: OTPItinerary?
    var selectedGraphQLTripPlan: OTPPlanTrip?
    
    var tripManagerState: TripManagerViewState = .creation
    
    /// Shared.
    /// - Parameters:
    ///   - ProfileManager: Parameter description
    public static var shared: ProfileManager = {
        let mgr = ProfileManager()
        return mgr
    }()
    
    /// Open saved trip item by push.
    /// - Parameters:
    ///   - _: Parameter description
    /// Opens saved trip item by push.
    func openSavedTripItemByPush(_ userInfo: [AnyHashable: Any]){
		var notification_type = "1"
		if let nt = userInfo["notification_type"] as? String {
			notification_type = nt
		}
		
        if let trip_id = userInfo["trip_id"] as? String {
			if notification_type == "1" {	// regular push notification to open the saved trip
				if let _ = AppSession.shared.loginInfo {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
						openProfilePage(tripId: trip_id)
					}
				}
			}
			else if notification_type == "2" {	// open the survey from push notification.
				if let survey_subdomain = userInfo["survey_subdomain"] as? String,
				   let survey_id = userInfo["survey_id"] as? String {
					let notification_id = userInfo["notification_id"] as? String ?? ""
					let user_id = userInfo["user_id"] as? String ?? (AppSession.shared.loginInfo?.auth0UserId ?? "")
					let date_time = OTPUtils.convertTimestampToLocal(Date().timeIntervalSince1970)
                  
                    let endpointURL = BrandConfig.shared.base_url + SurveyEndPoint.openPushSurvey.url().endpoint
                    let survey_link = endpointURL + "?user_id=\(user_id)&trip_id=\(trip_id)&notification_id=\(notification_id)"
                    
					if let url = URL(string: survey_link) {
						if UIApplication.shared.canOpenURL(url) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						}else{
							OTPLog.log(level: .error, info: "notification type is 2, app is going to open the survey link. but it failed. link is: \(survey_link)")
						}
					}
				}else{
					OTPLog.log(level: .error, info: "notification type is 2, but survey_id is not available.")
				}
			}
        }
    }
    
    /// Open profile page.
    /// - Parameters:
    ///   - tripId: Parameter description
    /// Opens profile page.
    @MainActor func openProfilePage(tripId: String) {
        
        if LiveRouteManager.shared.pubIsPreviewMode {
            // if the Preview Mode is on, make it off
            LiveRouteManager.shared.dismissPreviewMode()
        }
        
        if LiveRouteManager.shared.pubIsRouteActivated {
            // If we are in the activated route mode, then, we disable it
            LiveRouteManager.shared.resetLiveTracking()
        }
        ProfileManager.shared.redirectSavedTripForPushByTripId = tripId
        TabBarMenuManager.shared.currentItemTab = .myTrips
        TabBarMenuManager.shared.currentViewTab = .myTrips
    }
    
    /// Clear selected trip info
    /// Clears selected trip info.
    public func clearSelectedTripInfo() {
        selectedItinerary = nil
        selectedGraphQLTripPlan = nil
	}
	
 /// Refresh trip list.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Void)? = nil)
	public func refreshTripList(_ completion:(()->Void)? = nil){
        self.tripNotificationErrorMessage = ""
		self.pubTripNotificationLoading = true
		self.tripNotificationList.removeAll()
		notificationProvider.retrieveMyTripList(offset: pubTripListOffset) { success, tripRequestResponse in
			self.pubTripNotificationLoading = false
			if let tRR = tripRequestResponse, success {
				let data = tRR.data
				let newData = DataHelper.composeTNRWithPreviewStepId(oldTNRs: data)
				self.tripNotificationList.append(contentsOf: newData)
                self.fetchEditableTripIds(for: newData)
			}else{
                self.tripNotificationErrorMessage = "Failed to retrieve the saved trip notification items".localized()
			}
			DispatchQueue.main.async {
				self.pubLastTripListUpdate = Date().timeIntervalSince1970
				completion?()
			}
		}
	}
    
    /// Is account settings updated
    /// - Returns: Bool
    /// Checks if account settings updated.
    public func isAccountSettingsUpdated() -> Bool{
        if let localUserInfo = AppSession.shared.loginInfo, let serverUserInfo = AppSession.shared.tempLoginInfo{
            return localUserInfo != serverUserInfo
        }
        return false
    }
    
    /// Get all alerts array.
    /// - Parameters:
    ///   - legs: Parameter description
    /// - Returns: [OTPAlert?]
    func getAllAlertsArray(legs: [OTPLeg]?) -> [OTPAlert?]{
        var returnAlerts: [OTPAlert?] = []
        if let legs = legs {
            for item in legs {
                if let alerts = item.alerts {
                    returnAlerts.append(contentsOf: alerts)
                }
            }
        }
        return returnAlerts
    }
    
    /// Fetch editable trip ids.
    /// - Parameters:
    ///   - for: Parameter description
    /// Fetches editable trip ids.
    func fetchEditableTripIds(for trips: [TripNotificationResponse]) {
        guard let currentUserId = AppSession.shared.loginInfo?.id else { return }
        
        pubCurrentUsersTripIds = trips
            .filter { $0.userId == currentUserId }
            .map { $0.id }
    }
    
    /// Is trip editable.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isTripEditable(_ trip: TripNotificationResponse) -> Bool {
        return pubCurrentUsersTripIds.contains(trip.id)
    }
}
