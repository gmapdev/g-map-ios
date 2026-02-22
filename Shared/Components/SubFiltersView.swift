//
//  SubFiltersView.swift
//

import SwiftUI

struct SubFiltersView: View {
    var subitem: SearchMode
    var isSelected = false
    var index: Int = 0
    var action: ((Int) -> Void)?
    var width: CGFloat 
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        button
    }
    
    /// Button.
    /// - Parameters:
    ///   - some: Parameter description
    private var button: some View {
        Button(action:{
            self.action?(index)
        }) {
            VStack(alignment: .center, spacing: 0) {
                Image(subitem.mode_image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 5).padding(.top, 5)
                
                TextLabel(subitem.label.localized(),.bold, .caption)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color.black)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 3)
                    .frame(height: 35)
            }
            .frame(width: width, height: 85)
            .padding(10)
            .background(isSelected ? Color.java_main : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .roundedBorderWithColor(10, 0, Color.java_main, 2)
        }
        .frame(height: 90)

    }
}

struct SubFiltersViewAODA: View {
    var subitem: SearchMode
    var isSelected = false
    var index: Int = 0
    var action: ((Int) -> Void)?
    var width: CGFloat = 70
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        button
    }
    
    /// Button.
    /// - Parameters:
    ///   - some: Parameter description
    private var button: some View {
        HStack(spacing: 0) {
            Image(subitem.mode_image)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(Color.black)
                .padding(.horizontal, 5).padding(.top, 5)
            Spacer().frame(width: 10)
            TextLabel(subitem.label.localized(), .bold)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(.leading, 3)
                .foregroundColor(Color.black)
            Spacer()
        }
        .padding(10)
        .roundedBorderWithColor(10,0,Color.java_main,2)
        .background(isSelected ? Color.java_main : Color.white)
        .cornerRadius(10)
        .onTapGesture {
            action?(index)
        }
        .addAccessibility(text: "%1,".localized(subitem.label.localized()) + (isSelected ? "mode on, Double tap to activate".localized() : "mode off, Double tap to activate".localized() ))
    }
}

