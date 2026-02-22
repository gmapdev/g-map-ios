//
//  ClickableText.swift
//

import SwiftUI

struct ClickableText: View {
	
	let words: [String]
	let underlineWords : [String]
	let text: String
	let highlightColor: Color?
	let defaultColor: Color?
	let wordsResult : [NSTextCheckingResult]
    let realTimeDict: [String: Bool]
	let onTap: ((String?)->Void)?
	
    /// Initializes a new instance.
    /// - Parameters:
    ///   - text: String
    ///   - words: [String]
    ///   - underlineWords: [String]
    ///   - highlightColor: Color? = nil
    ///   - defaultColor: Color? = nil
    ///   - realTimeDict: [String: Bool]
    ///   - onTap: ((String?
    /// - Returns: Void)?)
    init (_ text: String, _ words: [String], _ underlineWords: [String], _ highlightColor: Color? = nil, _ defaultColor: Color? = nil, _ realTimeDict: [String: Bool], onTap: ((String?)->Void)?) {
		self.text = text
		self.words = words
		self.onTap = onTap
		self.underlineWords = underlineWords
		self.highlightColor = highlightColor
		self.defaultColor = defaultColor
        self.realTimeDict = realTimeDict
		let nsText = text as NSString

		let wholeString = NSRange(location: 0, length: nsText.length)
		do {
			var pattern = ""
			if words.count > 0 {
				pattern += "("
				var patternItems = ""
				for word in words {
					if patternItems.count > 0 {
						patternItems += "|"
					}
					patternItems += word;
				}
				pattern += patternItems
				pattern += ")"
			}
			let detector = try NSRegularExpression(pattern: pattern)
			wordsResult = detector.matches(in: text, range: wholeString)
		}catch(let error){
			wordsResult = []
		}
	}
	
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		if words.count == 0 {
			TextLabel(text).font(.body).onTapGesture {
				onTap?(text)
			}
		}else {
            ColoredText(text: text, words: wordsResult, underlineWords: underlineWords, highlightColor: highlightColor, defaultColor: defaultColor, realTimeDict: realTimeDict)
                .font(.body) // enforce here because the link tapping won't be right if it's different
                .overlay(TextTapOverlay(text: text, words: wordsResult, onTap: { word in
                    onTap?(word)
                }))
		}
	}
}

struct ColoredText: View {
	enum Component {
		case text(String)
		case highlightText(String, String)
	}

	let text: String
	let highlightColor: Color
	let underlineWords: [String]
	let defaultColor: Color
	let components: [Component]
    let realTimeDict: [String: Bool]

    /// Text:  string, words: [ n s text checking result], underline words: [ string], highlight color:  color?, default color:  color?, real time dict: [ string:  bool]
    /// Initializes a new instance.
    /// - Parameters:
    ///   - text: String
    ///   - words: [NSTextCheckingResult]
    ///   - underlineWords: [String]
    ///   - highlightColor: Color?
    ///   - defaultColor: Color?
    ///   - realTimeDict: [String: Bool]
    init(text: String, words: [NSTextCheckingResult], underlineWords: [String], highlightColor: Color?, defaultColor: Color?, realTimeDict: [String: Bool]) {
		self.text = text
		self.underlineWords = underlineWords
		self.highlightColor = highlightColor ?? .accentColor
		self.defaultColor = defaultColor ?? Color.black
        self.realTimeDict = realTimeDict
		let nsText = text as NSString

		var components: [Component] = []
		var index = 0
		for result in words {
			if result.range.location > index {
				components.append(.text(nsText.substring(with: NSRange(location: index, length: result.range.location - index))))
			}
			components.append(.highlightText(nsText.substring(with: result.range), nsText.substring(with: result.range)))
			index = result.range.location + result.range.length
		}

		if index < nsText.length {
			components.append(.text(nsText.substring(from: index)))
		}

		self.components = components
	}

 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		components.map { component in
			switch component {
			case .text(let text):
				return Text(verbatim: text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(self.defaultColor)
			case .highlightText(let text, _):
				if underlineWords.contains(text) {
                    return  highLightTextWithUnderline(text: text)
                                                
				}else{
                    return  highLightText(text: text)
				}
			}
		}.reduce(Text("").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)), +)
	}
    
    /// High light text with underline.
    /// - Parameters:
    ///   - text: Parameter description
    /// - Returns: Text
    func highLightTextWithUnderline(text: String) -> Text{
        if let isRealTime = realTimeDict[text], isRealTime{
            return Text(Image(AccessibilityManager.shared.pubIsLargeFontSize ? "ic_wifi_indicator_big" : "ic_wifi_indicator")).baselineOffset(3.0).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)) + Text(verbatim: text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(self.highlightColor).underline()
        }
        return Text(verbatim: text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(self.highlightColor).underline()
    }
    
    /// High light text.
    /// - Parameters:
    ///   - text: Parameter description
    /// - Returns: Text
    func highLightText(text: String) -> Text{
        if let isRealTime = realTimeDict[text], isRealTime{
            return Text(Image(AccessibilityManager.shared.pubIsLargeFontSize ? "ic_wifi_indicator_big" : "ic_wifi_indicator")).baselineOffset(3.0).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)) + Text(verbatim: text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(self.highlightColor)
        }
        return Text(verbatim: text).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)).foregroundColor(self.highlightColor)
    }
}

