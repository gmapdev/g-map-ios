//
//  LoadingView.swift
//

import SwiftUI

struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    /// Make u i view.
    /// - Parameters:
    ///   - context: Parameter description
    /// - Returns: UIActivityIndicatorView
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    /// Update u i view.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - context: Parameter description
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool
    
    var content: () -> Content

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {

        ZStack(alignment: .center) {
            self.content()
                .disabled(self.isShowing)
			
			if self.isShowing {
				VStack{
					HStack{
						Spacer()
					}
					Spacer()
				}
				.edgesIgnoringSafeArea(.all)
				.background(Color.black.opacity(0.6))
				.zIndex(9998)
				
				VStack {
                    TextLabel("Loading...".localized()).foregroundColor(Color.black).font(.subheadline)
					ActivityIndicator(isAnimating: .constant(true), style: .large)
				}
                .padding(.all)
                .frame(minWidth: 100, minHeight: 100)
				.background(Color.white)
				.foregroundColor(Color.primary)
				.cornerRadius(10)
				.opacity(self.isShowing ? 1 : 0)
				.shadow(radius: 5)
				.zIndex(9999)
			}
        }.zIndex(9999)
        
    }
}
