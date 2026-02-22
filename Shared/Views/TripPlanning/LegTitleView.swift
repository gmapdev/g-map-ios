//
//  LegTitleView.swift
//

import SwiftUI

struct LegTitleView: View {
    let time: String
    let icon: String
    let name: String
    let delay: Double
    let isRealtime: Bool
    let interLineWithPreviousLeg: Bool
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if AccessibilityManager.shared.pubIsLargeFontSize {
            contentViewAODA
        } else {
            contentView
        }
    }
    
    /// Content view.
    /// - Parameters:
    ///   - some: Parameter description
    var contentView: some View {
        VStack{
            HStack {
                (Text(interLineWithPreviousLeg ? "Stay on Board at ".localized() : "") + Text(name).bold()
                )
                .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.headline.size))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)
                .lineLimit(nil)
                Spacer()
                if isRealtime{
                    if delay > 0 && delay >= 60{
                        Text(time)
                            .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size))
                            .foregroundColor(.gray_subtitle_color)
                            .strikethrough(color: Color.red)
                    }else if delay < 0 && delay <= -60 {
                        Text(time)
                            .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size))
                            .foregroundColor(.gray_subtitle_color)
                            .strikethrough(color: Color.green)
                    }else {
                        TextLabel(time, .regular, .footnote)
                            .foregroundColor(Color.init(hex: "#3F883F"))
                    }
                } else {
                    TextLabel(time, .regular, .footnote)
                        .foregroundColor(.gray_subtitle_color)
                }
            }
            if name.contains("E-Scooter") {
                HStack {
                    TextLabel("Pick up E-Scooter".localized(), .regular, .footnote)
                        .foregroundColor(.gray_subtitle_color)
                    Spacer()
                }
            }
            if name.contains("Shared bike") {
                HStack {
                    TextLabel("Pick up shared bike".localized(), .regular, .footnote)
                        .foregroundColor(.gray_subtitle_color)
                    Spacer()
                }
            }
            
            HStack{
                if isRealtime{
                    if delay > 0 && delay >= 60 {
                        TextLabel(String(format: "%.0f", abs(floor(getMinutes(seconds: delay)))) + (abs(floor(getMinutes(seconds: delay))) > 1 ? " mins late".localized() : " min late".localized()), .semibold, .footnote)
                            .foregroundColor(.red)
                        Spacer()
                        TextLabel(getDelayedTime(currentTime: time, delay: delay), .semibold, .footnote)
                            .foregroundColor(.red)
                    }else if delay < 0 && delay <= -60  {
                        TextLabel(String(format: "%.0f", abs(floor(getMinutes(seconds: delay)))) + (abs(floor(getMinutes(seconds: delay))) > 1 ? " mins early".localized() : " min early".localized()), .semibold, .footnote)
                            .foregroundColor(.green)
                        Spacer()
                        TextLabel(getDelayedTime(currentTime: time, delay: delay), .semibold, .footnote)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.leading, 2)
    }
    
    /// Content view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var contentViewAODA: some View {
        VStack{
            VStack {
                HStack {
                    TextLabel(name, .bold, .body)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }
                HStack {
                        if isRealtime{
                            if delay > 0 && delay >= 60{
                                Text(time)
                                    .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size))
                                    .foregroundColor(.gray_subtitle_color)
                                    .strikethrough(color: Color.red)
                            }else if delay < 0 && delay <= -60 {
                                Text(time)
                                    .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size))
                                    .foregroundColor(.gray_subtitle_color)
                                    .strikethrough(color: Color.green)
                            } else {
                                TextLabel(time)
                                    .font(.footnote)
                                    .foregroundColor(Color.init(hex: "#3F883F"))
                            }
                        } else {
                            TextLabel(time)
                                .font(.footnote)
                                .foregroundColor(.gray_subtitle_color)
                        }
                    Spacer()
                }
            }
            HStack {
                VStack(alignment: .leading){
                    if isRealtime{
                        if delay > 0 && delay >= 60 {
                            TextLabel(getDelayedTime(currentTime: time, delay: delay), .semibold, .footnote)
                                .foregroundColor(.red)
                            TextLabel(String(format: "%.0f", abs(floor(getMinutes(seconds: delay)))) + (abs(floor(getMinutes(seconds: delay))) > 1 ? " mins late" : " min late"), .semibold, .footnote)
                                .foregroundColor(.red)
                        }else if delay < 0 && delay <= -60  {
                            TextLabel(getDelayedTime(currentTime: time, delay: delay), .semibold, .footnote)
                                .foregroundColor(.green)
                            TextLabel(String(format: "%.0f", abs(floor(getMinutes(seconds: delay)))) + (abs(floor(getMinutes(seconds: delay))) > 1 ? " mins early" : " min early"), .semibold, .footnote)
                                .foregroundColor(.green)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(.leading, 10)
    }
    
    /// Get minutes.
    /// - Parameters:
    ///   - seconds: Parameter description
    /// - Returns: Double
    func getMinutes(seconds: Double) -> Double{
        let minute = seconds / 60
        return minute
    }
    
    /// Get delayed time.
    /// - Parameters:
    ///   - currentTime: Parameter description
    ///   - delay: Parameter description
    /// - Returns: String
    func getDelayedTime(currentTime: String, delay: Double) -> String{
        let formatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        formatter.locale = Locale(identifier: language.languageCode())
        formatter.timeZone = EnvironmentManager.shared.currentTimezone
        formatter.dateFormat = "h:mm a"
        let time = formatter.date(from: currentTime)
        guard let newTime = time?.addingTimeInterval(delay) else { return "" }
        let formattedTime = formatter.string(from: newTime)
        return formattedTime
    }
}
