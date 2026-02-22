//
//  OTPPlanTrip.swift
//

import Foundation

// MARK: - Accessibility Score value
enum AccessibilityScore {
    case accessible
    case accessibilityUnknown
    case notAccessible
    case noInfo
}

// MARK: - OTPPlanTrip
public struct OTPPlanTrip: Codable {
    var routingErrors: [OTPJSONAny]?
    var itineraries: [OTPItinerary]?
    var otp2QueryParams: String?
}

// MARK: - OTPItinerary
public struct OTPItinerary: Equatable, Codable, Identifiable{
    // object hold
	public var id: String = UUID().uuidString
    var isSelected: Bool?
    var otp2QueryParam: PlanTripVariables?
    
    // json decoder hold
    var legs: [OTPLeg]?
    var waitingTime, startTime, endTime, walkTime, duration : Int?
    var accessibilityScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case legs
        case waitingTime, startTime, endTime, walkTime, duration, accessibilityScore
    }
	
 /// Copy
 /// - Returns: OTPItinerary
 /// Copy.
	public func copy() -> OTPItinerary {
		var newLegsCopy = [OTPLeg]()
		if let legs = legs {
			for leg in legs {
				newLegsCopy.append(leg.copy())
			}
		}
        var new = OTPItinerary(id: id, isSelected: isSelected, otp2QueryParam: otp2QueryParam, legs: newLegsCopy, waitingTime: waitingTime, startTime: startTime, endTime: endTime, walkTime: walkTime, duration: duration, accessibilityScore: accessibilityScore)
		return new
	}
}

// MARK: - Leg
public struct OTPLeg: Equatable, Codable {
	
	// This preview step Id is only used for tracking the preview click
	public var previewStepId: String? = UUID().uuidString
	
    var startTime, endTime, departureDelay: Int?
    var duration: Double?
    var interlineWithPreviousLeg: Bool?
    var mode: String?
    var distance: Double?
    var transitLeg, realTime: Bool?
    var arrivalDelay: Int?
    var rentedBike: Bool?
    var accessibilityScore: Double?
    var headsign: String?
    var fareProducts: [OTPFareProduct]?
    var legGeometry: OTPLegGeometry?
    var steps: [OTPStep]?
    var from: OTPLocation?
    var pickupType: OTPDropoffTypeEnum?
    var to: OTPLocation?
    var dropoffType: OTPDropoffTypeEnum?
    var agency: OTPAgency?
    var intermediateStops: [OTPIntermediateStop]?
    var trip: OTPTrip?
    var route: OTPRoute?
    var alerts: [OTPAlert?]?
    
    var searchMode : SearchMode? {
        if let mode = self.mode{
            let allModesList = FeatureConfig.shared.allModesList
            if let searchMode = allModesList.first(where: { $0.mode == mode}){
                return searchMode
            } else {
                OTPLog.log(info: "Didn't find Mode Value- \(mode) in our Generic Mode List")
                return allModesList.count > 0 ? allModesList.first! : SearchMode(mode: "BUS", label: "Bus", mode_image: "ic_bus", marker_image: "ic_marker_bus", line_color: "#7da8ef", color: "#e05522")
            }
        }
        return nil
    }
	
 /// Copy
 /// - Returns: OTPLeg
 /// Copy.
	public func copy() -> OTPLeg {
		var new = OTPLeg(previewStepId: previewStepId, startTime: startTime, endTime: endTime, departureDelay: departureDelay, duration: duration, interlineWithPreviousLeg: interlineWithPreviousLeg, mode: mode, distance: distance, transitLeg: transitLeg, realTime: realTime, arrivalDelay: arrivalDelay, rentedBike: rentedBike, accessibilityScore: accessibilityScore, headsign: headsign, fareProducts: fareProducts, legGeometry: legGeometry, steps: steps, from: from, pickupType: pickupType, to: to, dropoffType: dropoffType, agency: agency, intermediateStops: intermediateStops, trip: trip, route: route, alerts: alerts)
		return new
	}
}

// MARK: - Agency
public struct OTPAgency:Equatable, Codable {
	var timezone, url, name: String?
	var alerts: [OTPAlert?]?
	var id: String?

	enum CodingKeys: String, CodingKey {
		case timezone, url, name
		case alerts, id
	}
	
