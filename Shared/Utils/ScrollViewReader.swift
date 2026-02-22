//
//  ScrollViewReader.swift
//

import Foundation
import SwiftUI

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    /// Reduce.
    /// - Parameters:
    ///   - value: Parameter description
    ///   - nextValue: Parameter description
    /// - Returns: Value)
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}


struct ChildSizeReader<Content: View>: View {
    @Binding var size: CGSize
    
    let content: () -> Content
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack {
            content().background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: SizePreferenceKey.self,
                        value: proxy.size
                    )
                }
            )
        }
        .onPreferenceChange(SizePreferenceKey.self) { preferences in
            self.size = preferences
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero
    
    /// Reduce.
    /// - Parameters:
    ///   - value: Parameter description
    ///   - nextValue: Parameter description
    /// - Returns: Value)
    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}
