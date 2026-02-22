//
//  ProfileTripModel.swift
//

import Foundation

enum REALTIME_STATUS: String {
    case EARLY = "EARLY"
    case LATE = "LATE"
    case ON_TIME = "ON_TIME"
    case SCHEDULED = "SCHEDULED"
}

enum DayOfWeek {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
    
    /// Raw value.
    /// - Parameters:
    ///   - (name: Parameter description
    ///   - value: Parameter description
    var rawValue: (name: String, value: Int) {
        switch self {
        case .sunday: return ("Sunday", 1)
        case .monday: return ("Monday", 2)
        case .tuesday: return ("Tuesday", 3)
        case .wednesday: return ("Wednesday", 4)
        case .thursday: return ("Thursday", 5)
        case .friday: return ("Friday", 6)
        case .saturday: return ("Saturday", 7)
        }
    }
    
    /// Raw value:  string
    /// Initializes a new instance.
    /// - Parameters:
    ///   - rawValue: String
    init(rawValue: String) {
        switch rawValue.lowercased() {
        case "sunday": self = .sunday
        case "monday": self = .monday
        case "tuesday": self = .tuesday
        case "wednesday": self = .wednesday
        case "thursday": self = .thursday
        case "friday": self = .friday
        case "saturday": self = .saturday
        default: fatalError("Invalid day string: \(rawValue)")
        }
    }
}

enum CHOICE_OF_DAYS: String {
    case SELECTIVE_DAYS = "Selective Days"      // Options to select any particular days of week
    case DEFAULT_DAY = "Default Day"            // Just for default date(current day when saving a trip)
}

enum NotificationLeadingTime: Int{
    case mins15 = 15
    case mins30 = 30
    case mins45 = 45
    case mins1Hr = 60
    
    /// To label
    /// - Returns: String
    /// To label.
    func toLabel() -> String {
        return NotificationLeadingTime.toLabel(value: self.rawValue)
    }
    
    /// To label.
    /// - Parameters:
    ///   - value: Parameter description
    /// - Returns: String
    static func toLabel(value: Int) -> String {
        let valueMapping = NotificationLeadingTime.labelValueMapping()
        if let label = valueMapping[value] {
            return label
        }
        return "30 min (default)"
    }
    
    /// Label value mapping
    /// - Returns: [Int: String]
    /// Label value mapping.
    static private func labelValueMapping() -> [Int: String]{
        let valueMapping = [15: "15 min".localized(), 30: "30 min (default)".localized(), 45: "45 min".localized(), 60: "1 hour".localized()]
        return valueMapping
    }
    
    /// To value.
    /// - Parameters:
    ///   - label: Parameter description
    /// - Returns: Int
    static func toValue(label: String) -> Int {
        let valueMapping = NotificationLeadingTime.labelValueMapping()
        for key in valueMapping.keys {
            let lbl = NotificationLeadingTime.toLabel(value:key)
            if lbl == label {
                return key
            }
        }
        return 30
    }
}

enum NotificationDelayTime: Int{
    case mins5 = 5
    case mins10 = 10
    case mins15 = 15
    
    /// To label
    /// - Returns: String
    /// To label.
    func toLabel() -> String {
        return NotificationDelayTime.toLabel(value: self.rawValue)
    }
    
    /// To label.
    /// - Parameters:
    ///   - value: Parameter description
    /// - Returns: String
    static func toLabel(value: Int) -> String {
        let valueMapping = NotificationDelayTime.labelValueMapping()
        if let label = valueMapping[value] {
            return label
        }
        return "5 min (default)".localized()
    }
    
    /// Label value mapping
    /// - Returns: [Int: String]
    /// Label value mapping.
    static private func labelValueMapping() -> [Int: String]{
        let valueMapping = [5: "5 min (default)".localized(), 10: "10 min".localized(), 15: "15 min".localized()]
        return valueMapping
    }
    
    /// To value.
    /// - Parameters:
    ///   - label: Parameter description
    /// - Returns: Int
    static func toValue(label: String) -> Int {
        let valueMapping = NotificationDelayTime.labelValueMapping()
        for key in valueMapping.keys {
            let lbl = NotificationDelayTime.toLabel(value:key)
            if lbl == label {
                return key
            }
        }
        return 5
    }
}

class ProfileTripModel: ObservableObject{
    
