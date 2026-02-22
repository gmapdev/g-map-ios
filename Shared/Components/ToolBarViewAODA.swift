//
//  ToolBarViewAODA.swift
//

import SwiftUI

struct ToolBarViewAODA: View {
    var title: String
    var cancelAction: (() -> Void)? = nil
    var doneAction: (() -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        HStack {
            Button(action: {
                cancelAction?()
            }) {
                HStack(spacing:0){
                    Image("ic_leftarrow")
                        .renderingMode(.template)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 35, alignment: .center)
                        .foregroundColor(.toolbar_action)
                }
            }
            Spacer()
            
            TextLabel(title,.bold)
            Spacer().frame(width: 20)
            Spacer()
            
            Button(action: {
                doneAction?()
            }) {
                Image(systemName: "checkmark")
                    .resizable()
                    .padding(.horizontal, 5)
                    .foregroundColor(Color.black)
                    .frame(width: 45, height: 35)
            }
        }
        .padding(.horizontal, 15)
        
    }
}
