//
//  TabBarPanel.swift
//

import SwiftUI

/// Simple tab bar panel that renders the bottom tab bar items.
/// Does not manage content - only displays the tab bar UI.
struct TabBarPanel: View {

	@ObservedObject var menuManager = TabBarMenuManager.shared
	@ObservedObject var liveRoute = LiveRouteManager.shared
	@ObservedObject var accessibilityManager = AccessibilityManager.shared
	@ObservedObject var stopViewerModel = StopViewerViewModel.shared
	@ObservedObject var mapFromToModel = MapFromToViewModel.shared
	@ObservedObject var session = AppSession.shared

	var body: some View {
		VStack(spacing: 0) {
			// Tab Bar - conditionally rendered based on app state
			if !liveRoute.pubIsRouteActivated {
				if accessibilityManager.pubIsLargeFontSize {
					// Render AODA-compliant tab bar for large font sizes
					renderTabBarAODA()
				} else {
					// Hide tab bar when auto complete is active to avoid accessibility announcement
					if !mapFromToModel.isPushedFrom && !mapFromToModel.isPushedTo {
						renderTabBar()
					}
				}
			}

			// Safe area bottom spacer to account for device notches/home indicators
			VStack {
				HStack { Spacer() }
				Spacer()
			}
			.frame(height: ScreenSize.safeBottom())
			.edgesIgnoringSafeArea(.bottom)
			.background(Color.white)
		}
		.onAppear {
			// Configure tabs when view appears based on login state
			Task { @MainActor in
				menuManager.configureTabs(isLoggedIn: session.loginInfo != nil)
				// Select Plan Trip by default on appear
				menuManager.selectTab(.planTrip)
			}
		}
		.onChange(of: session.loginInfo) { _ in
			// Reconfigure tabs when login state changes
			Task { @MainActor in
				menuManager.configureTabs(isLoggedIn: session.loginInfo != nil)
			}
		}
	}

	// MARK: - Tab Bar Rendering

	/// Renders the standard tab bar with menu button (if configured) and tab items.
	/// Includes accessibility traits and proper z-index layering.
	/// - Returns: A view containing the horizontal tab bar layout
	private func renderTabBar() -> some View {
		HStack {
			// Menu button if configured in feature settings
			if FeatureConfig.shared.menu.count > 0 {
				menuButton()
			}

			// Render all available tab items - use refreshCounter in id to force re-render
			ForEach(menuManager.availableTabs, id: \.id) { tab in
				TabBarButtonView(
					tab: tab,
					session: session,
					mapFromToModel: mapFromToModel,
					onTap: {
						tab.action()
						handlePostTapAction(for: tab.type)
					}
				)
			}
		}
		.padding(6)
		.background(Color.white)
		.padding(.bottom, 0)
		.availableAccessibility(AvailableAccessibilityItem.tabBar)
		.accessibility(addTraits: stopViewerModel.pubIsShowingStopViewer ? [.isModal] : [])
		// Use refreshCounter to force the entire HStack to re-render
		.id("tabbar-\(menuManager.refreshCounter)")
	}

