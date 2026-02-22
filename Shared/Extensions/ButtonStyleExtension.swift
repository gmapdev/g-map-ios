//
//  ButtonStyleExtension.swift
//

import Foundation
import SwiftUI

extension View{
    /// Rounded border.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    func roundedBorder(_ corner: CGFloat = 5, _ padding: CGFloat = 5) -> some View{
        self
            .foregroundColor(.black)
            .padding(.all, padding)
            .padding(.horizontal, padding)
            .overlay(RoundedRectangle(cornerRadius: corner)
                        .stroke(Color.gray, lineWidth: 0.77))
    }
    
    /// Rounded border with color.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    func roundedBorderWithColor(_ corner: CGFloat = 5, _ padding: CGFloat = 5, _ color: Color = Color.black, _ lineWidth: CGFloat = 1) -> some View{
        self
            .foregroundColor(.black)
            .padding(.all, padding)
            .padding(.horizontal, padding)
            .overlay(RoundedRectangle(cornerRadius: corner)
                        .stroke(color, lineWidth: lineWidth))
    }
    
    /// Wide border
    /// - Returns: some View
    /// Wide border.
    func wideBorder() -> some View{
        self
            .foregroundColor(Color.black)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            .border(Color.gray.opacity(0.77), width: 0.77)
    }
}
