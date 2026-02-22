//
//  AlertManager.swift
//

import Foundation

enum AlertType: String {
	case confirm
	case alert
}

class AlertManager: ObservableObject {
	
	@Published var presentAlert: Bool = false
	
	var alertType = AlertType.alert
	
	var alertTitle = ""
	var alertMessage = ""
	
	var confirmTitle = ""
	var confirmMessage = ""
	var confirmPrimaryButtonText = "Cancel".localized()
	var confirmSecondaryButtonText = "Yes".localized()
	var confirmCallback:((String)->Void)? = nil	// String indicate which button trigger the callback
	
 /// Shared.
 /// - Parameters:
 ///   - AlertManager: Parameter description
	public static var shared: AlertManager = {
		let mgr = AlertManager()
		return mgr
	}()
	
 /// Present alert.
 /// - Parameters:
 ///   - title: Parameter description
 ///   - message: Parameter description
	func presentAlert(title: String = "", message: String){
		self.alertTitle = title
		self.alertType = .alert
		self.alertMessage = message
        
		DispatchQueue.main.async {
			self.presentAlert = true
		}
	}
	
 /// Present confirm.
 /// - Parameters:
 ///   - title: Parameter description
 ///   - message: Parameter description
 ///   - primaryButtonText: Parameter description
 ///   - secondaryButtonText: Parameter description
 ///   - callback: Parameter description
 /// - Returns: Void)? = nil)
	func presentConfirm(title: String = "", message: String, primaryButtonText: String = "Cancel".localized(), secondaryButtonText: String = "Yes".localized(), callback: ((String) -> Void)? = nil) {
		self.confirmTitle = title
		self.alertType = .confirm
		self.confirmMessage = message
		self.confirmCallback = callback
		self.confirmPrimaryButtonText = primaryButtonText
		self.confirmSecondaryButtonText = secondaryButtonText
		DispatchQueue.main.async {
			self.presentAlert = true
		}
	}
}