	/// Renders the AODA-compliant tab bar for accessibility with large fonts.
	/// Identical layout to standard tab bar but may have different styling/behavior.
	/// - Returns: A view containing the AODA-compliant horizontal tab bar layout
	private func renderTabBarAODA() -> some View {
       VStack(spacing: 0){
            if menuManager.pubShowTabsPopUp {
                // Render all available tab items - use refreshCounter in id to force re-render
                ForEach(menuManager.availableTabs.reversed(), id: \.id) { tab in
                    if menuManager.pubSelectedTabMenuItem != tab {
                        TabBarButtonViewAODA(
                            tab: tab,
                            session: session,
                            mapFromToModel: mapFromToModel,
                            showExpander: false,
                            onTap: {
                                tab.action()
                                menuManager.pubShowTabsPopUp.toggle()
                                MapManager.shared.isMapSettings = false
                                handlePostTapAction(for: tab.type)
                            }
                        )
                    }
                }
                
                // Menu button if configured in feature settings
                if FeatureConfig.shared.menu.count > 0 {
                    menuButtonAODA()
                }
            }
           
           TabBarButtonViewAODA(tab: menuManager.pubSelectedTabMenuItem, session: session, mapFromToModel: mapFromToModel, showExpander: true) {
               if  menuManager.pubShowProfilePopUp {
                   menuManager.pubShowProfilePopUp.toggle()
                   menuManager.seletedTab = TabBarItem(type: menuManager.previousItemTab)
                   menuManager.selectTab(menuManager.previousItemTab)
                   menuManager.currentItemTab = menuManager.previousItemTab
                   menuManager.currentViewTab = menuManager.previousViewTab
               } else {
                   menuManager.pubShowTabsPopUp.toggle()
               }
           }
		}
		.padding(6)
		.background(Color.white)
		.padding(.bottom, 0)
		.availableAccessibility(AvailableAccessibilityItem.tabBar)
		.accessibility(addTraits: stopViewerModel.pubIsShowingStopViewer ? [.isModal] : [])
		// Use refreshCounter to force the entire HStack to re-render
		.id("tabbar-aoda-\(menuManager.refreshCounter)")
	}

	// MARK: - Menu Button

	/// Creates the menu button that opens the side menu.
	/// Only displayed if menu items are configured in feature settings.
	/// - Returns: A view representing the menu button with icon and title
	private func menuButton() -> some View {
		let menuTab = TabBarItem(type: .menu)

		return VStack {
			Image(menuTab.type.iconName)
				.resizable()
				.renderingMode(.template)
				.frame(width: 20, height: 20, alignment: .center)
				.aspectRatio(contentMode: .fit)

			TextLabel(menuTab.type.title.localized(), .semibold, .caption)
				.lineLimit(2)
				.fixedSize(horizontal: false, vertical: true)
		}
		.foregroundColor(Color.black)
		.padding(.vertical, 8)
		.frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78)
		.cornerRadius(10)
		.addTabAccessibility(tab: menuTab)
		.accessibilityAction {
			// Open side menu for accessibility action
			HomeViewModel.shared.pubOpenSideMenu = true
		}
		.onTapGesture {
			// Open side menu for regular tap
			HomeViewModel.shared.pubOpenSideMenu = true
		}
	}
    
    // MARK: - Menu Button AODA

    /// Creates the menu button that opens the side menu.
    /// Only displayed if menu items are configured in feature settings.
    /// - Returns: A view representing the menu button with icon and title
    private func menuButtonAODA() -> some View {
        let menuTab = TabBarItem(type: .menu)

        return HStack {
            Image(menuTab.type.iconName)
                .resizable()
                .renderingMode(.template)
                .frame(width: 40, height: 40, alignment: .center)
                .aspectRatio(contentMode: .fit)

            TextLabel(menuTab.type.title.localized(), .semibold, .caption)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .foregroundColor(Color.black)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78)
        .cornerRadius(10)
        .addTabAccessibility(tab: menuTab)
        .accessibilityAction {
            // Open side menu for accessibility action
            HomeViewModel.shared.pubOpenSideMenu = true
        }
        .onTapGesture {
            // Open side menu for regular tap
            HomeViewModel.shared.pubOpenSideMenu = true
        }
    }

	// MARK: - Post Tap Actions

	/// Handles additional actions after a tab is tapped.
	/// Currently redraws from/to markers after a delay when Plan Trip tab is selected.
	/// - Parameter type: The type of tab that was tapped
	private func handlePostTapAction(for type: TabBarItemType) {
		if type == .planTrip && menuManager.currentViewTab == .planTrip {
			// Redraw markers after a short delay to ensure map is ready
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				MapManager.shared.reDrawFromToMarkers()
			}
		}
	}
}

// MARK: - Tab Bar Button View

