//
//  DropDownMenuButtonView.swift
//

import SwiftUI

struct MultiChoiceDropDownMenuView: View {
    enum SelectionMode {
        case single
        case multiple
    }
    
    @State private var showDropdownMenu: Bool = false
    @State private var selectedChoices: Set<String>
    @State private var singleSelection: String
    
    let title: String
    let choices: [String]
    let selectionMode: SelectionMode
    let allowSingleDeselection: Bool
    let setPickerValues: ([String]) -> Void
    let isDisabled: Bool // New parameter to handle disabled state

    /// Initializes a new instance.
    init(
        title: String,
        choices: [String],
        selectionMode: SelectionMode,
        allowSingleDeselection: Bool = false,
        preselected: [String] = [],
        isDisabled: Bool = false, // Default to false
        setPickerValues: @escaping ([String]) -> Void
    ) {
        self.title = title
        self.choices = choices
        self.selectionMode = selectionMode
        self.allowSingleDeselection = allowSingleDeselection
        self.setPickerValues = setPickerValues
        self.isDisabled = isDisabled

        if selectionMode == .single {
            /// Initializes a new instance.
            /// - Parameters:

            ///   - initialValue: preselected.first ?? ""

            /// - Parameters:
            _singleSelection = State(initialValue: preselected.first ?? "")
            /// Initializes a new instance.
            /// - Parameters:
            ///   - initialValue: []

            /// - Parameters:
            _selectedChoices = State(initialValue: [])
        } else {
            /// Initializes a new instance.
            /// - Parameters:

            ///   - initialValue: Set(preselected

            /// - Parameters:
            _selectedChoices = State(initialValue: Set(preselected))
            /// Initializes a new instance.
            /// - Parameters:
            ///   - initialValue: ""

            /// - Parameters:
            _singleSelection = State(initialValue: "")
        }
    }

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
                    if !isDisabled && !choices.isEmpty { showDropdownMenu.toggle() }
                }, label: {
                    Spacer()
                    Text(choices.isEmpty ? "No Options" : (selectionMode == .single
                        ? (singleSelection.isEmpty ? title : singleSelection)
                        : (selectedChoices.isEmpty ? "Select..." : selectedChoices.joined(separator: ", "))))
                        .font(Font.custom("HelveticaNeue", size: 16))
                        .foregroundColor(choices.isEmpty || isDisabled ? .gray : .black)
                    Spacer()
                    Image("expand_down_icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .opacity(isDisabled ? 0.5 : 1) // Lower opacity when disabled
                })
                .disabled(isDisabled || choices.isEmpty)
            }
            .padding(.all, 5)
            .frame(minHeight: 40, alignment: .center)
            .cornerRadius(10.0)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isDisabled || choices.isEmpty ? Color.gray.opacity(0.5) : Color.gray, lineWidth: 0.77)
            )
            .opacity(isDisabled || choices.isEmpty ? 0.5 : 1)
            .sheet(isPresented: $showDropdownMenu) {
                if selectionMode == .single {
                    SingleChoiceListView(
                        choices: choices,
                        selectedChoice: $singleSelection,
                        allowDeselection: allowSingleDeselection,
                        onDone: {
                            setPickerValues([singleSelection])
                            showDropdownMenu.toggle()
                        }
                    )
                } else {
                    MultiChoiceListView(
                        choices: choices,
                        selectedChoices: $selectedChoices,
                        onDone: {
                            setPickerValues(Array(selectedChoices))
                            showDropdownMenu.toggle()
                        }
                    )
                }
            }
        }
    }
}


struct SingleChoiceListView: View {
    let choices: [String]
    @Binding var selectedChoice: String
    let allowDeselection: Bool  // New parameter
    let onDone: () -> Void

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        NavigationView {
            List(choices, id: \.self) { choice in
                HStack {
                    Text(choice)
                    Spacer()
                    if selectedChoice == choice {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedChoice == choice {
                        if allowDeselection {
                            selectedChoice = "" // Allow deselection
                        }
                    } else {
                        selectedChoice = choice
                    }
                }
            }
            .navigationTitle("Select Option")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
        }
    }
}

struct MultiChoiceListView: View {
    let choices: [String]
    @Binding var selectedChoices: Set<String>
    let onDone: () -> Void

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        NavigationView {
            List(choices, id: \.self) { choice in
                HStack {
                    Text(choice)
                    Spacer()
                    if selectedChoices.contains(choice) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedChoices.contains(choice) {
                        selectedChoices.remove(choice)
                    } else {
                        selectedChoices.insert(choice)
                    }
                }
            }
            .navigationTitle("Select Options")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone()
                    }
                }
            }
        }
    }
}

// Example Usage
struct ContentView: View {
    @State private var selectedItems: [String] = ["Option 2"] // Preselected items

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack {
            MultiChoiceDropDownMenuView(
                title: "Select Option",
                choices: ["Option 1", "Option 2", "Option 3"],
                selectionMode: .single,
                preselected: selectedItems, // Pass preselected items here
                setPickerValues: { selected in
                    selectedItems = selected
                }
            )
            
            MultiChoiceDropDownMenuView(
                title: "Select Options",
                choices: ["Option A", "Option B", "Option C"],
                selectionMode: .multiple,
                preselected: selectedItems, // Pass preselected items here
                setPickerValues: { selected in
                    selectedItems = selected
                }
            )
        }
    }
}

