//
//  TripSettingDropDownMenuView.swift
//

import SwiftUI

struct TripSettingDropDownMenuView: View {
    @State private var showDropdownMenu: Bool = false
    @State private var buttonTitle: String
    let choices: [String]
    let setPickerValue: (String) -> Void

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            Button(action: {
                showDropdownMenu.toggle()
            }) {
                HStack {
                    TextLabel(buttonTitle.localized(), .semibold, .subheadline)
                        .foregroundColor(Color.black)
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        Spacer()
                    }
                    Image(systemName: "arrowtriangle.down.fill")
                        .renderingMode(.template)
                        .resizable()
                        .padding(.horizontal, 5)
                        .frame(
                            width: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20,
                            height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 10
                        )
                        .foregroundColor(Color.java_main)
                }
                .padding(10)
                .roundedBorderWithColor(10, 0, Color.java_main, 1)
            }
            .actionSheet(isPresented: $showDropdownMenu) {
                ActionSheet(
                    title: Text("Select an Option"),
                    buttons: generateActionSheetButtons()
                )
            }
        }
    }

    /// Generate action sheet buttons
    /// - Returns: [ActionSheet.Button]
    /// Generate action sheet buttons.
    private func generateActionSheetButtons() -> [ActionSheet.Button] {
        var buttons = choices.map { item in
            ActionSheet.Button.default(Text(item).font(.subheadline)) {
                buttonTitle = item
                setPickerValue(item)
            }
        }
        buttons.append(.cancel()) // Add a cancel button at the end
        return buttons
    }

    /// Sets.
    /// - Returns: void

    /// - Returns: void

    /// Title:  string, choices: [ string], func set value: @escaping ( string) ->  void
    /// Initializes a new instance.
    /// - Parameters:
    ///   - title: String
    ///   - choices: [String]
    ///   - funcSetValue: @escaping (String
    /// - Returns: Void)
    init(title: String, choices: [String], funcSetValue: @escaping (String) -> Void) {
        /// Initializes a new instance.
        /// - Parameters:
        ///   - initialValue: title

        /// - Parameters:
        _buttonTitle = State(initialValue: title)
        self.choices = choices
        self.setPickerValue = funcSetValue
    }
}