    @Published var pubLastCheck = ""
    @Published var pubSnoozed = false
    @Published var pubIsActive = true
    @Published var pubJourneyStateTripStatus:String?
    @Published var pubCustomNameForTrip:String = ""
    @Published var pubRealtimeAlertNotification = "Yes (default)".localized()
    @Published var pubAlternativeRouteNotification = "Yes (default)".localized()
    @Published var pubDelayNotification = "5 min (default)".localized()
    @Published var pubAdvancedSetting = "30 min (default)".localized()
    @Published var pubRealTimeAlertDropdownItem = ["Yes (default)".localized(), "No".localized()]
    @Published var pubAlternativeRouteDropdownItem = ["Yes (default)".localized(), "No".localized()]
    @Published var pubDelayDropdownItem = [NotificationDelayTime.mins5.toLabel(),
                                           NotificationDelayTime.mins10.toLabel(),
                                           NotificationDelayTime.mins15.toLabel()]
    @Published var pubTitleText = "Loading...".localized()
    @Published var pubSubTitleText = ""
    @Published var pubAdvancedSettingDropdownItem = [NotificationLeadingTime.mins15.toLabel(),
                                                     NotificationLeadingTime.mins30.toLabel(),
                                                     NotificationLeadingTime.mins45.toLabel(),
                                                     NotificationLeadingTime.mins1Hr.toLabel()]
    @Published var pubWeekdays: [WeekdayslistItem] = []
    @Published var pubSelectedDaysOfTrip : CHOICE_OF_DAYS = .SELECTIVE_DAYS         // For the Selection of Repeating of Save Trip
    
    // Travel Companion
    @Published var pubCompanionOnThisTrip = "Select..."
    @Published var pubObserversOnthisTrip = ["Select..."]
    @Published var pubCompanionDropdownItem : [String] = []
    @Published var pubObserversDropdownitem : [String] = []
    
    // Trip Should be Editable or not
    @Published var pubisTripEditable = true         // This will decied weather User has permission to update the Trip or not.
    @Published var pubIsTripNameEmpty = false
    
    var temporaryDaysOfTrip : [WeekdayslistItem]?
    
    @Inject var notificationProvider: NotificationProvider
    
    var id: String?
    var tripTime = ""
    var tripStartTimeText = ""
    var tripNotificationResponse: TripNotificationResponse?
    private let selectedDaysStoreKEY = "selected_days_while_saving_trip"
    var baselineArrivalTimeEpochMillis = 0.0
    
    /// Shared.
    /// - Parameters:
    ///   - ProfileTripModel: Parameter description
    public static var shared: ProfileTripModel = {
        let model = ProfileTripModel()
        model.initWeekDays()
        return model
    }()
    
