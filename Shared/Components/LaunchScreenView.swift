//
//  LaunchScreenView.swift
//

import SwiftUI

struct LaunchScreenView: View {
    @Binding var showLaunchScreen:Bool
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
		ZStack{
			Color.white
			VStack(spacing: 0){
				HStack{
					Spacer()
				}
				.frame(height:ScreenSize.safeTop())
				.padding(0)
				Image("launchImage")
					.resizable()
					.frame(maxWidth: 1242, maxHeight: 2668)
					.aspectRatio(contentMode: .fit)
			}.padding(0)
		}
		.padding(0)
		.edgesIgnoringSafeArea(.all)
		.onAppear(perform: {
			DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
				self.showLaunchScreen = false
			}
		})
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        LaunchScreenView(showLaunchScreen: .constant(true))
    }
}
