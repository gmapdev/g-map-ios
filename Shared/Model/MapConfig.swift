//
//  MapConfig.swift
//

import Foundation
import CoreLocation

enum MapStyle: String, Codable {
    case satellite, streets
}

public struct MapBoundary: Codable {
    struct Rect: Codable {
        let minCoordinate: Coordinate
        let maxCoordinate: Coordinate
    }
    var rect: MapBoundary.Rect
}

struct MapConfig: Codable {
    struct DefaultLocation: Codable {
        let coordinate: Coordinate
    }
    
    let defaultLocation: DefaultLocation
    let zoomLevel: Int
    var mapStyles: [MapStyle]
    var defaultStyle: MapStyle
    let boundary: MapBoundary
}

extension Coordinate {
    /// Coordinate2 d.
    /// - Parameters:
    ///   - CLLocationCoordinate2D: Parameter description
    var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public struct TrackingLocation: Codable, Hashable {
	var bearing:Double?
	var lat: Double?
	var lon: Double?
	var speed: Double?
	var timestamp: Int?
    var locationAccuracy: Double?
}

public struct TrackingLocationResponse: Codable{
	var frequencySeconds: Double?
	var instruction: String?
	var journeyId: String?
	var tripStatus: String?
    var message: String?
    var itinery: OTPItinerary?
    
}


