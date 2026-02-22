//
//  FromToView.swift
//

import SwiftUI

struct FromToView: View {
    var fromAction: (() -> Void)? = nil
    var toAction: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            VStack(alignment: .leading, spacing: 20) {
                fromButtonAODA.addAccessibility(text: AvailableAccessibilityItem.fromHereButton.rawValue.localized())
                toButtonAODA.addAccessibility(text: AvailableAccessibilityItem.toHereButton.rawValue.localized())
            }
        } else {
            HStack(alignment: .center, spacing: 20) {
                fromButton.addAccessibility(text: AvailableAccessibilityItem.fromHereButton.rawValue.localized())
                toButton.addAccessibility(text: AvailableAccessibilityItem.toHereButton.rawValue.localized())
            }
        }
    }
    
    /// From button.
    /// - Parameters:
    ///   - some: Parameter description
    private var fromButton: some View {
        Button(action: {
            fromAction?()
        }) {
            VStack(alignment: .center) {
                Image("ic_origin")
                    .resizable()
                    .frame(width: 23, height: 23, alignment: .center)
                TextLabel("From Here".localized(),.regular, .footnote)
                    .foregroundColor(Color.blue)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 35, alignment: .leading)
            }
        }
    }
    
    /// To button.
    /// - Parameters:
    ///   - some: Parameter description
    private var toButton: some View {
        Button(action: {
            toAction?()
        }) {
            VStack(alignment: .center) {
                Image("ic_destination")
                    .resizable()
                    .frame(width: 25, height: 25, alignment: .center)
                    .offset(x: -3)
                TextLabel("To Here".localized(), .regular, .footnote)
                    .foregroundColor(Color.blue)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 35, alignment: .leading)
            }
        }
    }
    
    /// From button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var fromButtonAODA: some View {
        Button(action: {
            fromAction?()
        }) {
            HStack {
                Image("ic_origin")
                    .resizable()
                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                TextLabel("From Here".localized(), .regular, .footnote)
                    .foregroundColor(Color.blue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    /// To button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var toButtonAODA: some View {
        Button(action: {
            toAction?()
        }) {
            HStack {
                Image("ic_destination")
                    .resizable()
                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)

                TextLabel("To Here".localized(),.regular, .footnote)
                    .foregroundColor(Color.blue)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
}

struct FromToView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        FromToView()
    }
}
