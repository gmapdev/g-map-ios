//
//  TripAlertsView.swift
//

import SwiftUI

struct LegAlertItemView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    let alertItem: OTPAlert?
    @State var isExpanded = false
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(alignment: .leading){
            if let alertItem = alertItem {
                Button(action: {
                    isExpanded.toggle()
                }, label: {
                    HStack {
                        TextLabel(alertItem.alertHeaderText?.replacingOccurrences(of: "\n", with: "") ?? "", .bold)
                            .lineLimit(nil)
                            .padding(10)
                            .foregroundStyle(isExpanded ? Color.white : Color.black)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        VStack{
                            Image(isExpanded ? "ic_up" : "ic_down")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(isExpanded ? Color.white : Color.main)
                                .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20, height: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20)
                            Spacer()
                        }
                        .padding(10)
                    }
                })
                .background(isExpanded ? Color.main : Color.white)
                if isExpanded {
                    VStack(alignment: .leading){
                        TextLabel(alertItem.alertDescriptionText ?? "")
                            .lineLimit(nil)
                        TextLabel("Effective as of %1".localized(tripPlanManager.timeIntervalToDate(timeInterval: alertItem.effectiveStartDate ?? 0)))
                            .lineLimit(nil)
                        if let alertUrl = alertItem.alertUrl, !alertUrl.isEmpty {
                            Button(action: {
                                if let url = URL(string: alertUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }, label: {
                                HStack {
                                    TextLabel("More".localized())
                                        .foregroundStyle(Color.main)
                                    Image("ic_link")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(Color.main)
                                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20, height: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20)
                                }
                            })
                        }
                    }.padding(10)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .roundedBorderWithColor(10,0,Color.main, 2)
        .padding(.vertical, 5)
    }
}

struct TripAlertsView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(spacing: 0){
            Spacer().frame(height: ScreenSize.safeTop())
                .background(Color.main)
            HStack {
                Spacer().frame(width: 10)
                Button(action: {
                    tripPlanManager.pubIsShowingTripAlerts = false
                }) {
                    Image("ic_leftarrow")
                        .renderingMode(.template)
                        .resizable()
                        .padding(5)
                        .foregroundColor(.white)
                }
                .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 35 : 25, height: AccessibilityManager.shared.pubIsLargeFontSize ? 40 : 30)
                .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
                .accessibilityAction {
                    tripPlanManager.pubIsShowingTripAlerts = false
                }
                Spacer()
                TextLabel("Alerts".localized(), .bold)
                    .foregroundStyle(Color.white)
                Spacer()
                Spacer()
                    .frame(width: 35)
            }
            .padding()
            .background(Color.main)
            ScrollView {
                VStack {
                    contentView
                    Spacer()
                }
            }
        }
        .background(Color.white)
    }
    
    /// Content view.
    /// - Parameters:
    ///   - some: Parameter description
    var contentView: some View {
        var routeName = ""
        var alertsCount = 0
        let routeAlerts: [OTPAlert?] = tripPlanManager.getAlertsArray(leg: tripPlanManager.pubCurrentTripLeg)
        if let leg = tripPlanManager.pubCurrentTripLeg, let route = leg.route, routeAlerts.count > 0{
            routeName = route.shortName ?? route.longName ?? ""
            alertsCount = routeAlerts.count
        }
        return VStack {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                topViewAODA(routeName: routeName, alertsCount: alertsCount)
            } else {
                topView(routeName: routeName, alertsCount: alertsCount)
            }
            ForEach(0..<routeAlerts.count, id: \.self) { index in
                LegAlertItemView(alertItem: routeAlerts[index])
            }
        }
        .padding()
    }
    
    /// Top view.
    /// - Parameters:
    ///   - routeName: Parameter description
    ///   - alertsCount: Parameter description
    /// - Returns: some View
    private func topView(routeName: String, alertsCount: Int) -> some View {
        return HStack {
            if !routeName.isEmpty {
                VStack(spacing: 0){
                    VStack(spacing: 0){
                        HStack{Spacer()}
                        Spacer()
                    }.padding(.horizontal, 5)
                        .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName))
                        .frame(height: 10).background(Color(hex: tripPlanManager.getRouteColor(leg: tripPlanManager.pubCurrentTripLeg))).opacity(1)
                    
                    HStack{
                        Spacer()
                        TextLabel(routeName).font(.subheadline).foregroundColor(Color.black)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.horizontal, 5)
                    .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), minHeight: 30)
                    .background(Color(hex: tripPlanManager.getRouteColor(leg: tripPlanManager.pubCurrentTripLeg)).opacity(0.5))
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            TextLabel("\(alertsCount) \(alertsCount > 1 ? "alerts".localized() : "alert".localized())")
                .foregroundStyle(Color.red)
            Spacer()
        }
    }
    
    /// Top view a o d a.
    /// - Parameters:
    ///   - routeName: Parameter description
    ///   - alertsCount: Parameter description
    /// - Returns: some View
    private func topViewAODA(routeName: String, alertsCount: Int) -> some View {
        return HStack {
            VStack(alignment: .leading){
                if !routeName.isEmpty {
                    VStack(spacing: 0){
                        VStack(spacing: 0){
                            HStack{Spacer()}
                            Spacer()
                        }.padding(.horizontal, 5)
                            .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName))
                            .frame(height: 10).background(Color(hex: tripPlanManager.getRouteColor(leg: tripPlanManager.pubCurrentTripLeg))).opacity(1)
                        
                        HStack{
                            Spacer()
                            TextLabel(routeName).font(.subheadline).foregroundColor(Color.black)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(.horizontal, 5)
                        .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), minHeight: 30)
                        .background(Color(hex: tripPlanManager.getRouteColor(leg: tripPlanManager.pubCurrentTripLeg)).opacity(0.5))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                TextLabel("\(alertsCount) \(alertsCount > 1 ? "alerts".localized() : "alert".localized())")
                    .foregroundStyle(Color.red)
            }
            Spacer()
        }
    }
}

#Preview {
    TripAlertsView()
}
