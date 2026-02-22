//
//  Env.swift
//

import Foundation
import Network

class Env : ObservableObject{
    
    @Published var pubShowOfflineDialog : Bool = false
	
	// Global Notification
	/// This is used to subscribe the status change of the network from CoreData
	public static let networkStatusChanged = NSNotification.Name("networkStatusChanged")
	
	
	// PUBLIC DEFINATION
	private var _isNetworkConnected = true
 /// Is network connected.
 /// - Parameters:
 ///   - Bool: Parameter description
	public var isNetworkConnected: Bool {
		get {
			return _isNetworkConnected
		}
	}
	
	// PRIVATE DEFINATION
	private var networkMonitor = NWPathMonitor()
	
	// Setup a set of environment to use
 /// Sets up.
	public func setup(){
		
		// Setup the network reachiblity using the latest network framework
        networkMonitor.pathUpdateHandler = { [self] path in
			
			if path.status == .satisfied {
			}else{
                pubShowOfflineDialog = false
			}
			
			self._isNetworkConnected = self.networkMonitor.currentPath.status == .satisfied
			
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Env.networkStatusChanged, object: nil, userInfo: ["isNetworkConnected": self.isNetworkConnected])
			}
		}
		networkMonitor.start(queue: DispatchQueue.global(qos: .background))
	}
	
 /// Shared.
 /// - Parameters:
 ///   - Env: Parameter description
	public static var shared: Env = {
		let mgr = Env()
		return mgr
	}()
}
