//
//  Stop.swift
//

import Foundation

/// Represents stop times without pattern information.
///
/// Used for lightweight stop time queries where pattern details are not needed.
struct StoptimesWithoutPatterns: Codable, Hashable {
    /// Service day timestamp (Unix time)
    let serviceDay: Int?
}

/// Represents transit agency feed information.
///
/// Contains metadata about the transit data feed provider.
struct AgencyFeed: Decodable, Equatable{
    /// Unique identifier for the feed
    let feedId: String

    /// Publisher information for the feed
    let publisher: Publisher
}

/// Represents the publisher of a transit data feed.
struct Publisher: Decodable, Equatable{
    /// Name of the publishing organization
    let name: String
}

/// Represents a transit stop location.
///
/// A Stop contains all information about a physical transit stop including:
/// - Location coordinates (latitude/longitude)
/// - Identification (ID, code, name)
/// - Service information (stop times)
///
/// Stops are used throughout the app for:
/// - Displaying stop locations on the map
/// - Showing stop schedules and arrivals
/// - Trip planning origin/destination selection
/// - Real-time vehicle tracking
///
/// Example:
/// ```swift
/// let stop = Stop(
///     id: "agency:123",
///     code: "123",
///     name: "Main St & 1st Ave",
///     lat: 47.6062,
///     lon: -122.3321,
///     stoptimesWithoutPatterns: nil
/// )
/// print(stop.displayIdentifier()) // "123"
/// ```
struct Stop: Codable, Identifiable, Hashable, Equatable {

    /// Compares two stops for equality based on their ID.
    ///
    /// Two stops are considered equal if they have the same ID,
    /// regardless of other properties.
    static func == (lhs: Stop, rhs: Stop) -> Bool {
        return lhs.id == rhs.id
    }

    /// Unique identifier for the stop (format: "agency:stopId")
    let id: String

    /// Stop code displayed to riders (e.g., "123", "A45")
    let code: String?

    /// Human-readable stop name (e.g., "Main St & 1st Ave")
    let name: String

    /// Latitude coordinate of the stop location
    let lat: Double

    /// Longitude coordinate of the stop location
    let lon: Double

    /// Stop times without detailed pattern information
    let stoptimesWithoutPatterns: [StoptimesWithoutPatterns]?

    /// Extracts the display-friendly stop ID from a full stop identifier.
    ///
    /// Stop IDs are typically formatted as "agency:stopId". This method
    /// extracts just the stopId portion for display purposes.
    ///
    /// - Parameter stopId: Full stop identifier (e.g., "agency:123")
    /// - Returns: Display-friendly stop ID (e.g., "123")
    ///
    /// Example:
    /// ```swift
    /// Stop.findDisplayStopId("metro:456") // "456"
    /// Stop.findDisplayStopId("789") // "789"
    /// Stop.findDisplayStopId(nil) // ""
    /// ```
    public static func findDisplayStopId(_ stopId: String?) -> String{
        guard let stopId = stopId else {
            return ""
        }
        let components = stopId.components(separatedBy: ":")
        return components.last ?? stopId
    }

    /// Extracts the agency/company ID from a full stop identifier.
    ///
    /// Stop IDs are typically formatted as "agency:stopId". This method
    /// extracts the agency portion.
    ///
    /// - Parameter stopId: Full stop identifier (e.g., "metro:123")
    /// - Returns: Agency identifier (e.g., "metro")
    ///
    /// Example:
    /// ```swift
    /// Stop.findDisplayCompanyId("metro:456") // "metro"
    /// Stop.findDisplayCompanyId("789") // "789"
    /// Stop.findDisplayCompanyId(nil) // ""
    /// ```
    public static func findDisplayCompanyId(_ stopId: String?) -> String{
        guard let stopId = stopId else {
            return ""
        }
        let components = stopId.components(separatedBy: ":")
        return components.first ?? stopId
    }

    /// Returns the display-friendly identifier for this stop.
    ///
    /// Prefers the stop code if available, otherwise extracts the stop ID
    /// from the full identifier.
    ///
    /// - Returns: Display-friendly stop identifier
    ///
    /// Example:
    /// ```swift
    /// // Stop with code
    /// let stop1 = Stop(id: "metro:123", code: "A45", ...)
    /// stop1.displayIdentifier() // "A45"
    ///
    /// // Stop without code
    /// let stop2 = Stop(id: "metro:123", code: nil, ...)
    /// stop2.displayIdentifier() // "123"
    /// ```
    public func displayIdentifier() -> String {
        if let stopCode = code {
            return stopCode
        }
        let components = id.components(separatedBy: ":")
        return components.last ?? id
    }
}

/// Extension providing coordinate conversion for Stop.
extension Stop {
    /// Converts the stop's latitude and longitude to a Coordinate object.
    ///
    /// This computed property provides easy access to the stop's location
    /// as a Coordinate struct, which is used throughout the app for
    /// map operations and distance calculations.
    ///
    /// - Returns: A Coordinate containing the stop's lat/lon
    var coordinate: Coordinate {
        Coordinate(latitude: lat, longitude: lon)
    }
}

