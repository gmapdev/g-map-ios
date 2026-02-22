//
//  CustomAlertView.swift
//

import SwiftUI

struct CustomAlertView: View {
    var titleMessage: String
    var primaryButton: String
    var secondaryButton: String
    var primaryAction: (() -> Void)? = nil
    var secondaryAction: (() -> Void)? = nil
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            VStack {
                Spacer().frame(height: 30)
                TextLabel(titleMessage.localized(), .bold)
                    .padding()
                Button(action: {
                    primaryAction?()
                }, label: {
                    HStack {
                        Spacer()
                        TextLabel(primaryButton.localized(), .bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(minHeight: 60)
                            .foregroundStyle(Color.black)
                        Spacer()
                    }
                    .padding(AccessibilityManager.shared.pubIsLargeFontSize ? 10 : 0)
                    .background(Color.yellow_main)
                })
                .padding(.horizontal)
                Button(action: {
                    secondaryAction?()
                }, label: {
                    HStack {
                        Spacer()
                        TextLabel(secondaryButton.localized(), .bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(minHeight: 60)
                            .foregroundStyle(Color.black)
                        Spacer()
                    }
                    .padding(AccessibilityManager.shared.pubIsLargeFontSize ? 10 : 0)
                    .background(Color.white)
                    .border(Color.yellow_main, width: 2)
                })
                .padding(.horizontal)
                .padding(.vertical, 10)
                Spacer().frame(height: 30)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
            .padding()
        }
    }
}

struct CustomMessageView: View {
    var titleMessage: String
    var boldMessage: String
    var primaryAction: (() -> Void)? = nil
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .onTapGesture {
                primaryAction?()
            }
            VStack {
                BoldSubstringText(title: titleMessage.localized(), boldText: boldMessage)
                    .padding(30)
                Button(action: {
                    primaryAction?()
                }, label: {
                    HStack {
                        Spacer()
                        TextLabel("OK".localized(), .bold)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .frame(minHeight: 60)
                            .foregroundStyle(Color.black)
                        Spacer()
                    }
                    .padding(AccessibilityManager.shared.pubIsLargeFontSize ? 10 : 0)
                    .background(Color.yellow_main)
                })
                .padding(.bottom, 30)
                .padding(.horizontal, 30)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 5)
            .padding(30)
        }
    }
}

struct BoldSubstringText: View {
    let title: String
    let boldText: String
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        var textComponents: [Text] = []
        let components = title.components(separatedBy: boldText)
        for i in 0..<components.count {
            textComponents.append(Text(components[i]).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).fontWeight(.regular))
            if i < components.count - 1 {
                textComponents.append(Text(boldText).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).fontWeight(.bold))
            }
        }
        return textComponents.reduce(Text("").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)), +).multilineTextAlignment(.center)
    }
}

#Preview {
    CustomMessageView(titleMessage: "This is the Example message", boldMessage: "Example")
}
