//
//  LaunchDisclaimerView.swift
//

import Foundation
import SwiftUI

struct LaunchDisclaimerView: View {

	@ObservedObject var session = AppSession.shared
    @ObservedObject var profileManager = ProfileManager.shared
	
	@Inject var userAccountProvider: UserAccountProvider
	
	var title = "Create a new account"
	var spacing: CGFloat = 20
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
        let checkBoxSize = AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize()/2 : 15
        
		return VStack(){
					Spacer().frame(height:spacing)
				
					VStack{
						HStack{
                            TextLabel(title.localized(), .bold, .title2).lineLimit(nil).foregroundColor(Color.black)
								.fixedSize(horizontal: false, vertical: true)
							Spacer()
						}
                        .padding(.bottom, 5)
						HStack{
                            TextLabel("You must agree to the terms of service to continue.".localized(), .bold, .subheadline).lineLimit(nil).foregroundColor(Color.black)
								.fixedSize(horizontal: false, vertical: true)
							Spacer()
						}

						HStack{
							Button(action: {
                                profileManager.pubHasConsentedToTerms.toggle()
                                AppSession.shared.loginInfo?.hasConsentedToTerms = profileManager.pubHasConsentedToTerms
							}, label: {
								ZStack{
									HStack{
										VStack{ Spacer() }
										Spacer()
									}
                                    .frame(width: (checkBoxSize + 5),height: (checkBoxSize + 5))
                                    .roundedBorder(5,0)
                                    .background(profileManager.pubHasConsentedToTerms ? Color.blue : Color.white)
                                    .cornerRadius(5)
                                    if profileManager.pubHasConsentedToTerms {
                                        Image(systemName: "checkmark").resizable().renderingMode(.template).aspectRatio(contentMode: .fit).foregroundColor(Color.white).frame(width: checkBoxSize, height: checkBoxSize)
                                            
                                    }
                                }.frame(width: (checkBoxSize * 2), height:(checkBoxSize * 2))
							})
							.accessibilityElement(children:.combine)
                            .addAccessibility(text: "Check box, double tap to %1 the option, I confirm that I am at least 18 years old, and I have read and consent to the Terms of Service for using the Trip Planner".localized((profileManager.pubHasConsentedToTerms ? "uncheck".localized() : "check".localized())))
							
                            self.hilightedText(str:  "I confirm that I am at least 18 years old, and I have read and consent to the Terms of Service for using the Trip Planner".localized(), searched: "Terms of Service".localized())
                                .fixedSize(horizontal: false, vertical: true)
                            .onTapGesture {
                                let termsString = FeatureConfig.shared.url_terms_of_service.replacingOccurrences(of: "{locale}", with: Helper.shared.getLanguageCode())
                                if let url = URL(string: termsString) {
									UIApplication.shared.open(url)
								}
							}
                            .addAccessibility(text: "double tap to read the terms of service".localized())
                            Spacer()
                        }
                        .frame(width: ScreenSize.width()-40)
						.padding(.bottom, 20)
						.padding(.top, 20)
						Spacer()
					}
        }
        .padding(.horizontal)
	}
    
    /// Hilighted text.
    /// - Parameters:
    ///   - str: Parameter description
    ///   - searched: Parameter description
    /// - Returns: Text
    func hilightedText(str: String, searched: String) -> Text {
        guard !str.isEmpty && !searched.isEmpty else { return Text(str).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)) }

        var result = Text("").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))

        var range = str.startIndex..<str.endIndex
        repeat {
            guard let found = str.range(of: searched, options: .caseInsensitive, range: range, locale: nil) else {
                result = result.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(.black) + Text(str[range]).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(.black)
                break
            }

            let prefix = str[range.lowerBound..<found.lowerBound]
            result = result.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(.black) + Text(prefix).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(.black) + Text(str[found]).font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.body.size)).foregroundColor(Color.main)

            range = found.upperBound..<str.endIndex
        } while (true)

        return result
    }
}

public struct LaunchDisclaimerView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    public static var previews: some View {
        LaunchDisclaimerView()
    }
}