struct StopViewerModel: Codable {
    let pattern: Pattern
    let times: [StopTime]
}

struct StopScheduleModel: Codable {
    let time: StopTime
    let route: String
    let to: String
}

struct GraphQLStopScheduleModel: Codable {
    let time: GraphQLStopTime
    let route: String
    let to: String
}

extension Array where Element == GraphQLStopViewerModel {
    /// Schedule times.
    /// - Parameters:
    ///   - [StopScheduleItem]: Parameter description
    var scheduleTimes: [StopScheduleItem] {
        var schedules = self.flatMap({ $0.schedule })
        schedules = schedules.sorted(by: { $0.time.scheduledDeparture < $1.time.scheduledDeparture })
        return schedules.map({
            let time = $0.time.departureDate.timeForStopViewer()
            return StopScheduleItem(leftText: $0.route, middleText: $0.to, rightText: time)
        })
    }
}

struct Pattern: Codable {
    let id, desc: String?
}
struct StopTime: Codable {
    let stopID: String
    let scheduledDeparture: TimeInterval
    let stopIndex, stopCount, scheduledArrival: Int
    let realtimeArrival, realtimeDeparture, arrivalDelay, departureDelay: Int
    let timepoint, realtime: Bool
    let headsign: String?
    let realtimeState: String
    let serviceDay: Int
    let tripID: String?
    let blockID: String?
    let continuousPickup, continuousDropOff, serviceAreaRadius: Int?
    var date = Date()

    enum CodingKeys: String, CodingKey {
        case stopID = "stopId"
        case stopIndex, stopCount, scheduledArrival, scheduledDeparture, realtimeArrival, realtimeDeparture, arrivalDelay, departureDelay, timepoint, realtime, realtimeState, serviceDay, headsign
        case tripID = "tripId"
        case blockID = "blockId"
        case continuousPickup, continuousDropOff, serviceAreaRadius
    }
}

struct GraphQLStopViewerModel: Codable {
    let pattern: GraphQLPattern
    let times: [GraphQLStopTime]
}

struct GraphQLPattern: Codable, Equatable {
    static func == (lhs: GraphQLPattern, rhs: GraphQLPattern) -> Bool {
        lhs.headsign == rhs.headsign && lhs.desc == rhs.desc && lhs.route == rhs.route
    }
    
    let headsign: String?
    let desc: String?
    let route: GraphQLPatternRoute
}

struct GraphQLPatternRoute: Codable, Equatable {
    static func == (lhs: GraphQLPatternRoute, rhs: GraphQLPatternRoute) -> Bool {
        lhs.routeId == rhs.routeId
    }
    
    let routeId: String
    let agency: Agency
    let shortName: String?
    let type: Int?
    let mode: String?
    let longName: String?
    let color: String?
    let textColor: String?
}

struct GraphQLStopTime: Codable {
    let serviceDay: Int
    let departureDelay: Int
    let realtimeState: String
    let realtimeDeparture: Int
    let scheduledDeparture: Int
    let headsign: String?
    var date = Date()

    enum CodingKeys: String, CodingKey {
        case serviceDay, departureDelay, realtimeState, realtimeDeparture, scheduledDeparture, headsign
    }
}

struct GraphQLStop: Codable {
    let id: String
}

struct GraphQLTrip: Codable {
    let id: String
}


extension GraphQLStopTime {
    /// Departure date.
    /// - Parameters:
    ///   - Date: Parameter description
    var departureDate: Date {
        return Date(timeInterval: TimeInterval(scheduledDeparture), since: date.midnight)
    }
    
