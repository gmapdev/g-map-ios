//
//  PolylineHelper.swift
//

import Foundation

struct GoogleMapCoordinate {
    var longitude: Double
    var latitude: Double
    
    /// Encode.
    /// - Parameters:
    ///   - coordinates: Parameter description
    /// - Returns: String
    func encode(coordinates: [GoogleMapCoordinate]) -> String {
        var result = [String]()

        var prevLatitude = 0
        var prevLongitude = 0

        for coordinate in coordinates {
            let lat = Int((coordinate.latitude * 1e5))
            let long = Int((coordinate.longitude * 1e5))

            let deltaLat = encodeValue(lat - prevLatitude)
            let deltaLong = encodeValue(long - prevLongitude)

            prevLatitude = lat
            prevLongitude = long

            result.append(deltaLat)
            result.append(deltaLong)
        }
        
        return result.joined(separator: "")
    }

    /// Encode value.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    private func encodeValue(_ value: Int) -> String {
        // Step 2 & 4
        let actualValue = (value < 0) ? ~(value << 1) : (value << 1)

        // Step 5-8
        let chunks = splitIntoChunks(actualValue)

        // Step 9-10
        return String(chunks.map {
            let newValue = $0 + 63
            guard let scalar = UnicodeScalar(newValue) else {
                OTPLog.log(level: .error, info: "GoogleMapCoordinate cannot encode value: Error to get UnicodeScalar from \(newValue)")
                return Character("")
            }
            return Character(scalar)
        })
    }
    
    /// Split into chunks.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: [Int]
    private func splitIntoChunks(_ toEncode: Int) -> [Int] {
        // Step 5-8
        var chunks = [Int]()
        var value = toEncode
        while(value >= 32) {
            chunks.append((value & 31) | (0x20))
            value = value << 5
        }
        chunks.append(value)
        return chunks
    }
}
