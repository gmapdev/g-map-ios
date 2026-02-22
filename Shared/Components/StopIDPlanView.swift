//
//  StopIDPlanView.swift
//

import SwiftUI

struct StopIDPlanView: View {
    var fromAction: (() -> Void)? = nil
    var toAction: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(alignment: .leading) {
            if AccessibilityManager.shared.pubIsLargeFontSize {
                VStack(alignment: .leading, spacing: 10){
                    TextLabel("Plan trip".localized(), .bold, .headline)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                    fromToView
                }
            } else {
                HStack{
                    TextLabel("Plan trip".localized(), .bold , .headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 45)
                        .accessibilityHidden(true)
                    fromToView
                }
            }
        }
    }
    
    /// From to view.
    /// - Parameters:
    ///   - some: Parameter description
    private var fromToView: some View {
        var view = FromToView()
        view.fromAction = fromAction
        view.toAction = toAction
        return view
    }
}

struct StopIDPlanView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        StopIDPlanView()
    }
}
