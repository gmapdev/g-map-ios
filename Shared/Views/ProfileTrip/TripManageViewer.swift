//
//  TripManageViewer.swift
//

import SwiftUI

struct TripManageViewer: View {
    
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject var viewModel = ProfileTripModel.shared
    @ObservedObject var tabBarMenuManager = TabBarMenuManager.shared
    
    @State var showAdvancedSettings: Bool = false
    @State var presentProcessingView: Bool = false
    @State var presentDaysProcessingView: Bool = false
    
    @Inject var notificationProvider: NotificationProvider
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return
            ZStack{
                ScrollView(showsIndicators: false){
                    if profileManager.tripManagerState == .update {
                        VStack{
                            HStack{
                                TextLabel("Trip information".localized(), .bold, .title2)
                                    .foregroundColor(Color.black)
                                Spacer()
                            }
                            .padding(.top, 10)
                            HStack{
                                TextLabel("Fields marked with an asterisk (*) are required.", .regular, .footnote)
                                    .foregroundStyle(Color.gray)
                                Spacer()
                            }
                        }
                        
                        NextTripInformationView()
                    }else{
                        TripManageHeaderView()
                    }
                    TripInformationView()
                    TripNameView()
                        if presentDaysProcessingView{
                                HStack{
                                    Spacer()
                                    VStack{
                                        ActivityIndicator(isAnimating: .constant(true), style: AccessibilityManager.shared.pubIsLargeFontSize ? .large : .medium)
                                        TextLabel("Checking itinerary existence for each day of the week".localized(), .semibold, .footnote)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                }
                                .padding(5)
                                .roundedBorder(5, 0)
                            .frame(minHeight: 60)
                            .background(Color.white)
                            .offset(y: -10)
                        } else {
                            WeekdaysListView()
                        }
                    TripNotificationView()
                    SavingTripTravelCompanions()
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        TripManageFooterButtonAODA()
                    } else {
                        TripManageFooterButton()
                    }
                }
                .padding(.horizontal, 20)

                .onAppear {
                    // MARK: here is the second call
                    if profileManager.tripManagerState == .update{
                        updateDays()
                    } else {
                        checkItinerary()
                    }
                }
                if self.presentProcessingView {
                    LoadingViewFullPage(showBackground: true)
                }
            }.zIndex(9998)
    }
    
    /// Check itinerary
    /// Checks itinerary.
    func checkItinerary(){
        presentDaysProcessingView = true
        guard let itinerary = profileManager.selectedItinerary, let tripPlan = profileManager.selectedGraphQLTripPlan else {
            return
        }
        let userId = AppSession.shared.loginInfo?.id ?? ""
        let leadTimeInMinutes = NotificationLeadingTime.toValue(label: viewModel.pubAdvancedSetting)
        let minutesThreshold = NotificationDelayTime.toValue(label: viewModel.pubDelayNotification)
        let isActive = viewModel.pubIsActive
        if let otp2QueryParams = itinerary.otp2QueryParam {
            let response = prepareRequestData(minutesThreshold: minutesThreshold, isActive: isActive, itineraryObject: itinerary, leadTimeInMinutes: leadTimeInMinutes, userId: userId, otp2QueryParams: otp2QueryParams)
            
            notificationProvider.checkDaysAvailibility(jsonItinerary: response) { result, response in
                let temp = viewModel.pubWeekdays
                if let data = response{
                    viewModel.pubWeekdays.removeAll()
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Mon."), isChecked: profileManager.tripManagerState == .update ? temp[0].isChecked : data.monday.valid, isAvaliable: data.monday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Tue."), isChecked: profileManager.tripManagerState == .update ? temp[1].isChecked : data.tuesday.valid, isAvaliable: data.tuesday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Wed."), isChecked: profileManager.tripManagerState == .update ? temp[2].isChecked : data.wednesday.valid, isAvaliable: data.wednesday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Thu."), isChecked: profileManager.tripManagerState == .update ? temp[3].isChecked : data.thursday.valid, isAvaliable: data.thursday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Fri."), isChecked: profileManager.tripManagerState == .update ? temp[4].isChecked : data.friday.valid, isAvaliable: data.friday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sat."), isChecked: profileManager.tripManagerState == .update ? temp[5].isChecked : data.saturday.valid, isAvaliable: data.saturday.valid))
                    viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sun."), isChecked: profileManager.tripManagerState == .update ? temp[6].isChecked : data.sunday.valid, isAvaliable: data.sunday.valid))
                    
                    // Storing the selection of days in Temporary variable
                    viewModel.temporaryDaysOfTrip?.removeAll()
                    viewModel.temporaryDaysOfTrip = viewModel.pubWeekdays
                }
                // If not selected any Days, switch to Default day
                if !viewModel.checkAvailabilityAndCheckedStatus(){
                    viewModel.pubSelectedDaysOfTrip = .DEFAULT_DAY
                }
                presentDaysProcessingView = false
            }
        }
    }
    
    /// Update days
    /// Updates days.
    func updateDays() {
        let temp = viewModel.pubWeekdays
        presentDaysProcessingView = true
        if let tripNotification = profileManager.selectedTripNotification, let availibility = tripNotification.itineraryExistence {
            viewModel.pubWeekdays.removeAll()
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Mon."), isChecked: profileManager.tripManagerState == .update ? temp[0].isChecked : tripNotification.monday, isAvaliable: availibility.monday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Tue."), isChecked: profileManager.tripManagerState == .update ? temp[1].isChecked : tripNotification.tuesday, isAvaliable: availibility.tuesday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Wed."), isChecked: profileManager.tripManagerState == .update ? temp[2].isChecked : tripNotification.wednesday, isAvaliable: availibility.wednesday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Thu."), isChecked: profileManager.tripManagerState == .update ? temp[3].isChecked : tripNotification.thursday, isAvaliable: availibility.thursday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Fri."), isChecked: profileManager.tripManagerState == .update ? temp[4].isChecked : tripNotification.friday, isAvaliable: availibility.friday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sat."), isChecked: profileManager.tripManagerState == .update ? temp[5].isChecked : tripNotification.saturday, isAvaliable: availibility.saturday.valid))
            viewModel.pubWeekdays.append(WeekdayslistItem(name: ProfileTripModel.shared.getWeekDayName(dayName: "Sun."), isChecked: profileManager.tripManagerState == .update ? temp[6].isChecked : tripNotification.sunday, isAvaliable: availibility.sunday.valid))
            
            // Storing the selection of days in Temporary variable
            viewModel.temporaryDaysOfTrip?.removeAll()
            viewModel.temporaryDaysOfTrip = viewModel.pubWeekdays
        }
        // If not selected any Days, switch to Default day
        if !viewModel.checkAvailabilityAndCheckedStatus(){
            viewModel.pubSelectedDaysOfTrip = .DEFAULT_DAY
        }
        presentDaysProcessingView = false
    }
    
    /// Prepare request data.
    /// - Parameters:
    ///   - minutesThreshold: Parameter description
    ///   - isActive: Parameter description
    ///   - itineraryObject: Parameter description
    ///   - leadTimeInMinutes: Parameter description
    ///   - userId: Parameter description
    ///   - otp2QueryParams: Parameter description
    /// - Returns: [String: Any]
    func prepareRequestData(minutesThreshold: Int, isActive: Bool, itineraryObject: OTPItinerary, leadTimeInMinutes: Int, userId: String, otp2QueryParams: PlanTripVariables) -> [String: Any]{
        var jsonObject: [String: Any] = [:]
        var otp2QueryParamsDict: [String: Any] = [:]
        do {
            otp2QueryParamsDict = try DataHelper.convertToDictionary(object: otp2QueryParams)
        } catch {
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }

        var itineraryDict: [String: Any] = [:]
        do {
            itineraryDict = try DataHelper.convertToDictionary(object: itineraryObject)
        } catch {
            OTPLog.log(level: .error, info: "\(error.localizedDescription)")
        }
        jsonObject["arrivalVarianceMinutesThreshold"] = minutesThreshold
        jsonObject["departureVarianceMinutesThreshold"] = minutesThreshold
        jsonObject["otp2QueryParams"] = otp2QueryParamsDict
        jsonObject["excludeFederalHolidays"] = true
        jsonObject["isActive"] = isActive
        jsonObject["itinerary"] = itineraryDict
        jsonObject["leadTimeInMinutes"] = leadTimeInMinutes
        jsonObject["tripName"] = ""
        jsonObject["userId"] = userId
        jsonObject["monday"] = true
        jsonObject["tuesday"] = true
        jsonObject["wednesday"] = true
        jsonObject["thursday"] = true
        jsonObject["friday"] = true
        jsonObject["saturday"] = false
        jsonObject["sunday"] = false
        return jsonObject
    }
    
    /// Next trip information view
    /// - Returns: some View
    /// Next trip information view.
    func NextTripInformationView() -> some View {
        return VStack{
            VStack{
                VStack{
                    HStack{
                        TextLabel(self.viewModel.pubTitleText).font(.title3).foregroundColor(Color.black)
                        Spacer()
                    }
                    HStack{
                        TextLabel(self.viewModel.pubLastCheck).font(.subheadline).foregroundColor(Color.black)
                        Spacer()
                    }
                }.padding(10)
            }
            /// Hex: "# d d d d d d")
            /// Initializes a new instance.
            /// - Parameters:

            ///   - Color.init(hex: "#DDDDDD"
            .background(Color.init(hex: "#DDDDDD"))
            VStack{
                HStack{
                    TextLabel(self.viewModel.pubSubTitleText)
                        .font(.body)
                    Spacer()
                }
                .padding(10)
            }
            .padding(.top,5)
            
            if viewModel.pubIsActive && !(viewModel.pubSnoozed) {
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    snoozViewAODA.padding(.horizontal, 10)
                } else {
                    snoozView
                }
            }
            else if !viewModel.pubIsActive {
                HStack{
                    Spacer().frame(width:10)
                    Button(action: {
                        viewModel.pubIsActive.toggle()
                        if let item = profileManager.selectedTripNotification {
                            viewModel.getRenderData(item: item)
                        }
                    }, label: {
                        HStack{
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            TextLabel("Resume".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.resumeButton.rawValue.localized())
                    Spacer()
                }
            }
            else if viewModel.pubSnoozed {
                HStack{
                    Spacer().frame(width:10)
                    Button(action: {
                        viewModel.pubSnoozed.toggle()
                        if let item = profileManager.selectedTripNotification {
                            viewModel.getRenderData(item: item)
                        }
                    }, label: {
                        HStack{
                            Image(systemName: "play.fill")
                                .font(.system(size: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 14))
                            TextLabel("Unsnooze".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.unSnoozeButton.rawValue.localized())
                    
                    if viewModel.pubJourneyStateTripStatus == "NEXT_TRIP_NOT_POSSIBLE"{
                        Button(action: {
                            planNewTrip()
                        }, label: {
                            HStack{
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                TextLabel("Plan New Trip".localized())
                                    .font(.body)
                            }.roundedBorder()
                        })
                        .addAccessibility(text: AvailableAccessibilityItem.planTripButton.rawValue.localized())
                    }
                    Spacer()
                }
            }
            
            Spacer().frame(height:15)
        }
        .border(Color.gray, width: 1)
    }
    
    /// Snooz view.
    /// - Parameters:
    ///   - some: Parameter description
    var snoozView: some View {
        HStack{
            Spacer().frame(width:10)
            if viewModel.pubTitleText.contains("Failed to retrieve the next trip start information".localized()) {
                HStack{
//                    Spacer().frame(width:10)
                    Button(action: {
                        viewModel.pubSnoozed.toggle()
                        if let item = profileManager.selectedTripNotification {
                            viewModel.getRenderData(item: item)
                        }
                    }, label: {
                        HStack{
                            Image(systemName: "play.fill")
                                .font(.system(size: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 14))
                            TextLabel("Unsnooze".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.unSnoozeButton.rawValue.localized())
                    .disabled(!viewModel.pubisTripEditable)
                    .accessibilityRemoveTraits(.isButton)
                    
                    Button(action: {
                        planNewTrip()
                    }, label: {
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                            TextLabel("Plan New Trip".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.planTripButton.rawValue.localized())
                    .disabled(!viewModel.pubisTripEditable)
                }
                
            } else {
                Button(action: {
                    viewModel.pubSnoozed.toggle()
                    if let item = profileManager.selectedTripNotification {
                        viewModel.getRenderData(item: item)
                    }
                }, label: {
                    HStack{
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                        TextLabel("Snooze for rest of today".localized())
                            .font(.body)
                            .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                    }.roundedBorder()
                })
                .addAccessibility(text: AvailableAccessibilityItem.snoozeButton.rawValue.localized())
                .disabled(!viewModel.pubisTripEditable)
                .accessibilityRemoveTraits(.isButton)
            }
            Spacer()
            if !viewModel.pubTitleText.contains("Unable to monitor trip".localized()) {
                Button(action: {
                    viewModel.pubIsActive.toggle()
                    if let item = profileManager.selectedTripNotification {
                        viewModel.getRenderData(item: item)
                    }
                }, label: {
                    HStack{
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                        TextLabel("Pause".localized())
                            .font(.body)
                            .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                    }.roundedBorder()
                })
                .disabled(!viewModel.pubisTripEditable)
                .addAccessibility(text: AvailableAccessibilityItem.pauseButton.rawValue.localized())
                .accessibilityRemoveTraits(.isButton)
            }
            Spacer().frame(width:10)
        }
    }
    
    /// Snooz view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var snoozViewAODA: some View {
        VStack{
            Spacer().frame(width:10)
            if viewModel.pubTitleText.contains("Unable to monitor trip".localized()) || viewModel.pubTitleText.contains("Failed to retrieve the next trip start information".localized()) {
                HStack{
                    Spacer().frame(width:10)
                    Button(action: {
                        viewModel.pubSnoozed.toggle()
                        if let item = profileManager.selectedTripNotification {
                            viewModel.getRenderData(item: item)
                        }
                    }, label: {
                        HStack{
                            Image(systemName: "play.fill")
                                .font(.system(size: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 14))
                            TextLabel("Unsnooze trip analysis".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.unSnoozeButton.rawValue.localized())
                    .accessibilityRemoveTraits(.isButton)
                    .disabled(!viewModel.pubisTripEditable)
                    
                    Button(action: {
                        planNewTrip()
                    }, label: {
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                            TextLabel("Plan New Trip".localized())
                                .font(.body)
                        }.roundedBorder()
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.planTripButton.rawValue.localized())
                    .disabled(!viewModel.pubisTripEditable)
                }
            } else {
                Button(action: {
                    viewModel.pubSnoozed.toggle()
                    if let item = profileManager.selectedTripNotification {
                        viewModel.getRenderData(item: item)
                    }
                }, label: {
                    HStack {
                        VStack{
                            Image(systemName: "pause.fill")
                                .font(.system(size: 30))
                                .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                            TextLabel("Snooze for rest of today".localized())
                                .font(.body)
                                .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                        }
                    }
                    .roundedBorder()
                })
                .addAccessibility(text: AvailableAccessibilityItem.snoozeButton.rawValue.localized())
                .accessibilityRemoveTraits(.isButton)
            }
            Spacer()
            if !viewModel.pubTitleText.contains("Unable to monitor trip".localized()) {
                Button(action: {
                    viewModel.pubIsActive.toggle()
                    if let item = profileManager.selectedTripNotification {
                        viewModel.getRenderData(item: item)
                    }
                }, label: {
                    HStack {
                        Spacer()
                        VStack{
                            Image(systemName: "pause.fill")
                                .font(.system(size: 30))
                            TextLabel("Pause".localized())
                                .font(.body)
                        }
                        Spacer()
                    }
                    .roundedBorder()
                })
                .disabled(!viewModel.pubisTripEditable)
                .addAccessibility(text: AvailableAccessibilityItem.pauseButton.rawValue.localized())
                .accessibilityRemoveTraits(.isButton)
                
            }
            Spacer().frame(width:10)
        }
    }
    
    /// Plan new trip
    /// Plan new trip.
    func planNewTrip() {
        if let itinerary = profileManager.selectedItinerary{
            
            if let queryParams = itinerary.otp2QueryParam{
                let from = queryParams.fromPlace
                let to = queryParams.toPlace
                
                viewModel.getLocationFromCoordinates(locationStirng: from) { autoCompleteFeature in
                    if let feature = autoCompleteFeature {
                        SearchManager.shared.from = feature
                        MapFromToViewModel.shared.pubFromString = feature.properties.label
                        MapFromToViewModel.shared.pubFromDisplayString = feature.properties.label
                        openPlanTripPage()
                    }
                }
                
                viewModel.getLocationFromCoordinates(locationStirng: to) { autoCompleteFeature in
                    if let feature = autoCompleteFeature {
                        SearchManager.shared.to = feature
                        MapFromToViewModel.shared.pubToString = feature.properties.label
                        MapFromToViewModel.shared.pubToDisplayString = feature.properties.label
                        openPlanTripPage()
                    }
                }
            }
        }
    }
    
    /// Open plan trip page
    /// Opens plan trip page.
    func openPlanTripPage() {
        if !MapFromToViewModel.shared.pubFromString.isEmpty && !MapFromToViewModel.shared.pubToString.isEmpty {
            MapManager.shared.reDrawFromToMarkers()
            tabBarMenuManager.currentItemTab = .planTrip
            tabBarMenuManager.currentViewTab = .planTrip
            MapManager.shared.pubSearchRoute = true
        }
    }
    
    // MARK: Header
    /// Trip manage header view.
    /// - Returns: some View
    func TripManageHeaderView() -> some View{
        VStack{
            HStack{
                TextLabel("Trip information".localized(), .bold, .title2)
                    .foregroundColor(Color.black)
                    .padding(.top, 10)
                Spacer()
            }
            HStack{
                TextLabel("Fields marked with an asterisk (*) are required.", .regular, .footnote)
                    .foregroundStyle(Color.gray)
                Spacer()
            }
        }
    }
    
    // MARK: Trip Information
    
    /// Trip information view
    /// - Returns: some View
    /// Trip information view.
    func TripInformationView() -> some View{
        VStack(alignment: .leading, spacing: 10, content: {
            HStack{
                TextLabel("Selected itinerary:".localized(), .bold, .body)
                    .foregroundColor(Color.black)
                Spacer()
            }
            if AccessibilityManager.shared.pubIsLargeFontSize {
                TripItineraryTransportViewAODA()
            } else {
                TripItineraryTransportView()
            }
    
        }).padding(.top, AccessibilityManager.shared.pubIsLargeFontSize ? 5 : 20)
    }
    
    /// Trip itinerary transport view
    /// - Returns: some View
    /// Trip itinerary transport view.
    func TripItineraryTransportView() -> some View {
        guard let itinerary = self.profileManager.selectedItinerary else {
            fatalError("no selected itinerary can be used to generate the legs view")
        }
        let (timeText, _) = TripPlanningManager.shared.timeText(for: String(itinerary.duration ?? 0))
        return VStack(alignment: .leading){
            HStack{
                TextLabel("Itinerary".localized())
                    .font(.body)
                TextLabel(TripPlanningManager.shared.createShowTimeforEditTrip(itinerary: itinerary))
                    .font(.body)
                Spacer()
                TextLabel(timeText)
                    .font(.body)
            }
            
            TransportsView(itinerary: itinerary)
        }
    }
    
    /// Trip itinerary transport view a o d a
    /// - Returns: some View
    /// Trip itinerary transport view aoda.
    func TripItineraryTransportViewAODA() -> some View {
        guard let itinerary = self.profileManager.selectedItinerary else {
            fatalError("no selected itinerary can be used to generate the legs view")
        }
        let (timeText, _) = TripPlanningManager.shared.timeText(for: String(itinerary.duration ?? 30))
        return VStack(alignment: .leading){
                TextLabel("Itinerary".localized())
                    .font(.body)
                TextLabel(TripPlanningManager.shared.createShowTimeforEditTrip(itinerary: itinerary))
                    .font(.body)
                Spacer()
            TextLabel(timeText)
                .font(.body)
            
            TransportsView(itinerary: itinerary)
        }.padding(.top, 5)
    }
    
    /// Trip name view
    /// - Returns: some View
    /// Trip name view.
    func TripNameView() -> some View {
        VStack{
            HStack{
                TextLabel("Please provide a name for this trip:".localized(), .bold, .callout)
                    .foregroundColor(viewModel.pubIsTripNameEmpty ? Color.red : Color.black)
                TextLabel("*", .bold, .body)
                    .foregroundColor(Color.red)
                
                Spacer()
            }
            TextField("", text: $viewModel.pubCustomNameForTrip)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.callout)
                .foregroundColor(viewModel.pubisTripEditable ? .black : .gray_subtitle_color)
                .disabled(!viewModel.pubisTripEditable)
            
            if viewModel.pubIsTripNameEmpty{
                HStack{
                    TextLabel("Please enter a trip name".localized())
                        .font(.callout)
                        .foregroundColor(Color.red)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 15)
    }
    
    /// Weekdays list view
    /// - Returns: some View
    /// Weekdays list view.
    func WeekdaysListView() -> some View{
        VStack{
            HStack{
                TextLabel("What days do you take this trip?".localized(), .bold, .callout)
                    .foregroundColor(Color.black)
                TextLabel("*", .bold, .body)
                    .foregroundColor(Color.red)
                Spacer()
            }.padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 10){
                // Custom Radio Button, with Specific Design
                HStack {
                    Button(action: {
                        if let previousDays = viewModel.temporaryDaysOfTrip{
                            viewModel.pubWeekdays = previousDays
                        }
                        if viewModel.checkAvailabilityAndCheckedStatus(){
                            viewModel.pubSelectedDaysOfTrip = .SELECTIVE_DAYS
                        }
                    }) {
                        VStack {
                            HStack {
                                Image(systemName: viewModel.pubSelectedDaysOfTrip == .SELECTIVE_DAYS ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(viewModel.pubSelectedDaysOfTrip == .SELECTIVE_DAYS ? .blue : .gray)
                                TextLabel("On certain days each week".localized(), .regular, .callout)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Disable default button style
                    Spacer()
                }.disabled(!viewModel.pubisTripEditable)
                if viewModel.pubSelectedDaysOfTrip == .SELECTIVE_DAYS{
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        VStack {
                            WeekdaysItemViewAODA(width: AccessibilityManager.shared.getFontSize())
                        }
                    } else {
                        GeometryReader{ reader in
                            HStack(alignment: .center, spacing: 0, content: {
                                WeekdaysItemView(width: reader.size.width)
                            })
                        }.frame(height: 55)
                    }
                    
                    HStack{
                        TextLabel("Your trip is available on the days of the week as indicated above.".localized()).font(.callout).foregroundColor(Color.gray_subtitle_color)
                        Spacer()
                    }
                }
                HStack {
                    Button(action: {
                        viewModel.temporaryDaysOfTrip = viewModel.pubWeekdays
                        viewModel.updateDaysSelection()
                        viewModel.pubSelectedDaysOfTrip = .DEFAULT_DAY
                    }) {
                        HStack {
                            Image(systemName: viewModel.pubSelectedDaysOfTrip == .DEFAULT_DAY ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(viewModel.pubSelectedDaysOfTrip == .DEFAULT_DAY ? .blue : .gray)
                            TextLabel("Only on %1".localized(viewModel.theDefaultDateforSavingTrip()), .regular, .callout)
                        }
                    }
                    .buttonStyle(PlainButtonStyle()) // Disable default button style
                    Spacer()
                }.disabled(!viewModel.pubisTripEditable)
            }
        }
    }
    
    /// Weekdays item view.
    /// - Parameters:
    ///   - width: Parameter description
    /// - Returns: some View
    func WeekdaysItemView(width: CGFloat) -> some View{
        ForEach(0..<viewModel.pubWeekdays.count, id: \.self) { index in
            HStack {
            ZStack{
                if !viewModel.pubWeekdays[index].isChecked && viewModel.pubWeekdays[index].isAvaliable{
                    VStack{
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .padding(.bottom, 0.1)
                            .font(.callout)
                            .minimumScaleFactor(0.5)
                        Image(systemName: "square")
                            .font(.system(size: 14))
        
                    }
                    .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: width/CGFloat(viewModel.pubWeekdays.count) , height: 55, alignment: .center)
                        .border(Color.gray, width: 0.77)
                }
                else if viewModel.pubWeekdays[index].isChecked && viewModel.pubWeekdays[index].isAvaliable {
                    VStack{
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .foregroundColor(.white)
                            .padding(.bottom, 0.1)
                            .font(.callout)
                            .minimumScaleFactor(0.5)
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                    .zIndex(1)
                    .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                    
                    Rectangle()
                        .fill(Color.main)
                        .border(Color.gray, width: 0.77)
                        .frame(width: width/CGFloat(viewModel.pubWeekdays.count), height: 55, alignment: .center)
                }
                else{
                    VStack{
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .foregroundColor(Color.redForeground)
                            .padding(.bottom, 0.1)
                            .font(.callout)
                            .minimumScaleFactor(0.5)
                            
                        Image(systemName: "slash.circle")
                            .foregroundColor(Color.redForeground)
                            .font(.system(size: 14))
                            
                    }
                    .zIndex(1)
                        .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(width: width/CGFloat(viewModel.pubWeekdays.count), height: 55, alignment: .center)
                        .border(Color.gray, width: 0.77)
                }
            }
            .onTapGesture {
                if let matchingIndex = self.viewModel.pubWeekdays.firstIndex(where: { $0.id == viewModel.pubWeekdays[index].id }) {
                    if self.viewModel.pubWeekdays[matchingIndex].isAvaliable{
                        self.viewModel.pubWeekdays[matchingIndex].isChecked.toggle()
                        if !self.viewModel.checkAvailabilityAndCheckedStatus(){
                            self.viewModel.pubSelectedDaysOfTrip = .DEFAULT_DAY
                        }
                    }
                }
            }
            .disabled(!viewModel.pubisTripEditable)
            }
        }
    }
    
    /// Weekdays item view a o d a.
    /// - Parameters:
    ///   - width: Parameter description
    /// - Returns: some View
    func WeekdaysItemViewAODA(width: CGFloat) -> some View{
        ForEach(0..<viewModel.pubWeekdays.count, id: \.self) { index in
            VStack {
            ZStack{
                if !viewModel.pubWeekdays[index].isChecked && viewModel.pubWeekdays[index].isAvaliable{
                    HStack{
                        Image(systemName: "square")
                            .renderingMode(.template)
                            .font(.system(size: AccessibilityManager.shared.getFontSize()))
                            .foregroundColor(Color.black)
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
        
                    }
                    .padding(.all)
                    .roundedBorderWithColor(0, 0, Color.black,2)
                    .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                }
                else if viewModel.pubWeekdays[index].isChecked && viewModel.pubWeekdays[index].isAvaliable {
                    HStack{
                        Image(systemName: "checkmark.square")
                            .foregroundColor(.white)
                            .font(.system(size: AccessibilityManager.shared.getFontSize()))
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .padding(.bottom, 0.1)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.all)
                    .foregroundColor(Color.white)
                    .background(Color.main)
                    .roundedBorderWithColor(0, 0, Color.black,2)
                    .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                }
                else{
                    HStack{
                        Image(systemName: "slash.circle")
                            .foregroundColor(Color.redForeground)
                            .font(.system(size: AccessibilityManager.shared.getFontSize()))
                        TextLabel(viewModel.pubWeekdays[index].name.localized())
                            .foregroundColor(Color.redForeground)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.5)
                        Spacer()
                            
                    }
                    .padding(.all)
                    .roundedBorderWithColor(0, 0, Color.black,2)
                    .addAccessibility(text: getWeekDayLabel(title: viewModel.pubWeekdays[index].name.localized(), isChecked: viewModel.pubWeekdays[index].isChecked, isAvailable: viewModel.pubWeekdays[index].isAvaliable).localized())
                }
            }
            .onTapGesture {
                if let matchingIndex = self.viewModel.pubWeekdays.firstIndex(where: { $0.id == viewModel.pubWeekdays[index].id }) {
                    if self.viewModel.pubWeekdays[matchingIndex].isAvaliable{
                        self.viewModel.pubWeekdays[matchingIndex].isChecked.toggle()
                        if !self.viewModel.checkAvailabilityAndCheckedStatus(){
                            self.viewModel.pubSelectedDaysOfTrip = .DEFAULT_DAY
                        }
                    }
                }
            }
            }
        }
    }
    
    /// Get week day label.
    /// - Parameters:
    ///   - title: Parameter description
    ///   - isChecked: Parameter description
    ///   - isAvailable: Parameter description
    /// - Returns: String
    func getWeekDayLabel(title: String, isChecked: Bool, isAvailable: Bool) -> String{
        switch title {
        case ProfileTripModel.shared.getWeekDayName(dayName: "Mon."):
            return "Monday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Tue."):
            return "Tuesday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Wed."):
            return "Wednesday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Thu."):
            return "Thursday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Fri."):
            return "Friday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Sat."):
            return "Saturday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        case ProfileTripModel.shared.getWeekDayName(dayName: "Sun."):
            return "Sunday, %1, and, %2".localized((isAvailable ? "Available" : "Not Available"), (isChecked ? "Selected".localized() : "Not Selected".localized()))
        default:
            return ""
        }
    }
    
    // MARK: Trip Notification
    
    /// Trip notification view
    /// - Returns: some View
    /// Trip notification view.
    func TripNotificationView() -> some View{
        VStack(alignment: .leading, spacing: 10){
            HStack{
                TextLabel("Trip notifications".localized(), .bold, .title2)
                    .foregroundColor(Color.black)
                Spacer()
            }
            HStack{
                TextLabel("Notify me when:".localized(), .bold, .body).foregroundColor(Color.black)
                Spacer()
            }
            
            VStack(alignment: .leading){
                TextLabel("There is a realtime alert flagged on my journey".localized())
                    .font(.callout).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                MultiChoiceDropDownMenuView(title: viewModel.pubRealtimeAlertNotification, choices: viewModel.pubRealTimeAlertDropdownItem, selectionMode: .single, preselected: [viewModel.pubRealtimeAlertNotification],isDisabled: !viewModel.pubisTripEditable) { choices in
                    viewModel.pubRealtimeAlertNotification = choices.first ?? "N/A"
                }
            }.padding(.top, 20)
            
            VStack(alignment: .leading){
                TextLabel("An alternative route or transfer point is recommended".localized())
                    .font(.callout).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    
                MultiChoiceDropDownMenuView(title: viewModel.pubAlternativeRouteNotification, choices: viewModel.pubAlternativeRouteDropdownItem, selectionMode: .single, preselected: [viewModel.pubAlternativeRouteNotification],isDisabled: !viewModel.pubisTripEditable) { choices in
                    viewModel.pubAlternativeRouteNotification = choices.first ?? "N/A"
                }
            }
            
            VStack(alignment: .leading){
                TextLabel("There are delays or disruptions of more than".localized())
                    .font(.callout).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                MultiChoiceDropDownMenuView(title: viewModel.pubDelayNotification, choices: viewModel.pubDelayDropdownItem, selectionMode: .single, preselected: [viewModel.pubDelayNotification],isDisabled: !viewModel.pubisTripEditable) { choices in
                    viewModel.pubDelayNotification = choices.first ?? "N/A"
                }
            }
            
            Button(action: {
                showAdvancedSettings.toggle()
            }, label: {
                    HStack{
                        Image(systemName: showAdvancedSettings ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                            .accentColor(.black)
                            .font(.system(size: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 16))
                        TextLabel("Advanced settings".localized(), .bold, .body).foregroundColor(Color.black).multilineTextAlignment(.leading)
                    }
            }).padding(.vertical, 10)
            
            if showAdvancedSettings{
                VStack{
                    HStack{
                        VStack(alignment: .leading){
                            TextLabel("Monitor this trip before it begins:".localized())
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.body)
                        }
                        Spacer()
                    }
                    MultiChoiceDropDownMenuView(title: viewModel.pubAdvancedSetting, choices: viewModel.pubAdvancedSettingDropdownItem, selectionMode: .single, preselected: [viewModel.pubAdvancedSetting],isDisabled: !viewModel.pubisTripEditable) { choices in
                        viewModel.pubAdvancedSetting = choices.first ?? "N/A"
                    }
                }
            }
        }.padding(.top, 30)
    }
    
    // MARK: Travel Companions
    /// Saving trip travel companions.
    /// - Returns: some View
    func SavingTripTravelCompanions() -> some View {
        VStack(alignment: .leading, spacing: 10){
            HStack{
                TextLabel("Travel companions".localized(), .bold, .title2)
                    .foregroundColor(Color.black)
                Spacer()
            }
            HStack{
                HStack(spacing: 0){
                    TextLabel("Primary traveler:".localized(), .regular, .body).foregroundColor(Color.black)
                    TextLabel(" MySelf".localized(), .bold, .body)
                    Spacer()
                }
                Spacer()
            }
            VStack(alignment: .leading){
                TextLabel("Companion on this trip:".localized())
                    .font(.callout).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                MultiChoiceDropDownMenuView(title: viewModel.pubCompanionOnThisTrip, choices: viewModel.pubCompanionDropdownItem, selectionMode: .single, allowSingleDeselection: true, preselected: [viewModel.pubCompanionOnThisTrip], isDisabled: !viewModel.pubisTripEditable) { choices in
                    if let firstChoice = choices.first, firstChoice != "" {
                        viewModel.pubCompanionOnThisTrip = firstChoice
                        viewModel.removeCompanionFromObserverList(companion: firstChoice)
                    } else {
                        viewModel.pubCompanionOnThisTrip = "Select..."
                        viewModel.pubObserversDropdownitem = TravelCompanionsViewModel.shared.getCompanionList()
                    }

                }
            }.padding(.top, 20)
            
            VStack(alignment: .leading){
                TextLabel("Observers watching this trip:".localized())
                    .font(.callout).lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    
                
                MultiChoiceDropDownMenuView(title: viewModel.pubObserversOnthisTrip.joined(separator: ","), choices: viewModel.pubObserversDropdownitem, selectionMode: .multiple, preselected: viewModel.pubObserversOnthisTrip,isDisabled: !viewModel.pubisTripEditable) { choices in
                    if !choices.isEmpty {
                        viewModel.pubObserversOnthisTrip = choices
                        viewModel.removeObserversFromCompanionList(observers: choices)
                    }else{
                        viewModel.pubObserversOnthisTrip = ["Select..."]
                        viewModel.pubCompanionDropdownItem = TravelCompanionsViewModel.shared.getCompanionList()
                    }
                }
            }
            
        }
    }
    /// Trip manage footer button
    /// - Returns: some View
    /// Trip manage footer button.

    /// - Returns: some View
    func TripManageFooterButton() -> some View{
        HStack{
            Button(action: {
                self.profileManager.refreshTripList()
                self.profileManager.pubPageState = .trips
                self.profileManager.pubShowTripList = true
                self.profileManager.pubTripPageTitle = "My Trips".localized()
                if profileManager.pubEditTripFromPlanTrip == true{
                    TabBarMenuManager.shared.currentViewTab = .planTrip
                    TabBarMenuManager.shared.currentItemTab = .planTrip
                    profileManager.pubEditTripFromPlanTrip = false
                }
            }, label: {
                TextLabel("Cancel".localized()).roundedBorder()
                    .font(.body)
            })
            .addAccessibility(text: AvailableAccessibilityItem.cancelButton.rawValue.localized())
            Spacer()
            if viewModel.pubisTripEditable{
                Button(action: {
                    viewModel.pubIsTripNameEmpty = viewModel.pubCustomNameForTrip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if !viewModel.pubIsTripNameEmpty {
                        self.presentProcessingView = true
                        self.viewModel.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation) { success, message in
                            
                            DispatchQueue.main.async {
                                self.presentProcessingView = false
                            }
                            
                            if success {
                                viewModel.pubCustomNameForTrip = ""
                                self.profileManager.refreshTripList()
                                let statusText = profileManager.tripManagerState == .creation ? "saved" : "updated"
                                AlertManager.shared.presentAlert(message: "Your preferences were %1".localized(statusText))
                                self.profileManager.pubPageState = .trips
                                self.profileManager.pubShowTripList = true
                                self.profileManager.pubTripPageTitle = "My Trips".localized()
                                if profileManager.pubEditTripFromPlanTrip == true{
                                    TabBarMenuManager.shared.currentViewTab = .planTrip
                                    TabBarMenuManager.shared.currentItemTab = .planTrip
                                    profileManager.pubEditTripFromPlanTrip = false
                                }
                            }else{
                                if message == "Maximum permitted saved monitored trips reached. Maximum = 5" {
                                    AlertManager.shared.presentAlert(message: "You already have reached the maximum of five saved trips. Please remove unused trips from your saved trips, and try again.")
                                }else {
                                    AlertManager.shared.presentAlert(message: message)
                                }
                            }
                        }
                    }
                }, label: {
                    TextLabel("Save Preferences".localized())
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.all, 8)
                        .padding(.horizontal, 5)
                        .background(Color.main)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.gray, lineWidth: 0.77))
                })
                .addAccessibility(text: AvailableAccessibilityItem.savePreferencesButton.rawValue.localized())
            }
        }.padding(.vertical, 50)
    }
    
    /// Trip manage footer button a o d a
    /// - Returns: some View
    /// Trip manage footer button aoda.
    func TripManageFooterButtonAODA() -> some View{
        VStack{
            Button(action: {
                self.profileManager.refreshTripList()
                self.profileManager.pubPageState = .trips
                self.profileManager.pubShowTripList = true
                self.profileManager.pubTripPageTitle = "My Trips".localized()
                if profileManager.pubEditTripFromPlanTrip == true{
                    TabBarMenuManager.shared.currentViewTab = .planTrip
                    TabBarMenuManager.shared.currentItemTab = .planTrip
                    profileManager.pubEditTripFromPlanTrip = false
                }
            }, label: {
                HStack {
                    Spacer()
                    TextLabel("Cancel".localized())
                        .font(.body)
                    Spacer()
                }
                .roundedBorder()
            })
            .addAccessibility(text: AvailableAccessibilityItem.cancelButton.rawValue.localized())
            Spacer().frame(height: 20)
            if viewModel.pubisTripEditable{
                Button(action: {
                    viewModel.pubIsTripNameEmpty = viewModel.pubCustomNameForTrip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    if !viewModel.pubIsTripNameEmpty {
                        self.presentProcessingView = true
                        self.viewModel.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation) { success, message in
                            
                            DispatchQueue.main.async {
                                self.presentProcessingView = false
                            }
                            
                            if success {
                                viewModel.pubCustomNameForTrip = ""
                                self.profileManager.refreshTripList()
                                let statusText = profileManager.tripManagerState == .creation ? "saved" : "updated"
                                AlertManager.shared.presentAlert(message: "Your preferences were %1".localized(statusText))
                                self.profileManager.pubPageState = .trips
                                self.profileManager.pubShowTripList = true
                                self.profileManager.pubTripPageTitle = "My Trips".localized()
                                if profileManager.pubEditTripFromPlanTrip == true{
                                    TabBarMenuManager.shared.currentViewTab = .planTrip
                                    TabBarMenuManager.shared.currentItemTab = .planTrip
                                    profileManager.pubEditTripFromPlanTrip = false
                                }
                            }else{
                                if message == "Maximum permitted saved monitored trips reached. Maximum = 5" {
                                    AlertManager.shared.presentAlert(message: "You already have reached the maximum of five saved trips. Please remove unused trips from your saved trips, and try again.")
                                }else {
                                    AlertManager.shared.presentAlert(message: message)
                                }
                            }
                        }
                    }
                }, label: {
                    HStack {
                        Spacer()
                        TextLabel("Save Preferences".localized())
                            .font(.body)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.all, 8)
                    .padding(.horizontal, 5)
                    .background(Color.blueBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray, lineWidth: 0.77))
                })
                .addAccessibility(text: AvailableAccessibilityItem.savePreferencesButton.rawValue.localized())
            }
        }.padding(.vertical, 50)
    }
}