private struct TextTapOverlay: UIViewRepresentable {
	let text: String
	let words: [NSTextCheckingResult]
	let onTap: ((String?)->Void)?
	
 /// Make u i view.
 /// - Parameters:
 ///   - context: Parameter description
 /// - Returns: TextTapOverlayView
	func makeUIView(context: Context) -> TextTapOverlayView {
		let view = TextTapOverlayView()
		view.textContainer = context.coordinator.textContainer
		
		view.isUserInteractionEnabled = true
		let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTapLabel(_:)))
		tapGesture.delegate = context.coordinator
		view.addGestureRecognizer(tapGesture)
		
		return view
	}
	
 /// Update u i view.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - context: Parameter description
	func updateUIView(_ uiView: TextTapOverlayView, context: Context) {
		let attributedString = NSAttributedString(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
		context.coordinator.textStorage = NSTextStorage(attributedString: attributedString)
		context.coordinator.textStorage!.addLayoutManager(context.coordinator.layoutManager)
	}
	
 /// Make coordinator.
 /// - Returns: Coordinator
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, UIGestureRecognizerDelegate {
		let overlay: TextTapOverlay

		let layoutManager = NSLayoutManager()
		let textContainer = NSTextContainer(size: .zero)
		var textStorage: NSTextStorage?
		
  /// _ overlay:  text tap overlay
  /// Initializes a new instance.
  /// - Parameters:
  ///   - overlay: TextTapOverlay
		init(_ overlay: TextTapOverlay) {
			self.overlay = overlay
			
			textContainer.lineFragmentPadding = 0
			textContainer.lineBreakMode = .byWordWrapping
			textContainer.maximumNumberOfLines = 0
			layoutManager.addTextContainer(textContainer)
		}
		
  /// Gesture recognizer.
  /// - Parameters:
  ///   - _: Parameter description
  ///   - shouldReceive: Parameter description
  /// - Returns: Bool
		func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
			let location = touch.location(in: gestureRecognizer.view!)
			let result = words(at: location)
			return result != nil
		}
		
  /// Did tap label.
  /// - Parameters:
  ///   - _: Parameter description
  /// Handles when did tap label.
		@objc func didTapLabel(_ gesture: UITapGestureRecognizer) {
			let location = gesture.location(in: gesture.view!)
			guard let result = words(at: location) else {
				return
			}
			let nsText = overlay.text as NSString
			let touchedText = nsText.substring(with: result.range)
			overlay.onTap?(touchedText)
		}
		
  /// Words.
  /// - Parameters:
  ///   - at: Parameter description
  /// - Returns: NSTextCheckingResult?
		private func words(at point: CGPoint) -> NSTextCheckingResult? {
			guard !overlay.words.isEmpty else {
				return nil
			}

			let indexOfCharacter = layoutManager.characterIndex(
				for: point,
				in: textContainer,
				fractionOfDistanceBetweenInsertionPoints: nil
			)

			return overlay.words.first { $0.range.contains(indexOfCharacter) }
		}
	}
}

private class TextTapOverlayView: UIView {
	var textContainer: NSTextContainer!
	
 /// Layout subviews
 /// Layout subviews.
	override func layoutSubviews() {
		super.layoutSubviews()

		var newSize = bounds.size
		newSize.height += 20
		textContainer.size = newSize
	}
}