    /// Departure since now.
    /// - Parameters:
    ///   - isFormatted: Parameter description
    /// - Returns: String
    func departureSinceNow(isFormatted: Bool = true) -> String{
            let oneDayInSeconds = 86400
            let departureTime = self.realtimeDeparture
            let now = NSDate()
            let serviceDay = NSDate(timeIntervalSince1970: TimeInterval(serviceDay))
            
            //Determine if arrival occurs on different day
            let departureTimeRemainder = departureTime % oneDayInSeconds
            let timeAfterServiceDay = departureTime - departureTimeRemainder
            let departureDay = serviceDay.addingTimeInterval(TimeInterval(timeAfterServiceDay))
            let vehicleDepartsToday = now == departureDay
            
            let secondsUntilDeparture = self.realtimeDeparture + Int(self.serviceDay) - Int(now.timeIntervalSince1970)
            let departsInFuture = secondsUntilDeparture > 0
            
            //show exact time if the departure happens wihtin an hour
            let showCountDown = secondsUntilDeparture < oneDayInSeconds && departsInFuture
            //show day of the week if the arrival is on a different day
            let showDayOfWeek = !vehicleDepartsToday && !showCountDown
            
            if showDayOfWeek{
                let dateFormatter = DateFormatter()
                let language = SettingsManager.shared.appLanguage
                dateFormatter.locale = Locale(identifier: language.languageCode())
                dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
                dateFormatter.dateFormat = "EEEE"
                return dateFormatter.string(from: departureDay as Date)
            }
            
            if showCountDown{
                if secondsUntilDeparture < 60 {
                    return "Due".localized()
                } else if secondsUntilDeparture < 3600 {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.hour, .minute, .day]
                    formatter.unitsStyle = .short
                    var calendar = Calendar.current
                    let language = SettingsManager.shared.appLanguage
                    calendar.locale = Locale(identifier: language.languageCode())
                    formatter.calendar = calendar
                    var returnString = formatter.string(from: TimeInterval(secondsUntilDeparture)) ?? ""
                    returnString = returnString.replacingOccurrences(of: "min", with: "min".localized())
                    returnString = returnString.replacingOccurrences(of: "hr", with: "hr".localized())
                    return returnString
                }else{
                    if isFormatted {
                        let dateFormatter = DateFormatter()
                        let language = SettingsManager.shared.appLanguage
                        dateFormatter.locale = Locale(identifier: language.languageCode())
                        dateFormatter.dateFormat = "h:mm a"
                        
                        let dayFormatter = DateFormatter()
                        // MARK: - Get the day for departure date
                        dayFormatter.locale = Locale(identifier: language.languageCode())
                        dayFormatter.timeZone = EnvironmentManager.shared.currentTimezone
                        dayFormatter.dateFormat = "EEEE"
                        let departuredayName = dayFormatter.string(from: departureDay as Date)
                        
                        // MARK: - Get the day for today date
                        let todaydayName = dayFormatter.string(from: Date.now)
                        
                        if departuredayName == todaydayName {
                            var returnString = dateFormatter.string(from: departureDate)
                            return returnString
                        } else {
                            var returnString = departuredayName + " " + dateFormatter.string(from: departureDate)
                            return returnString
                        }
                        
                        
                    } else {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.hour, .minute, .day]
                        formatter.unitsStyle = .short
                        var calendar = Calendar.current
                        let language = SettingsManager.shared.appLanguage
                        calendar.locale = Locale(identifier: language.languageCode())
                        formatter.calendar = calendar
                        var returnString = formatter.string(from: TimeInterval(secondsUntilDeparture)) ?? ""
                        returnString = returnString.replacingOccurrences(of: "min", with: "min".localized())
                        returnString = returnString.replacingOccurrences(of: "h y", with: "hr".localized()) // MARK: system is converting hr to h y and here reverting back according to language table
                        return returnString
                    }
                }
            }
            
            return ""
    }
    
}


extension StopTime {
    /// Departure date.
    /// - Parameters:
    ///   - Date: Parameter description
    var departureDate: Date {
        return Date(timeInterval: scheduledDeparture, since: date.midnight)
    }
    
    /// Departure since now.
    /// - Parameters:
    ///   - String: Parameter description
    var departureSinceNow: String {
        let oneDayInSeconds = 86400
        let departureTime = self.realtimeDeparture
        let now = NSDate()
        let serviceDay = NSDate(timeIntervalSince1970: TimeInterval(serviceDay))
        
        //Determine if arrival occurs on different day
        let departureTimeRemainder = departureTime % oneDayInSeconds
        let timeAfterServiceDay = departureTime - departureTimeRemainder
        let departureDay = serviceDay.addingTimeInterval(TimeInterval(timeAfterServiceDay))
        let vehicleDepartsToday = now == departureDay
        
        let secondsUntilDeparture = self.realtimeDeparture + self.serviceDay - Int(now.timeIntervalSince1970)
        let departsInFuture = secondsUntilDeparture > 0
        
        //show exact time if the departure happens wihtin an hour
        let showCountDown = secondsUntilDeparture < oneDayInSeconds && departsInFuture
        //show day of the week if the arrival is on a different day
        let showDayOfWeek = !vehicleDepartsToday && !showCountDown
        
        if showDayOfWeek{
            let dateFormatter = DateFormatter()
            let language = SettingsManager.shared.appLanguage
            dateFormatter.locale = Locale(identifier: language.languageCode())
            dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
            dateFormatter.dateFormat = "EEEE"
            return dateFormatter.string(from: departureDay as Date)
        }
        
        if showCountDown{
            if secondsUntilDeparture < 60 {
                return "Due".localized()
            }
            else{
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.hour, .minute, .day]
                formatter.unitsStyle = .short
                var calendar = Calendar.current
                let language = SettingsManager.shared.appLanguage
                calendar.locale = Locale(identifier: language.languageCode())
                formatter.calendar = calendar
                return formatter.string(from: TimeInterval(secondsUntilDeparture)) ?? ""
            }
        }
        
        return ""
    }
    
}
