//
//  Shape+Extension.swift
//

import SwiftUI

/// Used to clip the view to round corner
struct RoundedCorner: SwiftUI.Shape {
	
	/// CGFloat value for the radius
	var radius: CGFloat = .infinity
	
	/// Corner position
	var corners: UIRectCorner = .allCorners
	
	/// Use the path to decide the rounder corner shape
	func path(in rect: CGRect) -> SwiftUI.Path {
		 let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		 return Path(path.cgPath)
	}
}

struct BlurView: View {
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return VStack{
                    HStack{
                        Spacer()
                    }
                 Spacer()
               }
               .background(Color.black)
               .opacity(0.5)
    }
}
