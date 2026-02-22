//
//  ToastView.swift
//

import SwiftUI

struct ToastView: View {
    @ObservedObject var toast = ToastManager.shared

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            HStack{
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                TextLabel(toast.message).font(.subheadline)
                    .foregroundColor(Color.black)
                    .padding(15)
                    .background(Color.gray.opacity(0.75))
                    .cornerRadius(10)
                    .frame(minWidth:100,maxWidth: 300, minHeight:45)
                Spacer()
            }
            .transition(.slide)
            Spacer().frame(height:30)
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        ToastView()
    }
}
