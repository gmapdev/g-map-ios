//
//  CollapsedSearchBarView.swift
//

import SwiftUI

struct CollapsedSearchBarView: View {
	@ObservedObject var liveRoute = LiveRouteManager.shared
	@ObservedObject var previewTripManager = PreviewTripManager.shared
    @State var hideAddressBar:Bool
    var backAction: (() -> Void)? = nil
    var collapseAction: (() -> Void)? = nil

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        collapsedView()
    }
    
    /// Collapsed view
    /// - Returns: some View
    /// Collapsed view.
    func collapsedView() -> some View{
        ZStack{
            HStack{
                backButton
                    .offset(y: -10)
                    .frame(width: 48, height: 48, alignment: .center)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                    .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
                    .accessibilityAction {
                        if LiveRouteManager.shared.pubIsPreviewMode {
                            // if the Preview Mode is on, make it off
                            LiveRouteManager.shared.dismissPreviewMode()
                        }else if LiveRouteManager.shared.pubIsRouteActivated {
                            // If we are in the activated route mode, then, we disable it
                            LiveRouteManager.shared.resetLiveTracking()
                        }else{
                            backAction?()
                        }
                    }
                Spacer()
				if !liveRoute.pubIsRouteActivated {
					collapseButton
						.frame(width: 48, height: 48, alignment: .center)
						.background(Color.white)
						.clipShape(Circle())
						.shadow(radius: 5)
				}
				
				// this is the alert when the route activation is enabled and live route preview mode is enabled.
				if liveRoute.pubIsRouteActivated && liveRoute.pubIsPreviewMode {
					previewAudioButton
						.frame(width: 48, height: 48, alignment: .center)
						.background(Color.white)
						.clipShape(Circle())
						.shadow(radius: 5)
				}
            }
        }
    }
	
 /// Preview audio button.
 /// - Parameters:
 ///   - some: Parameter description
	private var previewAudioButton: some View {
		Button {
			previewTripManager.pubEnableTTSText.toggle()
		} label: {
			Image(systemName: previewTripManager.pubEnableTTSText ? "bell.badge" : "bell")
				.renderingMode(.template)
				.resizable()
				.foregroundColor(.black)
				.frame(width: 25, height: 25)
				
		}.background(Color.white)
			.frame(width: 48, height: 48, alignment: .center)
			.addAccessibility(text: (hideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
	}
    
    /// Collapse button.
    /// - Parameters:
    ///   - some: Parameter description
    private var collapseButton: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                collapseAction?()
            }
        } label: {
            Image(hideAddressBar ? "btn_expand" : "btn_collapse")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.black)
                
        }.background(Color.white)
            .frame(width: 48, height: 48, alignment: .center)
            .addAccessibility(text: (hideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
    
    /// Back button.
    /// - Parameters:
    ///   - some: Parameter description
    private var backButton: some View {
        Button(action: {
            if LiveRouteManager.shared.pubIsPreviewMode {
                // if the Preview Mode is on, make it off
                LiveRouteManager.shared.dismissPreviewMode()
            }else if LiveRouteManager.shared.pubIsRouteActivated {
                // If we are in the activated route mode, then, we disable it
                LiveRouteManager.shared.resetLiveTracking()
            }else{
				backAction?()
			}
        }) {
            Image("ic_leftarrow")
                .renderingMode(.template)
                .resizable()
                .padding(5)
                .foregroundColor(.black)
        }
        .frame(width: 25, height: 30)
        .padding(.top, 20)
    }
}

struct CollapsedSearchBarView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        CollapsedSearchBarView(hideAddressBar: true)
    }
}
