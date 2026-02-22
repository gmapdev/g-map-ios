//
//  HomeMenuView.swift
//

import SwiftUI

struct MenuItem: Identifiable {
    var id = UUID().uuidString
    let text: String
    let image: String
    var action: () -> Void
}

struct HomeMenuView: View {
    var items: [MenuItem]
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ScrollView {
            VStack {
                ForEach(items) { item in
                    itemView(item)
                }
            }.padding()
        }.background(Color.white)
    }
    
    /// Item view.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    private func itemView(_ item: MenuItem) -> some View {
        Button(action: item.action) {
            HStack {
				if item.image.count > 0 {
					Image(item.image)
						.resizable()
						.frame(width: 20, height: 20)
				}
                TextLabel(item.text).foregroundColor(Color.black)
                Spacer()
            }
        }.background(Color.white)
    }
}

struct HomeMenuView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        HomeMenuView(items: [])
    }
}
