//
//  ToolBarView.swift
//

import SwiftUI

struct ToolBarView: View {
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
                        .frame(width: 20, height: 20, alignment: .center)
                        .foregroundColor(.toolbar_action)
                    
                    TextLabel("Back".localized())
                        .font(.body)
                        .foregroundColor(.toolbar_action)
                }
            }
            Spacer()
            TextLabel(title, .bold)
            Spacer().frame(width: 20)
            Spacer()
            
            Button(action: {
                doneAction?()
            }) {
                TextLabel("Save".localized())
                    .font(.body)
                    .foregroundColor(.toolbar_action)
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 15)
        
    }
}

