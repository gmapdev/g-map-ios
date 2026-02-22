//
//  PickerView.swift
//

import SwiftUI

struct PickerView<T: View>: ViewModifier {
    let contentView: T
    let isShown: Bool

    /// Is shown:  bool, @ view builder content: () ->  t
    /// Initializes a new instance.
    /// - Parameters:
    ///   - isShown: Bool
    ///   - content: (
    /// - Returns: T)
    init(isShown: Bool, @ViewBuilder content: () -> T) {
        self.isShown = isShown
        contentView = content()
    }

    /// Body.
    /// - Parameters:
    ///   - content: Parameter description
    /// - Returns: some View
    func body(content: Content) -> some View {
        content
            .overlay(self.content)
    }
    
    /// Content.
    /// - Parameters:
    ///   - some: Parameter description
    private var content: some View {
        GeometryReader { geometry in
            if isShown {
                contentView
                    .transition(.move(edge: .bottom))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            }
        }
    }
}




