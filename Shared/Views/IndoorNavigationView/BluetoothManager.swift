//
//  BluetoothManager.swift
//

import Foundation
import CoreBluetooth
import SwiftUI
import CoreLocation

struct BluetoothSpecs: Identifiable{
    var name: String
    var id: String
    var rssi: String
    var passBySpeed: Double
    var location: CLLocationCoordinate2D?
    var timestamp: Double
    
    /// Description
    /// - Returns: String
    /// Description.
    func description() -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let strDate = dateFormatter.string(from: date)
        return "\(name) - \(id):\n\(strDate)\nRSSI: \(rssi), Travel Speed:\(passBySpeed.rounded())kms, latitude: \(location?.latitude ?? 0), longitude: \(location?.longitude ?? 0),Detected Time:\(timestamp)"
    }
}

class BluetoothManager: NSObject, ObservableObject{
    
    private var isScanning = false
    private var bluetoothManager:CBCentralManager?
    
    public var didNearbyBeaconChanged: ((BluetoothSpecs)->Void)?
    
    /// Shared.
    /// - Parameters:
    ///   - BluetoothManager: Parameter description
    static var shared: BluetoothManager = {
        let instance = BluetoothManager()
        return instance
    }()
    
    /// Initializes a new instance.
    override init() {
        /// Initializes a new instance.
        super.init()
        bluetoothManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:false])
    }
    
    /// Start scan
    /// Starts scan.
    func startScan(){
        self.isScanning = true
        if let central = bluetoothManager {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            OTPLog.log(level: .info, info: "Start scan bluetooth devices ....")
        }
    }
    
    /// Stop scan
    /// Stops scan.
    func stopScan(){
        self.isScanning = false
        if let central = bluetoothManager {
            central.stopScan()
            OTPLog.log(level: .info, info: "Complete Stop bluetooth Scanning ....")
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    /// Central manager did update state.
    /// - Parameters:
    ///   - _: Parameter description
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOff:
            OTPLog.log(level: .info, info: "Bluetooth Device Power Off")
          break
        case .poweredOn:
            OTPLog.log(level: .info, info: "Bluetooth Device Power On")
          break
        default:
          break
        }
    }
}