    /// Init week days
    /// Init week days.
    func initWeekDays() {
        pubWeekdays = [WeekdayslistItem(name: self.getWeekDayName(dayName: "Mon.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Tue.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Wed.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Thu.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Fri.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Sat.".localized())),
                       WeekdayslistItem(name: self.getWeekDayName(dayName: "Sun.".localized()))]
    }
    /// Get week day name.
    /// - Parameters:
    ///   - dayName: Parameter description
    /// - Returns: String
    /// Retrieves week day name.
    public func getWeekDayName(dayName: String) -> String {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            switch dayName {
            case "Mon.".localized():
                return "Monday".localized()
            case "Tue.".localized():
                return "Tuesday".localized()
            case "Wed.".localized():
                return "Wednesday".localized()
            case "Thu.".localized():
                return "Thursday".localized()
            case "Fri.".localized():
                return "Friday".localized()
            case "Sat.".localized():
                return "Saturday".localized()
            case "Sun.".localized():
                return "Sunday".localized()
            default:
                return ""
            }
        } else {
            return dayName
        }
    }
    
    /// Clear trip model
    /// Clears trip model.
    public func clearTripModel(){
        self.id = nil
        self.pubSnoozed = false
        self.pubIsActive = true
        self.pubCustomNameForTrip = ""
        self.pubRealtimeAlertNotification = "Yes (default)".localized()
        self.pubAlternativeRouteNotification = "Yes (default)".localized()
        self.pubDelayNotification = "5 min (default)".localized()
        self.pubAdvancedSetting = "30 min (default)".localized()
        self.pubWeekdays = [
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Mon.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Tue.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Wed.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Thu.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Fri.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sat.".localized())),
            WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sun.".localized())),
        ]
        self.pubTitleText = "Loading...".localized()
        self.tripNotificationResponse = nil
        self.tripTime = ""
        self.tripStartTimeText = ""
    }
    
    /// Remove companion from observer list.
    /// - Parameters:
    ///   - companion: Parameter description
    /// Removes companion from observer list.
    func removeCompanionFromObserverList(companion: String) {
        var newList = TravelCompanionsViewModel.shared.getCompanionList()
        // Directly filter out the companion if it's in the list
        newList.removeAll { $0 == companion }
        pubObserversDropdownitem = newList
    }

    /// Remove observers from companion list.
    /// - Parameters:
    ///   - observers: Parameter description
    /// Removes observers from companion list.
    func removeObserversFromCompanionList(observers: [String]) {
        var newList = TravelCompanionsViewModel.shared.getCompanionList()
        // Filter out each observer from the list, only remove those that exist
        newList.removeAll { item in observers.contains(item) }
        pubCompanionDropdownItem = newList
    }
    
    /// Update trip model.
    /// - Parameters:
    ///   - _: Parameter description
    /// Updates trip model.
    public func updateTripModel(_ item: TripNotificationResponse){
        self.id = item.id
        self.pubSnoozed = item.snoozed
        self.pubIsActive = item.isActive
        self.pubCustomNameForTrip = item.tripName
        self.pubRealtimeAlertNotification = item.notifyOnAlert ? "Yes (default)".localized() : "No".localized()
        self.pubAlternativeRouteNotification = item.notifyOnItineraryChange ? "Yes (default)".localized() : "No".localized()
        self.pubDelayNotification = NotificationDelayTime.toLabel(value: item.departureVarianceMinutesThreshold)
        self.pubAdvancedSetting = NotificationLeadingTime.toLabel(value: item.leadTimeInMinutes)
        
        
        var monday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Mon.".localized()));monday.isChecked = item.monday
        var tuesday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Tue.".localized()));tuesday.isChecked = item.tuesday
        var wednesday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Wed.".localized()));wednesday.isChecked = item.wednesday
        var thursday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Thu.".localized()));thursday.isChecked = item.thursday
        var friday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Fri.".localized()));friday.isChecked = item.friday
        var saturday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sat.".localized()));saturday.isChecked = item.saturday
        var sunday = WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sun.".localized()));sunday.isChecked = item.sunday
        self.pubWeekdays = [monday, tuesday, wednesday, thursday, friday, saturday, sunday]
        self.pubTitleText = "Loading...".localized()
        self.tripNotificationResponse = item
        var lastCheckTimestamp = 0.0
        if let journeyState = item.journeyState {
            
            self.pubJourneyStateTripStatus = journeyState.tripStatus
            baselineArrivalTimeEpochMillis = Double(journeyState.baselineDepartureTimeEpochMillis)
            
            let time = Date(timeIntervalSince1970: baselineArrivalTimeEpochMillis/1000)
            let timeformatter = DateFormatter()
            timeformatter.timeZone = EnvironmentManager.shared.currentTimezone
            let language = SettingsManager.shared.appLanguage
            timeformatter.locale = Locale(identifier: language.languageCode())
            timeformatter.dateFormat = "HH:mm"
            let newTime = timeformatter.string(from: time)
            tripTime = newTime
            lastCheckTimestamp = Double(journeyState.lastCheckedEpochMillis/100)
        }
        let diffTimestamp = (Date().timeIntervalSince1970 - lastCheckTimestamp)/60
        let lastCheck = Helper.shared.formatReadableMins(mins: Int(diffTimestamp))
        self.pubLastCheck = "Last checked: %1".localized((diffTimestamp < 1 ? "just now".localized() : "%1 ago".localized(lastCheck) ))
        
        
        // Update Travel Companion/Observers is Selected before
        if let companion = item.companion {
            if let companionEmail = companion.email{
                self.pubCompanionOnThisTrip = companionEmail
                self.removeCompanionFromObserverList(companion: companionEmail)
            }
        } else{
            self.pubCompanionOnThisTrip = "Select..."
            self.pubObserversDropdownitem = TravelCompanionsViewModel.shared.getCompanionList()
        }
        
        if let observers = item.observers{
            self.pubObserversOnthisTrip.removeAll()
            for item in observers{
                if let observerEmail = item.email{
                    self.pubObserversOnthisTrip.append(observerEmail)
                }
            }
            self.removeObserversFromCompanionList(observers: pubObserversOnthisTrip)
        } else{
            self.pubObserversOnthisTrip = ["Select..."]
            self.pubCompanionDropdownItem = TravelCompanionsViewModel.shared.getCompanionList()
        }
        self.pubCompanionDropdownItem = TravelCompanionsViewModel.shared.getCompanionList()
        self.pubObserversDropdownitem = TravelCompanionsViewModel.shared.getCompanionList()
    }
    
    /// Edit trip notification header
    /// Edit trip notification header.
    public func editTripNotificationHeader(){
        if self.pubIsActive && !(self.pubSnoozed) {
            let notifyTime = self.tripTime.split(separator: ":")
            var hours = 0
            var minutes = 0
            if notifyTime.count == 2 {
                hours = Int(notifyTime[0]) ?? 0
                minutes = Int(notifyTime[1]) ?? 0
            }
            var suffix = " am"
            if hours >= 12 { suffix = " pm" }
            
            let startDateTime = (hours>12 ? "\(hours-12)" : "\(hours)") + ":" + (minutes<10 ? "0\(minutes)" : "\(minutes)") + suffix
            let leadingMinutes = NotificationLeadingTime.toValue(label: self.pubAdvancedSetting)
            let startDateTimestamp = baselineArrivalTimeEpochMillis
            let notifyDateTimestamp = startDateTimestamp - Double(leadingMinutes*60000)
            
            let notifyDate = notifyDateTimestamp.milliSecondsTimeToConfigTimeZone()
            tripStartTimeText = startDateTime
            self.pubTitleText = "Loading...".localized()
            self.pubSubTitleText = "Trip is due to begin at %1 (realtime monitoring will begin at %2)".localized(startDateTime, notifyDate)
            if let item = self.tripNotificationResponse {
                // MARK: here is the first call
                self.checkItinerary(item)
            }else{
                self.pubTitleText = "No trip information can be found".localized()
            }
        }
        else if !self.pubIsActive {
            self.pubTitleText = "Trip monitoring is paused".localized()
            self.pubSubTitleText = "Resume trip monitoring to see the updated status".localized()
        }
        else if self.pubSnoozed {
            self.pubTitleText = "Trip monitoring is paused for today".localized()
            self.pubSubTitleText = "Resume trip monitoring to see the updated status".localized()
        }
        else{
            self.pubTitleText = "Unknown Status".localized()
            self.pubSubTitleText = "Not Available".localized()
        }
    }
    
    /// Store notification to server.
    /// - Parameters:
    ///   - creation: Parameter description
    ///   - completion: Parameter description
    ///   - String: Parameter description
    /// - Returns: Void))
    public func storeNotificationToServer(creation: Bool ,completion:@escaping ((Bool, String)->Void)){
        guard let itinerary = ProfileManager.shared.selectedItinerary, let tripPlan = ProfileManager.shared.selectedGraphQLTripPlan else {
            completion(false, "no itinerary information, update failed".localized())
            return
        }
        let leadTimeInMinutes = NotificationLeadingTime.toValue(label: pubAdvancedSetting)
        let minutesThreshold = NotificationDelayTime.toValue(label: pubDelayNotification)
        let userId = AppSession.shared.loginInfo?.id ?? ""
        let alert = pubRealtimeAlertNotification == "Yes (default)".localized()
        let notifyChange = pubAlternativeRouteNotification == "Yes (default)".localized()
        var tripNotification: [String: Any] = [:]
        var itineraryObject: [String: Any] = [:]
        do {
            itineraryObject = try DataHelper.convertToDictionary(object: itinerary)
        } catch {
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
        var companionDict: [String: Any]?
        if let selectedCompanion = TravelCompanionsViewModel.shared.getCompanionObject(email: self.pubCompanionOnThisTrip){
            do {
                companionDict = try DataHelper.convertToDictionary(object: selectedCompanion)
            } catch {
                OTPLog.log(level: .error, info: "\(error.localizedDescription)")
            }
        }

        // This won't work beacuse Observers should be in array format
        var observerDict: [[String: Any]]?
        if let selectedObserver = TravelCompanionsViewModel.shared.getObserversObject(observers: self.pubObserversOnthisTrip){
            do {
                let observerData = try JSONEncoder().encode(selectedObserver)
                if let jsonData = try JSONSerialization.jsonObject(with: observerData, options: []) as? [[String: Any]]? {
                    observerDict = jsonData
                }
            } catch {
                OTPLog.log(level: .error, info: "\(error.localizedDescription)")
            }
        }
        
        if creation == false{
            if let tripNotificationResponse = tripNotificationResponse {
                tripNotification = prepareRequestData(id: id ?? "", minutesThreshold: minutesThreshold, isActive: pubIsActive, itineraryObject: itineraryObject, leadTimeInMinutes: leadTimeInMinutes, userId: userId, monday: pubWeekdays[0].isChecked, tuesday: pubWeekdays[1].isChecked, wednesday: pubWeekdays[2].isChecked, thursday: pubWeekdays[3].isChecked, friday: pubWeekdays[4].isChecked, saturday: pubWeekdays[5].isChecked, sunday: pubWeekdays[6].isChecked, tripName: pubCustomNameForTrip, snoozed: pubSnoozed, notifyChange: notifyChange, isCreation: false, notifyOnAlert: alert, otp2QueryParams: tripNotificationResponse.otp2QueryParams, companion: companionDict, observer: observerDict)
                
            }
        } else {
            if let otp2QueryParams = itinerary.otp2QueryParam {
                tripNotification = prepareRequestData(id: id ?? UUID().uuidString, minutesThreshold: minutesThreshold, isActive: pubIsActive, itineraryObject: itineraryObject, leadTimeInMinutes: leadTimeInMinutes, userId: userId, monday: pubWeekdays[0].isChecked, tuesday: pubWeekdays[1].isChecked, wednesday: pubWeekdays[2].isChecked, thursday: pubWeekdays[3].isChecked, friday: pubWeekdays[4].isChecked, saturday: pubWeekdays[5].isChecked, sunday: pubWeekdays[6].isChecked, tripName: pubCustomNameForTrip, snoozed: pubSnoozed, notifyChange: notifyChange, isCreation: true, notifyOnAlert: alert, otp2QueryParams: otp2QueryParams, companion: companionDict, observer: observerDict)
            }
        }
        let forCreation = ProfileManager.shared.tripManagerState == .creation
        self.notificationProvider.updateNotification(tripNotification: tripNotification, forCreation: forCreation ) { success, errorMessage in
            completion(success, errorMessage ?? "")
        }
    }
    
    
    /// Prepare request data.
    /// - Parameters:
    ///   - id: Parameter description
    ///   - minutesThreshold: Parameter description
    ///   - isActive: Parameter description
    ///   - itineraryObject: Parameter description
    ///   - leadTimeInMinutes: Parameter description
    ///   - userId: Parameter description
    ///   - monday: Parameter description
    ///   - tuesday: Parameter description
    ///   - wednesday: Parameter description
    ///   - thursday: Parameter description
    ///   - friday: Parameter description
    ///   - saturday: Parameter description
    ///   - sunday: Parameter description
    ///   - tripName: Parameter description
    ///   - snoozed: Parameter description
    ///   - notifyChange: Parameter description
    ///   - isCreation: Parameter description
    ///   - notifyOnAlert: Parameter description
    ///   - otp2QueryParams: Parameter description
    ///   - companion: Parameter description
    ///   - observer: Parameter description
    /// - Returns: [String: Any]
    func prepareRequestData(id: String, minutesThreshold: Int, isActive: Bool, itineraryObject: [String: Any], leadTimeInMinutes: Int, userId: String, monday: Bool, tuesday: Bool, wednesday: Bool, thursday: Bool, friday: Bool, saturday: Bool, sunday: Bool, tripName: String, snoozed: Bool, notifyChange: Bool, isCreation: Bool, notifyOnAlert: Bool, otp2QueryParams: PlanTripVariables?, companion: [String: Any]?, observer: [[String: Any]]?) -> [String: Any]{
        
        var jsonObject: [String: Any] = [:]
        var otp2QueryParamsDict: [String: Any] = [:]
        do {
            otp2QueryParamsDict = try DataHelper.convertToDictionary(object: otp2QueryParams)
        } catch {
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
        jsonObject["id"] = id
        jsonObject["arrivalVarianceMinutesThreshold"] = minutesThreshold
        jsonObject["departureVarianceMinutesThreshold"] = minutesThreshold
        jsonObject["otp2QueryParams"] = otp2QueryParamsDict
        jsonObject["excludeFederalHolidays"] = true
        jsonObject["isActive"] = isActive
        jsonObject["itinerary"] = itineraryObject
        jsonObject["leadTimeInMinutes"] = leadTimeInMinutes
        jsonObject["tripName"] = tripName
        jsonObject["userId"] = userId
        jsonObject["monday"] = monday
        jsonObject["tuesday"] = tuesday
        jsonObject["wednesday"] = wednesday
        jsonObject["thursday"] = thursday
        jsonObject["friday"] = friday
        jsonObject["saturday"] = saturday
        jsonObject["sunday"] = sunday
        jsonObject["companion"] = companion
        jsonObject["observers"] = observer
        if !isCreation {
            jsonObject["notifyOnItineraryChange"] = notifyChange
            jsonObject["notifyOnAlert"] = notifyOnAlert
            jsonObject["snoozed"] = snoozed
        }
        return jsonObject
    }
    
    /// Extrac avaliable weekday.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Date?
    private func extracAvaliableWeekday(_ weekday: WeekdaysAvaliability,_ HH: Int,_ mm: Int) -> Date? {
        if weekday.valid && weekday.validDates.count > 0 {
            let dateStr = weekday.validDates[0]
            let (year, month, day) = Helper.shared.extractYMD(from: dateStr)
            let newDate = Helper.shared.createDate(year: year, month: month, day: day, HH: HH, mm: mm, ss: 0)
            return newDate
        }
        return nil
    }
    
    /// Get render data.
    /// - Parameters:
    ///   - item: Parameter description
    /// Retrieves render data.
    func getRenderData(item: TripNotificationResponse) {
        if let journeyState = item.journeyState {
            let tripStatus = journeyState.tripStatus
            if tripStatus == "NEXT_TRIP_NOT_POSSIBLE" {
                nextTripNotPossibleRender(item: item)
            } else if !item.isActive {
                inactiveRender(item: item)
            } else if item.snoozed {
                snoozedRender(item: item)
            } else if tripStatus == "NO_LONGER_POSSIBLE" {
                noLongerPossibleRenderer(item: item)
            } else if tripStatus == "TRIP_UPCOMING" {
                upcomingTripRender(item: item)
            } else if tripStatus == "TRIP_ACTIVE" {
                activeTripRender(item: item)
            } else if tripStatus == "PAST_TRIP" {
                pastTripRender(item: item)
            } else {
                notYetCalculatedTripRender(item: item)
            }
        } else {
            notYetCalculatedTripRender(item: item)
        }
        
    }
    
    /// Upcoming trip render.
    /// - Parameters:
    ///   - item: Parameter description
    func upcomingTripRender(item: TripNotificationResponse) {
        if let journeyState = item.journeyState, let matchingItinerary = journeyState.matchingItinerary, let startTime = matchingItinerary.startTime {
            let startDate = Date(timeIntervalSince1970: TimeInterval((startTime) / 1000))
            let differenceInMinutes = Helper.shared.differenceInMinutes(from: startDate, to: Date.now)
            let oneMinute = 60 * 1000
            let tripStart = startTime
            let tripStartInDate = Date(timeIntervalSince1970: TimeInterval((tripStart) / 1000))
            let monitoringStart = tripStart - item.leadTimeInMinutes * oneMinute
            let monitoringStartInDate = Date(timeIntervalSince1970: TimeInterval((monitoringStart) / 1000))
            self.pubSubTitleText = "Trip is due to begin at \(Helper.shared.timeInPDT(from: tripStartInDate)). (Realtime monitoring will begin at \(Helper.shared.timeInPDT(from: monitoringStartInDate)).)"
            if(item.leadTimeInMinutes > differenceInMinutes) {
                self.pubTitleText = "Next trip starts on \(Helper.shared.dayName(from: tripStartInDate)) at \(Helper.shared.dateInPDT(from: tripStartInDate))."
                
            } else {
                if(journeyState.hasRealtimeData) {
                    let departureDeviationSeconds =
                            (startTime - Int(journeyState.scheduledDepartureTimeEpochMillis)) / 1000
                    let absDeviation = abs(departureDeviationSeconds)
                    let tripStatus = getTripStatus(isRealtime: true, delaySeconds: departureDeviationSeconds, onTimeThresholdSeconds: 60)
                    if tripStatus == REALTIME_STATUS.ON_TIME.rawValue {
                        self.pubTitleText = "Trip is starting soon and is about on time.".localized()
                    } else if tripStatus == REALTIME_STATUS.LATE.rawValue {
                        self.pubTitleText = "Trip start time is delayed %1!".localized(absDeviation)
                    } else {
                        self.pubTitleText = "Trip start time is happening %1 earlier than expected!".localized(abs(absDeviation))
                    }
                } else {
                    self.pubTitleText = "Trip is starting soon (no realtime updates available).".localized()
                }
            }
            
            
        }
       
    }
    
    /// Next trip not possible render.
    /// - Parameters:
    ///   - item: Parameter description
    func nextTripNotPossibleRender(item: TripNotificationResponse) {
        self.pubTitleText = "Unable to monitor trip".localized()
        self.pubSubTitleText = "After multiple failed attempts to locate your itinerary, monitoring has been snoozed for today as one or more changes to the itinerary may have occurred.  To resume trip monitoring, click Un-snooze. If monitoring is still not available, click Plan New Trip to save an up to date itinerary to monitor.".localized()
    }
    
    /// No longer possible renderer.
    /// - Parameters:
    ///   - item: Parameter description
    func noLongerPossibleRenderer(item: TripNotificationResponse) {
        self.pubTitleText = "Unable to monitor trip".localized()
        self.pubSubTitleText = "After multiple failed attempts to locate your itinerary, monitoring has been snoozed for today as one or more changes to the itinerary may have occurred.  To resume trip monitoring, click Un-snooze. If monitoring is still not available, click Plan New Trip to save an up to date itinerary to monitor.".localized()
    }
    
    /// Active trip render.
    /// - Parameters:
    ///   - item: Parameter description
    func activeTripRender(item: TripNotificationResponse) {
        if let journeyState = item.journeyState, journeyState.hasRealtimeData {
            if let journeyState = item.journeyState, let matchingItinerary = journeyState.matchingItinerary, let endTime = matchingItinerary.endTime {
                let scheduledArrivalTimeEpochMillis = journeyState.scheduledArrivalTimeEpochMillis
                let arrivalDeviationSeconds =
                (endTime - Int(scheduledArrivalTimeEpochMillis)) / 1000
                let tripStatus = getTripStatus(isRealtime: true, delaySeconds: arrivalDeviationSeconds, onTimeThresholdSeconds: 60)
                
                if tripStatus == REALTIME_STATUS.ON_TIME.rawValue {
                    self.pubTitleText = "Trip is in progress and is about on time.".localized()
                } else if tripStatus == REALTIME_STATUS.LATE.rawValue {
                    self.pubTitleText = "Trip is in progress and is delayed %1".localized(abs(arrivalDeviationSeconds))
                } else {
                    self.pubTitleText = "Trip is in progress and is arriving %1 earlier than expected!".localized(abs(arrivalDeviationSeconds))
                }
                
                let endDate = Date(timeIntervalSince1970: TimeInterval((endTime) / 1000))
                self.pubSubTitleText = "Trip is due to arrive at the destination at %1".localized(Helper.shared.timeInPDT(from: endDate))
            }
        } else {
            if let journeyState = item.journeyState, let matchingItinerary = journeyState.matchingItinerary, let endTime = matchingItinerary.endTime {
                let endDate = Date(timeIntervalSince1970: TimeInterval((endTime) / 1000))
                
                self.pubTitleText = "Trip is in progress (no realtime updates available)".localized()
                self.pubSubTitleText = "Trip is due to arrive at the destination at %1".localized(Helper.shared.timeInPDT(from: endDate))
            } else {
                self.pubTitleText = "Trip is in progress (no realtime updates available)".localized()
                self.pubSubTitleText = ""
            }
        }
        
    }
    
    /// Past trip render.
    /// - Parameters:
    ///   - item: Parameter description
    func pastTripRender(item: TripNotificationResponse) {
        self.pubTitleText = "Trip is in the past".localized()
        self.pubSubTitleText = "This is a one-time trip that occurred in the past.".localized()
    }
    
    /// Not yet calculated trip render.
    /// - Parameters:
    ///   - item: Parameter description
    func notYetCalculatedTripRender(item: TripNotificationResponse) {
        self.pubTitleText = "Trip not yet calculated".localized()
        self.pubSubTitleText = "Please wait a bit for the trip to calculate.".localized()
        self.pubLastCheck = "Awaiting calculation...".localized()
    }
    
    /// Snoozed render.
    /// - Parameters:
    ///   - item: Parameter description
    func snoozedRender(item: TripNotificationResponse) {
        self.pubTitleText = "Trip monitoring is paused for today".localized()
        self.pubSubTitleText = "Resume trip monitoring to see the updated status".localized()
    }
    
    /// Inactive render.
    /// - Parameters:
    ///   - item: Parameter description
    func inactiveRender(item: TripNotificationResponse) {
        self.pubTitleText = "Trip monitoring is paused".localized()
        self.pubSubTitleText = "Resume trip monitoring to see the updated status".localized()
    }
    
    /// Get trip status.
    /// - Parameters:
    ///   - isRealtime: Parameter description
    ///   - delaySeconds: Parameter description
    ///   - onTimeThresholdSeconds: Parameter description
    /// - Returns: String
    func getTripStatus(isRealtime: Bool, delaySeconds: Int, onTimeThresholdSeconds: Int) -> String{
      if (isRealtime) {
        if (delaySeconds > onTimeThresholdSeconds) {
          // late departure
            return REALTIME_STATUS.LATE.rawValue
        } else if (delaySeconds < -onTimeThresholdSeconds) {
          // early departure
          return REALTIME_STATUS.EARLY.rawValue
        } else {
          // on-time departure
          return REALTIME_STATUS.ON_TIME.rawValue
        }
      } else {
        // Schedule only
        return REALTIME_STATUS.SCHEDULED.rawValue
      }
    }
    
    /// Check itinerary.
    /// - Parameters:
    ///   - _: Parameter description
    /// Checks itinerary.
    public func checkItinerary(_ item: TripNotificationResponse){
        if let tripNotification = ProfileManager.shared.selectedTripNotification {
            if let itineraryExistence = tripNotification.itineraryExistence {
                /// Update title text.
                /// - Parameters:
                ///   - info: Parameter description
                /// Updates title text.
                func updateTitleText(info: String){
                    if self.pubIsActive && !(self.pubSnoozed) {
                        self.pubTitleText = info
                    }
                }
                
                    let notifyTime = self.tripTime.split(separator: ":")
                    var hours = 0
                    var minutes = 0
                    if notifyTime.count == 2 {
                        hours = Int(notifyTime[0]) ?? 0
                        minutes = Int(notifyTime[1]) ?? 0
                    }
                    var retWeekdays = [Date]()
                    if let date = self.extracAvaliableWeekday(itineraryExistence.monday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.tuesday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.wednesday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.thursday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.friday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.saturday, hours, minutes) { retWeekdays.append(date) }
                    if let date = self.extracAvaliableWeekday(itineraryExistence.sunday, hours, minutes) { retWeekdays.append(date) }
                
                    let currentTimestamp = Date().timeIntervalSince1970
                    /// Initializes a new instance.
                    var minDiff: Double = Double.greatestFiniteMagnitude
                    var validDate: Date?
                    for i in 0..<retWeekdays.count {
                        let diff = retWeekdays[i].timeIntervalSince1970 - currentTimestamp
                        
                        if diff < minDiff && diff > 0 {
                            validDate = retWeekdays[i]
                            minDiff = diff
                        }
                    }
                    
                    if let availableDate = validDate {
                        let calendar = Calendar.current
                        let weekdayText = self.nextAvailableDay(item: item)
                        let dateText = self.getDateFromDayName(weekdayText)
                        
                        
                        let leading = NotificationLeadingTime.toValue(label: self.pubAdvancedSetting)
                        if minDiff < Double(leading*60) {
                            updateTitleText(info: "Trip is starting soon (no realtime updates available).".localized())
                        }else{
                            updateTitleText(info: "Next trip starts on %1 %2 at %3".localized(weekdayText, dateText , self.tripStartTimeText))
                        }
                    }else{
                        updateTitleText(info: "Trip is not possible today".localized())
                    }
                
            }
        }
    }
    
    /// Next available day.
    /// - Parameters:
    ///   - item: Parameter description
    /// - Returns: String
    func nextAvailableDay(item: TripNotificationResponse) -> String {
        var availableDays: [String] = []
        if item.monday {
            availableDays.append("Monday")
        }
        if item.tuesday {
            availableDays.append("Tuesday")
        }
        if item.wednesday {
            availableDays.append("Wednesday")
        }
        if item.thursday {
            availableDays.append("Thursday")
        }
        if item.friday {
            availableDays.append("Friday")
        }
        if item.saturday {
            availableDays.append("Saturday")
        }
        if item.sunday {
            availableDays.append("Sunday")
        }
        var returnDay = ""
        let today = Date()
        let formatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        formatter.dateFormat = "EEEE"
        
        let dayName = formatter.string(from: today)
        if let todayIndex = availableDays.firstIndex(of: dayName) {
            // Calculate the index of the next day
            let nextDayIndex = (todayIndex + 1) % availableDays.count
            returnDay = availableDays[nextDayIndex]
        }
        return returnDay
    }
    
    /// Get date from day name.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    func getDateFromDayName(_ dayName: String) -> String {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let targetWeekday = getWeekdayNumber(from: dayName)
        
        var daysToAdd = (targetWeekday - weekday + 7) % 7
        if daysToAdd == 0 {
            daysToAdd = 7
        }
        
        if let date = calendar.date(byAdding: .day, value: daysToAdd, to: today) {
            let formatter = DateFormatter()
            let language = SettingsManager.shared.appLanguage
            formatter.locale = Locale(identifier: language.languageCode())
            formatter.dateFormat = "MM/dd/yyyy"
            return formatter.string(from: date)
        }
        
        return "Invalid day name"
    }
    
    /// Get weekday number.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: Int
    func getWeekdayNumber(from dayName: String) -> Int {
        let formatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        formatter.dateFormat = "EEEE"
        if let date = formatter.date(from: dayName) {
            return Calendar.current.component(.weekday, from: date)
        }
        return 0
    }
    
    /// Get location from coordinates.
    /// - Parameters:
    ///   - locationStirng: Parameter description
    ///   - completion: Parameter description
    /// - Returns: Void))
    func getLocationFromCoordinates(locationStirng: String, completion:@escaping ((_ autoComplete : Autocomplete.Feature?)->Void)) {
        let components = locationStirng.components(separatedBy: "::")
        let coordinateString = components.count > 1 ? components[1] : "Unknown"
        if coordinateString != "Unknown" && coordinateString.contains(",") {
            let locationArray = coordinateString.components(separatedBy: ",")
            if locationArray.count == 2 {
                if let lat = Double(locationArray[0]) , let lon = Double(locationArray[1]) {
                    MapManager.shared.reverseLocation(latitude: lat, longitude: lon) { autoComplete in
                        if let autocomplete = autoComplete {
                            for feature in autocomplete.features {
                                if let geometry = feature.geometry, let coordinate = geometry.coordinate {
                                    let featureLat = coordinate.latitude
                                    let featureLon = coordinate.longitude
                                    if featureLat == lat && featureLon == lon {
                                        completion(feature)
                                    }
                                }
                            }
                            if !autocomplete.features.isEmpty {
                                completion(autocomplete.features[0])
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Combined date time.
    /// - Parameters:
    ///   - dateString: Parameter description
    ///   - timeString: Parameter description
    /// - Returns: Date
    func combinedDateTime(dateString: String, timeString: String) -> Date {
        let combinedString = "\(dateString) \(timeString)"
        
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let combinedDate = dateFormatter.date(from: combinedString) {
            return combinedDate
        } else {
            // Handle invalid date/time format
            return Date()
        }
    }
    
    /// Check availability and checked status
    /// - Returns: Bool
    /// Checks availability and checked status.
    func checkAvailabilityAndCheckedStatus() -> Bool {
        let availableDays = self.pubWeekdays.filter { $0.isAvaliable }
        
        if availableDays.isEmpty {
            return false
        }
        for day in availableDays {
            if day.isChecked {
                return true
            }
        }
        return false
    }
    
    /// Update days selection
    /// Updates days selection.
    func updateDaysSelection() {
        for index in self.pubWeekdays.indices {
            if self.pubWeekdays[index].isAvaliable {
                self.pubWeekdays[index].isChecked = false
            }
        }
    }
    
    /// The default datefor saving trip
    /// - Returns: String
    /// The default datefor saving trip.
    func theDefaultDateforSavingTrip() -> String{
        
        if ProfileManager.shared.tripManagerState == .update{
            let startTime = ProfileManager.shared.selectedItinerary?.startTime
            return Helper.shared.formatTimeIntervaltoShortDate(timeInterval: startTime)
        }else{
            let dateSettings = SearchManager.shared.dateSettings
            let fd = Helper.shared.formatLocalTimeZoneDatetoDayDate(date: Date())
    
            var date: String = fd
            if let departAt = dateSettings.departAt {
                let fd = Helper.shared.formatLocalTimeZoneDatetoDayDate(date: departAt)
                date = fd
            }else if let arriveBy = dateSettings.arriveBy {
                let fd = Helper.shared.formatLocalTimeZoneDatetoDayDate(date: arriveBy)
                date = fd
            }else if let selectedTime = dateSettings.time {
                let fd = Helper.shared.formatLocalTimeZoneDatetoDayDate(date: selectedTime)
                date = fd
            }
            return date
        }
    }
}

struct WeekdayslistItem: Identifiable {
    let id = UUID()
    var name: String
    var isChecked: Bool = false
    var isAvaliable: Bool = true
}
