//
//  NotificationProviderModels.swift
//

import Foundation

struct SMSVerificationResponse: Codable {
    var sid: String?
    var status: String
}

struct TripNotificationLocation: Codable {
    var departure: Int64?
    var lat: Double
    var lon: Double
    var name: String
    var orig: String?
}

struct JourneyState: Codable {
    var baselineArrivalTimeEpochMillis: Int64
    var baselineDepartureTimeEpochMillis: Int64
    var hasRealtimeData: Bool
    var lastCheckedEpochMillis: Int64
    var lastNotificationTimeMillis: Int64
    var lastNotifications:[LastNotification]?
    var matchingItinerary:OTPItinerary?
    var scheduledArrivalTimeEpochMillis: Int64
    var scheduledDepartureTimeEpochMillis: Int64
    var targetDate: String?
    var tripStatus: String?
}

struct LastNotification: Codable {
    let id: String
    let lastUpdated, dateCreated: Int
    let type, body: String
}

struct TripNotificationResponse: Codable {
    var dateCreated: Int64
    var from: TripNotificationLocation
    var id: String
    var inactive: Bool?
    var journeyState:JourneyState?
    var lastUpdated: Int64
    var snoozed: Bool
    var to: TripNotificationLocation
    var tripTime: String?
    var otp2QueryParams: PlanTripVariables?
    
    var arrivalVarianceMinutesThreshold: Int
    var departureVarianceMinutesThreshold: Int
    var excludeFederalHolidays:Bool
    var isActive: Bool
    var itinerary: OTPItinerary
    var leadTimeInMinutes: Int
    var tripName: String
    var userId: String
    var notifyOnAlert: Bool
    var notifyOnItineraryChange: Bool
    var monday: Bool
    var tuesday: Bool
    var wednesday: Bool
    var thursday: Bool
    var friday: Bool
    var saturday: Bool
    var sunday: Bool
    var itineraryExistence: CheckItineraryResponse?
    var companion: RelatedUser?
    var observers: [RelatedUser]?
    
    /// Copy
    /// - Returns: TripNotificationResponse
    func copy() -> TripNotificationResponse {
        var tnlFromCopy = from
        var tnlToCopy = to
        var itineraryCopy = itinerary.copy()
        var itineraryExistenceCopy = itineraryExistence
        var new = TripNotificationResponse(dateCreated: dateCreated, from: tnlFromCopy, id: id, journeyState: journeyState, lastUpdated: lastUpdated, snoozed: snoozed, to: tnlToCopy, otp2QueryParams:otp2QueryParams, arrivalVarianceMinutesThreshold: arrivalVarianceMinutesThreshold, departureVarianceMinutesThreshold: departureVarianceMinutesThreshold, excludeFederalHolidays: excludeFederalHolidays, isActive: isActive, itinerary: itineraryCopy, leadTimeInMinutes: leadTimeInMinutes,tripName: tripName, userId: userId, notifyOnAlert: notifyOnAlert, notifyOnItineraryChange: notifyOnItineraryChange, monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday, friday: friday, saturday: saturday, sunday: sunday, itineraryExistence: itineraryExistenceCopy, companion: companion, observers: observers)
        return new
    }
}

// Define a Codable wrapper type for dictionary values
enum CodableValue: Codable {
    case string(String)
    case int(Int)
    
    /// Initializes a new instance.
    /// - Parameters:
    ///   - decoder: Decoder
    /// - Throws: Error if operation fails
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value cannot be decoded as String or Int"
            )
        }
    }
    
    /// Encode.
    /// - Parameters:
    ///   - encoder: Encoder
    /// - Throws: Error if operation fails
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
}


struct TripRequestResponse: Codable {
    var clazz: String
    var limit: Int
    var offset: Int
    var timestamp: Int64
    var total: Int
    var data: [TripNotificationResponse]
}

struct CheckItineraryResponse: Codable {
    var id: String
    var lastUpdated: Int
    var dateCreated: Int
    var monday: WeekdaysAvaliability
    var tuesday: WeekdaysAvaliability
    var wednesday: WeekdaysAvaliability
    var thursday: WeekdaysAvaliability
    var friday: WeekdaysAvaliability
    var saturday: WeekdaysAvaliability
    var sunday:WeekdaysAvaliability
    var message: String?
    var error: Bool
    var timestamp: Int
    
}

struct WeekdaysAvaliability: Codable {
    var invalidDates: [String]
    var validDates: [String]
    var valid: Bool
}