	public static func == (lhs: OTPAgency, rhs: OTPAgency) -> Bool {
		return lhs.timezone == rhs.timezone &&
		lhs.url == rhs.url &&
		lhs.name == rhs.name &&
		lhs.id == rhs.id
	}
}

enum OTPDropoffTypeEnum: String, Codable {
	/// Regularly scheduled pickup / drop off.
	case scheduled = "SCHEDULED"
	/// No pickup / drop off available.
	case none = "NONE"
	/// Must phone agency to arrange pickup / drop off.
	case callAgency = "CALL_AGENCY"
	/// Must coordinate with driver to arrange pickup / drop off.
	case coordinateWithDriver = "COORDINATE_WITH_DRIVER"
	
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPDropoffTypeEnum(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - OTPFareProduct
public struct OTPFareProduct: Codable {
	var id: String?
	var product: OTPProduct?

	enum CodingKeys: String, CodingKey {
		case id, product
	}
	
	public static func == (lhs: OTPFareProduct, rhs: OTPFareProduct) -> Bool {
		return lhs.id == rhs.id &&
		lhs.product == rhs.product
	}
}

// MARK: - Product
public struct OTPProduct: Equatable, Codable {
	var medium: OTPMedium?
	var name: OTPProductName?
	var riderCategory: OTPMedium?
	var id: OTPProductID?
	var price: OTPPrice?

	enum CodingKeys: String, CodingKey {
		case medium, name
		case riderCategory, id, price
	}
	
	public static func == (lhs: OTPProduct, rhs: OTPProduct) -> Bool {
		return lhs.medium == rhs.medium &&
		lhs.name == rhs.name &&
		lhs.riderCategory == rhs.riderCategory &&
		lhs.id == rhs.id &&
		lhs.price == rhs.price
	}
}

enum OTPProductID: String, Codable {
    case orcaElectronicRegular = "atlanta:electronicRegular"
    case orcaElectronicSenior = "atlanta:electronicSenior"
    case orcaElectronicSpecial = "atlanta:electronicSpecial"
    case orcaElectronicYouth = "atlanta:electronicYouth"
    case orcaFarePayment = "atlanta:farePayment"
    case orcaRegular = "atlanta:regular"
    case orcaSenior = "atlanta:senior"
    case orcaYouth = "atlanta:youth"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPProductID(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - Medium
public struct OTPMedium: Equatable, Hashable, Codable {
	var name: OTPMediumName?
	var id: OTPMediumID?

	enum CodingKeys: String, CodingKey {
		case name
		case id
	}
	
	public static func == (lhs: OTPMedium, rhs: OTPMedium) -> Bool {
		return lhs.name == rhs.name &&
		lhs.id == rhs.id
	}
}

enum OTPMediumID: String, Codable {
	case orcaCash = "atlanta:cash"
	case orcaElectronic = "atlanta:electronic"
	case orcaRegular = "atlanta:regular"
	case orcaSenior = "atlanta:senior"
	case orcaSpecial = "atlanta:special"
	case orcaYouth = "atlanta:youth"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPMediumID(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

enum OTPMediumName: String, Codable {
	case cash = "cash"
	case electronic = "electronic"
	case regular = "regular"
	case senior = "senior"
	case special = "special"
	case youth = "youth"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPMediumName(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
    /// Lable
    /// - Returns: String
    /// Lable.

    /// - Returns: String
    func lable() -> String {
        return self.rawValue.uppercased()
    }
}

enum OTPMediumTypename: String, Codable {
	case fareMedium = "FareMedium"
	case riderCategory = "RiderCategory"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPMediumTypename(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

enum OTPProductName: String, Codable {
    case electronicRegular = "electronicRegular"
    case electronicSenior = "electronicSenior"
    case electronicSpecial = "electronicSpecial"
    case electronicYouth = "electronicYouth"
    case regular = "regular"
    case rideCost = "rideCost"
    case senior = "senior"
    case transfer = "transfer"
    case youth = "youth"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPProductName(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - Price
public struct OTPPrice: Equatable, Codable {
	var currency: OTPCurrency?
	var amount: Double?

	enum CodingKeys: String, CodingKey {
		case currency, amount
	}
	
	public static func == (lhs: OTPPrice, rhs: OTPPrice) -> Bool {
		return lhs.currency == rhs.currency &&
		lhs.amount == rhs.amount
	}
}

// MARK: - Currency
public struct OTPCurrency: Equatable, Codable {
	var code: OTPCode?
	var digits: Int?

	enum CodingKeys: String, CodingKey {
		case code, digits
	}
	
	public static func == (lhs: OTPCurrency, rhs: OTPCurrency) -> Bool {
		return lhs.code == rhs.code &&
		lhs.digits == rhs.digits
	}
}

enum OTPCode: String, Codable {
	case usd = "USD"
	case unknown = "Unknown"
    
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPCode(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - From
public struct OTPLocation:Equatable, Codable {
	var name: String?
	var lon: Double?
	var vertexType: OTPVertexType?
	var lat: Double?
	var stop: OTPLocationStop?
	var rentalVehicle: OTPRentalVehicle?

	enum CodingKeys: String, CodingKey {
		case name, lon, vertexType, lat, stop, rentalVehicle
	}
    
    /// Meaningful name
    /// - Returns: String
    /// Meaningful name.
    func meaningfulName() -> String {
        if let rentalVehicle = self.rentalVehicle, let network = rentalVehicle.network {
            if network == Network.limeSeattle.rawValue {
                return "LIME Vehicle"
            }
            if network == Network.birdSeattleWashington.rawValue {
                return "Bird Vehicle"
            }
            if network == Network.linkSeattle.rawValue {
                return "LINK Vehicle"
            }
        }
        return self.name ?? ""
    }
}

// MARK: - RentalVehicle
public struct OTPRentalVehicle:Equatable, Codable {
	var network, id: String?
    var vehicleType: VehicleType?

	enum CodingKeys: String, CodingKey {
		case network, id, vehicleType
	}
	
	public static func == (lhs: OTPRentalVehicle, rhs: OTPRentalVehicle) -> Bool {
        return lhs.network == rhs.network && lhs.id == rhs.id && lhs.vehicleType == rhs.vehicleType
	}
}

// MARK: - FromStop
public struct OTPLocationStop:Equatable, Codable {
	var gtfsID: String?
	var alerts: [OTPJSONAny]?
	var id, code: String?   // we will need to add name later.

	enum CodingKeys: String, CodingKey {
		case gtfsID = "gtfsId"
		case alerts
		case id, code
	}
	
	public static func == (lhs: OTPLocationStop, rhs: OTPLocationStop) -> Bool {
		return lhs.gtfsID == rhs.gtfsID && lhs.id == rhs.id && lhs.id == rhs.code
	}
}

enum OTPVertexType: String, Codable {
	/// NORMAL
	case normal = "NORMAL"
	/// TRANSIT
	case transit = "TRANSIT"
	/// BIKEPARK
	case bikepark = "BIKEPARK"
	/// BIKESHARE
	case bikeshare = "BIKESHARE"
	/// PARKANDRIDE
	case parkandride = "PARKANDRIDE"
	
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPVertexType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - IntermediateStop
public struct OTPIntermediateStop: Codable {
	var name: String?
	var locationType: OTPLocationType?
	var stopCode: String?
	var lon: Double?
	var stopID: String?
	var lat: Double?

	enum CodingKeys: String, CodingKey {
		case name, locationType, stopCode
		case lon
		case stopID = "stopId"
		case lat
	}
	
	public static func == (lhs: OTPIntermediateStop, rhs: OTPIntermediateStop) -> Bool {
		return lhs.name == rhs.name &&
		lhs.locationType == rhs.locationType &&
		lhs.stopCode == rhs.stopCode &&
		lhs.lon == rhs.lon &&
		lhs.stopID == rhs.stopID &&
		lhs.lat == rhs.lat
	}
}

enum OTPLocationType: String, Codable {
	/// A location where passengers board or disembark from a transit vehicle.
	case stop = "STOP"
	/// A physical structure or area that contains one or more stop.
	case station = "STATION"
	case entrance = "ENTRANCE"
	
	case unknown = "Unknown"
	public init(from decoder: Decoder) throws {
		self = try OTPLocationType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - OTPLegGeometry
public struct OTPLegGeometry:Equatable, Codable {
	var points: String?
	var length: Int?

	enum CodingKeys: String, CodingKey {
		case points
		case length
	}
	
	public static func == (lhs: OTPLegGeometry, rhs: OTPLegGeometry) -> Bool {
		return lhs.length == rhs.length && lhs.points == rhs.points
	}
}
// MARK: - Route
public struct OTPRoute:Equatable, Codable {
	var gtfsID: String?
	var type: Int?
	var id: String?
	var alerts: [OTPAlert?]?
	var color, shortName, longName, textColor: String?

	enum CodingKeys: String, CodingKey {
		case gtfsID = "gtfsId"
		case type, id, alerts, color, shortName, textColor, longName
	}
	
	public static func == (lhs: OTPRoute, rhs: OTPRoute) -> Bool {
		return lhs.gtfsID == rhs.gtfsID &&
		lhs.type == rhs.type &&
		lhs.id == rhs.id &&
		lhs.color == rhs.color &&
		lhs.shortName == rhs.shortName &&
		lhs.longName == rhs.longName &&
		lhs.textColor == rhs.textColor
	}
}

public struct OTPAlert: Codable {
    let id: String?
    let alertDescriptionText: String?
    let alertHeaderText: String?
    let alertUrl: String?
    let effectiveStartDate: Int?
    
    enum CodingKeys: CodingKey {
        case id, alertDescriptionText, alertHeaderText, alertUrl, effectiveStartDate
    }
}

// MARK: - OTPStep
public struct OTPStep: Codable {
	var distance: Double?
	var relativeDirection: OTPRelativeDirection?
	var alerts: [OTPJSONAny]?
	var lon, lat: Double?
	var absoluteDirection: OTPAbsoluteDirection?
	var area: Bool?
	var elevationProfile: [OTPJSONAny]?
	var streetName: String?
	var stayOn: Bool?

	enum CodingKeys: String, CodingKey {
		case distance, relativeDirection, alerts, lon, lat, absoluteDirection
		case area, elevationProfile, streetName, stayOn
	}
	
	public static func == (lhs: OTPStep, rhs: OTPStep) -> Bool {
		return lhs.distance == rhs.distance &&
		lhs.relativeDirection == rhs.relativeDirection &&
		lhs.lon == rhs.lon &&
		lhs.lat == rhs.lat &&
		lhs.absoluteDirection == rhs.absoluteDirection &&
		lhs.area == rhs.area &&
		lhs.streetName == rhs.streetName &&
		lhs.stayOn == rhs.stayOn
	}
}

enum OTPAbsoluteDirection: String, Codable {
	case north = "NORTH"
	case northeast = "NORTHEAST"
	case east = "EAST"
	case southeast = "SOUTHEAST"
	case south = "SOUTH"
	case southwest = "SOUTHWEST"
	case west = "WEST"
	case northwest = "NORTHWEST"
	
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPAbsoluteDirection(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

enum OTPRelativeDirection: String, Codable {
	case depart = "DEPART"
	case hardLeft = "HARD_LEFT"
	case left = "LEFT"
	case slightlyLeft = "SLIGHTLY_LEFT"
	case `continue` = "CONTINUE"
	case slightlyRight = "SLIGHTLY_RIGHT"
	case right = "RIGHT"
	case hardRight = "HARD_RIGHT"
	case circleClockwise = "CIRCLE_CLOCKWISE"
	case circleCounterclockwise = "CIRCLE_COUNTERCLOCKWISE"
	case elevator = "ELEVATOR"
	case uturnLeft = "UTURN_LEFT"
	case uturnRight = "UTURN_RIGHT"
	case unknown = "Unknown"
 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public init(from decoder: Decoder) throws {
		self = try OTPRelativeDirection(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

// MARK: - Trip
public struct OTPTrip: Equatable, Codable {
	var gtfsID, tripHeadsign: String?
    var id: String?
    var departureStoptime: OTPStoptime?
	var arrivalStoptime: OTPStoptime?

	enum CodingKeys: String, CodingKey {
		case gtfsID = "gtfsId"
		case tripHeadsign
		case departureStoptime, id, arrivalStoptime
	}
	
	public static func == (lhs: OTPTrip, rhs: OTPTrip) -> Bool {
		return lhs.gtfsID == rhs.gtfsID &&
		lhs.tripHeadsign == rhs.tripHeadsign &&
		lhs.id == rhs.id &&
		lhs.departureStoptime == rhs.departureStoptime &&
		lhs.arrivalStoptime == rhs.arrivalStoptime
	}
}

// MARK: - Stoptime
public struct OTPStoptime:Equatable, Codable {
	var stop: OTPArrivalStoptimeStop?
	var stopPosition: Int?

	enum CodingKeys: String, CodingKey {
		case stop, stopPosition
	}
	
	public static func == (lhs: OTPStoptime, rhs: OTPStoptime) -> Bool {
		return lhs.stopPosition == rhs.stopPosition &&
		lhs.stop == rhs.stop
	}
}

// MARK: - ArrivalStoptimeStop
public struct OTPArrivalStoptimeStop: Equatable, Codable {
	var gtfsID, id: String?
	enum CodingKeys: String, CodingKey {
		case gtfsID = "gtfsId"
		case id
	}
	public static func == (lhs: OTPArrivalStoptimeStop, rhs: OTPArrivalStoptimeStop) -> Bool {
		return lhs.gtfsID == rhs.gtfsID &&
		lhs.id == rhs.id
	}
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

	public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
		return true
	}

 /// Hash.
 /// - Parameters:
 ///   - into: Parameter description
	public func hash(into hasher: inout Hasher) {}

	public init() {}

 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public required init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		if !container.decodeNil() {
			throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
		}
	}

 /// Encode.
 /// - Parameters:
 ///   - encoder: Encoder
 /// - Throws: Error if operation fails
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encodeNil()
	}
}

class JSONCodingKey: CodingKey {
	let key: String

 /// Initializes a new instance.
 /// - Parameters:
 ///   - intValue: Int
	required init?(intValue: Int) {
		return nil
	}

 /// Initializes a new instance.
 /// - Parameters:
 ///   - stringValue: String
	required init?(stringValue: String) {
		key = stringValue
	}

 /// Int value.
 /// - Parameters:
 ///   - Int?: Parameter description
	var intValue: Int? {
		return nil
	}

 /// String value.
 /// - Parameters:
 ///   - String: Parameter description
	var stringValue: String {
		return key
	}
}

class OTPJSONAny: Codable {

	let value: Any

 /// Decoding error.
 /// - Parameters:
 ///   - forCodingPath: Parameter description
 /// - Returns: DecodingError
	static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
		let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode OTPJSONAny")
		return DecodingError.typeMismatch(OTPJSONAny.self, context)
	}

 /// Encoding error.
 /// - Parameters:
 ///   - forValue: Parameter description
 ///   - codingPath: Parameter description
 /// - Returns: EncodingError
	static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
		let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode OTPJSONAny")
		return EncodingError.invalidValue(value, context)
	}

 /// Decode.
 /// - Parameters:
 ///   - container: SingleValueDecodingContainer
 /// - Returns: Any
 /// - Throws: Error if operation fails
	static func decode(from container: SingleValueDecodingContainer) throws -> Any {
		if let value = try? container.decode(Bool.self) {
			return value
		}
		if let value = try? container.decode(Int64.self) {
			return value
		}
		if let value = try? container.decode(Double.self) {
			return value
		}
		if let value = try? container.decode(String.self) {
			return value
		}
		if container.decodeNil() {
			return JSONNull()
		}
		throw decodingError(forCodingPath: container.codingPath)
	}

 /// Decode.
 /// - Parameters:
 ///   - container: inout UnkeyedDecodingContainer
 /// - Returns: Any
 /// - Throws: Error if operation fails
	static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
		if let value = try? container.decode(Bool.self) {
			return value
		}
		if let value = try? container.decode(Int64.self) {
			return value
		}
		if let value = try? container.decode(Double.self) {
			return value
		}
		if let value = try? container.decode(String.self) {
			return value
		}
		if let value = try? container.decodeNil() {
			if value {
				return JSONNull()
			}
		}
		if var container = try? container.nestedUnkeyedContainer() {
			return try decodeArray(from: &container)
		}
		if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
			return try decodeDictionary(from: &container)
		}
		throw decodingError(forCodingPath: container.codingPath)
	}

 /// Decode.
 /// - Parameters:
 ///   - container: inout KeyedDecodingContainer<JSONCodingKey>
 ///   - key: JSONCodingKey
 /// - Returns: Any
 /// - Throws: Error if operation fails
	static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
		if let value = try? container.decode(Bool.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(Int64.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(Double.self, forKey: key) {
			return value
		}
		if let value = try? container.decode(String.self, forKey: key) {
			return value
		}
		if let value = try? container.decodeNil(forKey: key) {
			if value {
				return JSONNull()
			}
		}
		if var container = try? container.nestedUnkeyedContainer(forKey: key) {
			return try decodeArray(from: &container)
		}
		if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
			return try decodeDictionary(from: &container)
		}
		throw decodingError(forCodingPath: container.codingPath)
	}

 /// Decode array.
 /// - Parameters:
 ///   - container: inout UnkeyedDecodingContainer
 /// - Returns: [Any]
 /// - Throws: Error if operation fails
	static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
		var arr: [Any] = []
		while !container.isAtEnd {
			let value = try decode(from: &container)
			arr.append(value)
		}
		return arr
	}

 /// Decode dictionary.
 /// - Parameters:
 ///   - container: inout KeyedDecodingContainer<JSONCodingKey>
 /// - Returns: [String: Any]
 /// - Throws: Error if operation fails
	static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
		var dict = [String: Any]()
		for key in container.allKeys {
			let value = try decode(from: &container, forKey: key)
			dict[key.stringValue] = value
		}
		return dict
	}

 /// Encode.
 /// - Parameters:
 ///   - container: inout UnkeyedEncodingContainer
 ///   - array: [Any]
 /// - Throws: Error if operation fails
	static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
		for value in array {
			if let value = value as? Bool {
				try container.encode(value)
			} else if let value = value as? Int64 {
				try container.encode(value)
			} else if let value = value as? Double {
				try container.encode(value)
			} else if let value = value as? String {
				try container.encode(value)
			} else if value is JSONNull {
				try container.encodeNil()
			} else if let value = value as? [Any] {
				var container = container.nestedUnkeyedContainer()
				try encode(to: &container, array: value)
			} else if let value = value as? [String: Any] {
				var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
				try encode(to: &container, dictionary: value)
			} else {
				throw encodingError(forValue: value, codingPath: container.codingPath)
			}
		}
	}

 /// Encode.
 /// - Parameters:
 ///   - container: inout KeyedEncodingContainer<JSONCodingKey>
 ///   - dictionary: [String: Any]
 /// - Throws: Error if operation fails
	static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
		for (key, value) in dictionary {
			let key = JSONCodingKey(stringValue: key)!
			if let value = value as? Bool {
				try container.encode(value, forKey: key)
			} else if let value = value as? Int64 {
				try container.encode(value, forKey: key)
			} else if let value = value as? Double {
				try container.encode(value, forKey: key)
			} else if let value = value as? String {
				try container.encode(value, forKey: key)
			} else if value is JSONNull {
				try container.encodeNil(forKey: key)
			} else if let value = value as? [Any] {
				var container = container.nestedUnkeyedContainer(forKey: key)
				try encode(to: &container, array: value)
			} else if let value = value as? [String: Any] {
				var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
				try encode(to: &container, dictionary: value)
			} else {
				throw encodingError(forValue: value, codingPath: container.codingPath)
			}
		}
	}

 /// Encode.
 /// - Parameters:
 ///   - container: inout SingleValueEncodingContainer
 ///   - value: Any
 /// - Throws: Error if operation fails
	static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
		if let value = value as? Bool {
			try container.encode(value)
		} else if let value = value as? Int64 {
			try container.encode(value)
		} else if let value = value as? Double {
			try container.encode(value)
		} else if let value = value as? String {
			try container.encode(value)
		} else if value is JSONNull {
			try container.encodeNil()
		} else {
			throw encodingError(forValue: value, codingPath: container.codingPath)
		}
	}

 /// Initializes a new instance.
 /// - Parameters:
 ///   - decoder: Decoder
 /// - Throws: Error if operation fails
	public required init(from decoder: Decoder) throws {
		if var arrayContainer = try? decoder.unkeyedContainer() {
			self.value = try OTPJSONAny.decodeArray(from: &arrayContainer)
		} else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
			self.value = try OTPJSONAny.decodeDictionary(from: &container)
		} else {
			let container = try decoder.singleValueContainer()
			self.value = try OTPJSONAny.decode(from: container)
		}
	}

 /// Encode.
 /// - Parameters:
 ///   - encoder: Encoder
 /// - Throws: Error if operation fails
	public func encode(to encoder: Encoder) throws {
		if let arr = self.value as? [Any] {
			var container = encoder.unkeyedContainer()
			try OTPJSONAny.encode(to: &container, array: arr)
		} else if let dict = self.value as? [String: Any] {
			var container = encoder.container(keyedBy: JSONCodingKey.self)
			try OTPJSONAny.encode(to: &container, dictionary: dict)
		} else {
			var container = encoder.singleValueContainer()
			try OTPJSONAny.encode(to: &container, value: self.value)
		}
	}
}
