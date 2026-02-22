//
//  Orientation.swift
//

import Foundation
import SwiftUI

/// This class is used to listen to the screen rotation event, at the same time, it tells us it is wide screen mode or narrow screen mode for us to easily layout our control element.
final class Orientation {
	
	/// Define the wide/narrow screen mode, wide mode comply with the regular/compact design guideline from Apple.
	public enum ScreenMode {
		
		/// Vertical is compact, horizental is any; or vertical and horizental are both regular
		case wide
		
		/// Vertical is regular and horizental is not regular
		case narrow
	}

	
	/// This is used to get the current screen mode for the ui element to layout
 /// Screen mode.
 /// - Parameters:
 ///   - vSizeClass: UserInterfaceSizeClass?
 ///   - hSizeClass: UserInterfaceSizeClass?
 /// - Returns: ScreenMode
	public static func screenMode(_ vSizeClass: UserInterfaceSizeClass?, _ hSizeClass: UserInterfaceSizeClass?) -> ScreenMode {
		if vSizeClass == .compact {
			return .wide
		}
		else if vSizeClass == .regular && hSizeClass == .regular {
			return .wide
		}
		
		return .narrow
	}
	
 /// Is portrait
 /// - Returns: Bool
 /// Checks if portrait.
	public static func isPortrait() -> Bool {
		var isPortrait = true
		if UIDevice.current.orientation.isPortrait {}
		else if UIDevice.current.orientation.isFlat {
			if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {}
			else{ isPortrait = false}
		}else{
			isPortrait = false
		}
		return isPortrait
	}
}

/// This class is used to return a certain of useful screen size, value will change when we rotate
final class ScreenSize {

	/// Gets the key window using the modern scene-based API for iOS 26.2+ compatibility
	private static func getKeyWindow() -> UIWindow? {
		// Use scene-based API for iOS 13+
		if let windowScene = UIApplication.shared.connectedScenes
			.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
			return windowScene.windows.first(where: { $0.isKeyWindow })
		}
		// Fallback for older iOS versions
		return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
	}

 /// Safe leading
 /// - Returns: CGFloat
	public static func safeLeading() -> CGFloat {
		guard let window = getKeyWindow() else {
			return 0
		}
		return window.safeAreaInsets.left
	}

 /// Safe trailing
 /// - Returns: CGFloat
 /// Safe trailing.
	public static func safeTrailing() -> CGFloat {
		guard let window = getKeyWindow() else {
			return 0
		}
		return window.safeAreaInsets.right
	}

 /// Safe top
 /// - Returns: CGFloat
 /// Safe top.
	public static func safeTop() -> CGFloat {
		guard let window = getKeyWindow() else {
			return 0
		}
		return window.safeAreaInsets.top
	}

 /// Safe bottom
 /// - Returns: CGFloat
 /// Safe bottom.
	public static func safeBottom() -> CGFloat {
		guard let window = getKeyWindow() else {
			return 0
		}
		return window.safeAreaInsets.bottom
	}

    /// Width
    /// - Returns: CGFloat
    /// Width.
    public static func width() -> CGFloat {
        guard let window = getKeyWindow() else {
            return 0
        }
        return window.frame.width
    }

    /// Height
    /// - Returns: CGFloat
    /// Height.
    public static func height() -> CGFloat {
        guard let window = getKeyWindow() else {
            return 0
        }
        return window.frame.height
    }
}
