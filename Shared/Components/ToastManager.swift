//
//  ToastManager.swift
//

import Foundation
import SwiftUI

/// Control and show the toast in the app.
class ToastManager: ObservableObject {

    @Published var pubPresentToastView = false
    
    // This is used to hold the message for the toast
    public var message: String = ""

    /// Shared.
    /// - Parameters:
    ///   - ToastManager: Parameter description
    public static var shared: ToastManager = {
        let mgr = ToastManager()
        return mgr
    }()
    
    /// This is used to show the message for the toast in the app
    /// Shows.
    /// - Parameters:
    ///   - message: String
    ///   - delay: Double = 0.5
    ///   - duration: Double = 2.5
    public static func show(message: String, delay: Double = 0.5, duration: Double = 2.5){
        shared.message = message
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation {
                shared.pubPresentToastView = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                shared.hideToast()
            }
        }
    }
    
    /// This is used to automatically hide the toast in the app
    /// Hides toast.
    private func hideToast(){
        DispatchQueue.main.async {
            withAnimation {
                self.pubPresentToastView = false
            }
        }
    }
}
