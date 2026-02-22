//
//  LoadingViewFullPage.swift
//

import Foundation
import SwiftUI

struct LoadingViewFullPage: View {
    var showBackground: Bool
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		return
			ZStack{
				  VStack{
					  HStack{
						  Spacer()
					  }
					  Spacer()
				  }.zIndex(998)
                if showBackground {
                    BlurView()
                }
				  VStack{
					  Spacer()
					  HStack{
						  Spacer()
						  VStack {
							  Spacer().frame(height:30)
                              TextLabel("Loading...".localized()).font(.footnote).foregroundColor(Color.black).padding(3)
							  ActivityIndicator(isAnimating: .constant(true), style: .large)
							  Spacer().frame(height:30)
						  }
						  .frame(minWidth: 100, minHeight: 100)
                          .background(Color.white)
						  .foregroundColor(Color.primary)
						  .cornerRadius(10)
						  Spacer()
					  }
					  Spacer().frame(height:UIScreen.main.bounds.size.height/2*0.8)
				  }.zIndex(999)
			  }
			  .zIndex(9999)
	}
}