/// A separate view for each tab button to ensure proper SwiftUI state management
struct TabBarButtonView: View {
	@ObservedObject var menuManager = TabBarMenuManager.shared
	
	let tab: TabBarMenuItem
	let session: AppSession
	let mapFromToModel: MapFromToViewModel
	let onTap: () -> Void

	var body: some View {
		VStack {
			if let login = session.loginInfo, tab.type == .user {
				// User profile circle with initials
				ZStack {
					Circle()
						.fill(Color(hex: "#EEC659"))
						.frame(minWidth: 50, minHeight: 50, alignment: .center)
						.zIndex(1)

					TextLabel(login.shortName().uppercased())
						.foregroundColor(menuManager.isTabSelected(tab.type) ? Color.white : Color.black)
						.font(.headline)
						.zIndex(2)
				}
			} else {
				// Regular tab icon and title
				Image(tab.type.iconName)
					.resizable()
					.renderingMode(.template)
					.frame(width: 20, height: 20, alignment: .center)
					.aspectRatio(contentMode: .fit)

				TextLabel(tab.type.title.localized(), .semibold, .caption)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.foregroundColor(menuManager.isTabSelected(tab.type) ? tab.type.color : Color.black)
		.padding(.vertical, 8)
		.frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78)
		.cornerRadius(10)
		.accessibility(hidden: mapFromToModel.isPushedTo || mapFromToModel.isPushedFrom)
		.addTabAccessibility(tab: TabBarItem(type: tab.type))
		.accessibilityAction {
			onTap()
		}
		.onTapGesture {
			onTap()
		}
	}
}


// MARK: - Tab Bar Button View AODA

/// A separate view for each tab button to ensure proper SwiftUI state management
struct TabBarButtonViewAODA: View {
    @ObservedObject var menuManager = TabBarMenuManager.shared
    
    let tab: TabBarMenuItem
    let session: AppSession
    let mapFromToModel: MapFromToViewModel
    let showExpander: Bool
    let onTap: () -> Void

    var body: some View {
        
        
        HStack {
            if let login = session.loginInfo, tab.type == .user {
                VStack(spacing: 0){
                    HStack{
                        HStack{
                            // User profile circle with initials
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#EEC659"))
                                    .frame(minWidth: 50, minHeight: 50, alignment: .center)
                                    .zIndex(1)
                                
                                TextLabel(login.shortName().uppercased())
                                    .foregroundColor(menuManager.isTabSelected(tab.type) ? Color.white : Color.black)
                                    .font(.headline)
                                    .zIndex(2)
                            }
                            TextLabel("Profile".localized())
                                .foregroundColor(Color.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.headline)
                        }
                        Spacer()
                        if showExpander {
                            Image(menuManager.pubShowTabsPopUp || menuManager.pubShowProfilePopUp ? "ic_down_solid" : "ic_up_solid")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                    }.background(.white)
                }
            } else {
                HStack{
                    // Regular tab icon and title
                    Image(tab.type.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 40, height: 40, alignment: .center)
                        .aspectRatio(contentMode: .fit)
                    
                    TextLabel(tab.type.title.localized(), .semibold, .caption)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if showExpander{
                    Button(action: {
                        menuManager.pubShowTabsPopUp.toggle()
                        MapManager.shared.isMapSettings = false
                    }, label: {
                        Image(menuManager.pubShowTabsPopUp ? "ic_down_solid" : "ic_up_solid")
                            .resizable()
                            .frame(width: 50, height: 50)
                    })
                }
            }
        }
        .foregroundColor(menuManager.isTabSelected(tab.type) ? tab.type.color : Color.black)
        .frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78)
        .cornerRadius(10)
        .accessibility(hidden: mapFromToModel.isPushedTo || mapFromToModel.isPushedFrom)
        .addTabAccessibility(tab: TabBarItem(type: tab.type))
        .accessibilityAction {
            onTap()
        }
        .onTapGesture {
            onTap()
        }
    }
}
