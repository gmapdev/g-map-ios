//
//  FilterView.swift
//

import SwiftUI

struct FilterView: View {
    var item: SearchMode
    var isSelected = false
    var action: () -> Void
    var width: CGFloat = 50
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack{
            Button(action:
                    self.action
            ) {
                ZStack {
					Image("\(item.mode_image)")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(self.isSelected ? .white : .black)
                            .frame(width: 30, height: 30, alignment: .center)
                        
                       
                }
            }.frame(width: width, height: 55).background(self.isSelected ? Color.main : Color.white)
                .cornerRadius(5)
            
			if BrandConfig.shared.enable_mode_filter {
                TextLabel(item.label.capitalized, .bold, .caption)
                    .foregroundColor(.black)
            }
        }
    }
 
}
