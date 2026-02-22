//
//  ViewerToolBar.swift
//

import SwiftUI

struct ViewerToolBar: View {
	@ObservedObject var stopManager = StopsManager.shared
    @ObservedObject var stopViewerViewModel = StopViewerViewModel.shared
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    let text: String
    let stop: Stop?
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let agencyImages = stopViewerViewModel.pubAgencyIcons
        return VStack {
                HStack {
                    if !agencyImages.isEmpty {
                        ForEach(0..<agencyImages.count, id: \.self) { index in
                            if let agencyImage = agencyImages[index] {
                                Image(uiImage: agencyImage)
                                    .resizable().aspectRatio(contentMode: .fit)
                                    .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 50, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 50, alignment: .center)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading) {
                    TextLabel(text, .semibold , .title2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack{
                        TextLabel("Stop ID:".localized())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        TextLabel(stop?.displayIdentifier() ?? "N/A")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
        }
        .frame(
            minWidth: 0,
            /// Initializes a new instance.
            maxWidth: .infinity,
            minHeight: 40
         )
        .background(Color.white)
        .padding(.horizontal, 16)
        .padding(.top)
    }
}
