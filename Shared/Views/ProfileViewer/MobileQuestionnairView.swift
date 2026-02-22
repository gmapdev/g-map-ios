//
//  MobileQuestionnairView.swift
//

import Foundation
import SwiftUI

struct OTPUserMobilityProfile: Codable, Equatable{
    var isMobilityLimited: Bool?
    var mobilityDevices: [String]
    var visionLimitation: String
    var mobilityMode : String?
}

struct CheckListItem: Codable, Hashable{
    var value: String
    var label: String
    var isSelected: Bool
}

class MobileQuestionnairViewModel: ObservableObject {
    
	@Published var pubOpenMobileQuestionnairs = false
    @Published var selectedMobilityProfile : OTPUserMobilityProfile?
    @Published var pubQuestionOneOptions = [CheckListItem]()
    @Published var pubShowCloseAlert: Bool = false
    
    var serverMobilityProfile : OTPUserMobilityProfile?
 /// Shared.
 /// - Parameters:
 ///   - MobileQuestionnairViewModel: Parameter description
	public static var shared: MobileQuestionnairViewModel = {
		let mgr = MobileQuestionnairViewModel()
		return mgr
	}()
    
    /// Is mobility profile updated
    /// - Returns: Bool
    /// Checks if mobility profile updated.
    func isMobilityProfileUpdated() -> Bool{
        if let localMobilityInfo = selectedMobilityProfile, let serverMobilityInfo = serverMobilityProfile{
            return localMobilityInfo != serverMobilityInfo
        }
        return false
    }
    
    /// Update selection.
    /// - Parameters:
    ///   - ans1: Parameter description
    ///   - ans2: Parameter description
    ///   - ans3: Parameter description
    func updateSelection(ans1: [String], ans2 : Bool, ans3: String){
        var tempAns3 = ans3 == "No vision limitations" ? "NONE" : ans3
        self.selectedMobilityProfile = OTPUserMobilityProfile(isMobilityLimited: ans2, mobilityDevices: ans1.map({$0.lowercased()}), visionLimitation: tempAns3.lowercased())
    }
    
    /// Is check mobility devices
    /// - Returns: Bool
    /// Checks if check mobility devices.
    func isCheckMobilityDevices() -> Bool {
        guard let mobilityProfile = self.selectedMobilityProfile else {
            return false
        }
        return !mobilityProfile.mobilityDevices.contains("no assistive device")
    }
    
    /// Has mobility or vision needs
    /// - Returns: Bool
    /// Checks if has mobility or vision needs.
    func hasMobilityOrVisionNeeds() -> Bool {
        guard let mobilityProfile = self.selectedMobilityProfile else {
            return false
        }
        
        // Normalize strings to lowercase for comparison
        let devices = mobilityProfile.mobilityDevices.map { $0.lowercased() }
        let vision = mobilityProfile.visionLimitation.lowercased()
        
        // Check for mobility needs: needs exist if array is not empty AND doesn't contain "no assistive device"
        let hasMobilityNeeds = !devices.isEmpty && !devices.contains("no assistive device")
        
        // Vision needs exist unless vision is explicitly "no vision limitations" or "none"
        let hasVisionNeeds = !(vision == "no vision limitations" || vision == "none")
        
        // Return true if either mobility OR vision needs exist
        return hasMobilityNeeds || hasVisionNeeds
    }
}

struct MobileQuestionnairView: View {
    @Inject var userAccountProvider: UserAccountProvider
	@ObservedObject var viewModel = MobileQuestionnairViewModel.shared
    @State var selectedAnswerQ1: [String] = []
    @State var selectedAnswerQ2: Bool?
    @State var selectedAnswerQ3: String = ""
    var isRegistrationFlow: Bool
	let q1Answers = ["No Assistive Device", "White Cane", "Manual Walker",  "Wheeled Walker", "Cane", "Crutches", "Stroller", "Service Animal", "Mobility Scooter", "Electric Wheelchair", "Manual/Traditional Wheelchair"]
    let questionOneValue = ["no assistive device", "white cane", "manual walker", "wheeled walker", "cane", "crutches", "stroller", "service animal", "mobility scooter", "electric wheelchair", "manual wheelchair"]
	let yesNoAnswers = ["Yes", "No"]
    let q3Answers = ["Low-vision", "Legally-blind","No vision limitations"]
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {

        ZStack{
            VStack(spacing: 0){
                if !isRegistrationFlow{
                    VStack{
                        Spacer().frame(height: ScreenSize.safeTop())
                        HStack{
                            Button(action: {
                                if viewModel.isMobilityProfileUpdated(){
                                    viewModel.pubShowCloseAlert = true
                                }else{
                                    viewModel.pubOpenMobileQuestionnairs = false
                                }
                            }, label: {
                                HStack(){
                                    Image("ic_leftarrow").renderingMode(.template).resizable().foregroundColor(Color.white)
                                        .frame(width: 15, height: 20, alignment: .center)
                                }
                            })
                            .frame(width: 30, height: 30)
                            .padding(.leading, 10)
                            .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
                            Spacer()
                            TextLabel("Mobility Profile".localized(), .bold, .title3).foregroundStyle(Color.white)
                            Spacer()
                            Spacer().frame(width:30,height: 30)
                        }
                        Spacer().frame(height:20)
                    }
                    .background(Color.main)
                }
                
                ScrollView{
                    VStack(alignment:.leading){
                        TextLabel("Define your Mobility Profile", .bold, .title3).foregroundStyle(Color.black)
                        TextLabel("Please answer a few questions to customize the trip planning experience to your needs and preferences.", .regular, .callout).foregroundStyle(Color.black)
                        Spacer().frame(height:50)
                        TextLabel("1. Do you regularly use a mobility assistive device? (Check all that apply)", .bold, .callout).foregroundStyle(Color.black)
                        ExclusiveCheckBoxList(checklistOptions: $viewModel.pubQuestionOneOptions, checkedOptions: viewModel.selectedMobilityProfile?.mobilityDevices) { selectedOptions in
                            selectedAnswerQ1 = selectedOptions
                            viewModel.updateSelection(
                                ans1: selectedAnswerQ1,                                ans2: selectedAnswerQ2 ?? (viewModel.selectedMobilityProfile?.isMobilityLimited ?? false),
                                ans3: selectedAnswerQ3 == "" ? viewModel.selectedMobilityProfile?.visionLimitation ?? "" : selectedAnswerQ3)
                        }
                        Spacer().frame(height:20)
                        TextLabel("2. Do you have any mobility limitations that cause you to walk more slowly or more carefully than other people?", .bold, .callout).foregroundStyle(Color.black)
                        CheckBoxList(options: yesNoAnswers, enableMultipleSelection: false, selectedOption: viewModel.selectedMobilityProfile?.isMobilityLimited != nil ? viewModel.selectedMobilityProfile?.isMobilityLimited  == true ? "Yes" : "No" : nil){ selectedOption in
                            selectedAnswerQ2 = selectedOption[0] == "Yes" ? true : false
                            viewModel.updateSelection(
                                ans1: selectedAnswerQ1,
                                ans2: selectedAnswerQ2 ?? false,
                                ans3: selectedAnswerQ3 == "" ? viewModel.selectedMobilityProfile?.visionLimitation ?? "" : selectedAnswerQ3)
                        }
                        Spacer().frame(height:20)
                        TextLabel("3. Do you have any vision limitations?", .bold, .callout).foregroundStyle(Color.black)
                        
                        CheckBoxList(options: q3Answers, enableMultipleSelection: false, selectedOption: viewModel.selectedMobilityProfile?.visionLimitation == "none" ? "No vision limitations" : viewModel.selectedMobilityProfile?.visionLimitation){ selectedOption in
                            selectedAnswerQ3 = selectedOption[0]
                            viewModel.updateSelection(
                                ans1: selectedAnswerQ1,
                                ans2: selectedAnswerQ2 ?? (viewModel.selectedMobilityProfile?.isMobilityLimited ?? false),
                                ans3: selectedAnswerQ3 == "" ? viewModel.selectedMobilityProfile?.visionLimitation ?? "" : selectedAnswerQ3)
                        }
                        Spacer().frame(height:20)
                        Button {
                            userAccountProvider.storeUserInfoToServer { success in
                                if success {
                                    AlertManager.shared.presentAlert(message: "Your preferences have been saved.".localized())
                                    JMapManager.shared.pubAccessLevel = viewModel.hasMobilityOrVisionNeeds() ? 0 : 100
                                    viewModel.pubOpenMobileQuestionnairs = false
                                }else{
                                    AlertManager.shared.presentAlert(message: "Failed to save preferences.".localized())
                                    viewModel.pubOpenMobileQuestionnairs = false
                                }
                            }
                        } label: {
                            HStack{
                                Spacer()
                                TextLabel("Save Preferences".localized()).font(.body).foregroundColor(Color.white).padding(20)
                                Spacer()
                            }
                            .background(Color.main)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        Spacer().frame(height: ScreenSize.safeBottom())
                    }
                    .padding(20)
                }
            }
            .background(Color.white)
            .zIndex(99)
            .onAppear{
                // Initialize local state from existing profile to avoid accidental overrides
                if let isLimited = viewModel.selectedMobilityProfile?.isMobilityLimited {
                    selectedAnswerQ2 = isLimited
                }
                if let vision = viewModel.selectedMobilityProfile?.visionLimitation, !vision.isEmpty {
                    selectedAnswerQ3 = (vision == "none") ? "No vision limitations" : vision
                }
                
                viewModel.pubQuestionOneOptions = [CheckListItem]()
                for i in 0 ..< questionOneValue.count{
                    var isSelected = false
                    if let mobilityDevices = viewModel.selectedMobilityProfile?.mobilityDevices{
                        selectedAnswerQ1 = mobilityDevices
                        for device in mobilityDevices {
                            if device == questionOneValue[i]{
                                isSelected = true
                            }
                        }
                    }
                    let item = CheckListItem(value: questionOneValue[i], label: q1Answers[i], isSelected: isSelected)
                    viewModel.pubQuestionOneOptions.append(item)
                }
            }
            if viewModel.pubShowCloseAlert{
                CustomAlertView(titleMessage: "You have unsaved changes", primaryButton: "Keep editing", secondaryButton: "Discard changes",primaryAction: {
                    viewModel.pubShowCloseAlert = false
                }, secondaryAction: {
                    viewModel.selectedMobilityProfile = viewModel.serverMobilityProfile
                    viewModel.pubOpenMobileQuestionnairs = false
                    viewModel.pubShowCloseAlert = false
                }).zIndex(100)
                .accessibility(addTraits: [.isModal])
            }
        }
	}
}

struct ExclusiveCheckBoxList: View {
    @Binding var checklistOptions: [CheckListItem]
    @State var checkedOptions: [String]?
    @State var selectedOption: String?
    var onOptionsSelected: ((_ options: [String]) -> Void)?
    
    /// Is in checked option.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isInCheckedOption(_ option: String) -> Bool {
        guard let checkedOptions = checkedOptions else { return false }
        return checkedOptions.contains { $0.lowercased() == option.lowercased() }
    }
    
    /// Coordinated checked option.
    /// - Parameters:
    ///   - _: Parameter description
    func coordinatedCheckedOption(_ isSelected: Bool, _ option: String) {
        if checkedOptions == nil {
            checkedOptions = []
        }
        
        guard var checkedOptions = checkedOptions else { return }
        
        // Special case: "no assistive device"
        if option == "no assistive device" {
            if isSelected {
                // Represent "no assistive device" as empty array
                self.checkedOptions = []
                
                for i in 0..<checklistOptions.count {
                    checklistOptions[i].isSelected = (checklistOptions[i].value == "no assistive device")
                }
            }
            return
        }
        
        // Uncheck "no assistive device" if other options are selected
        if let index = checklistOptions.firstIndex(where: { $0.value == "no assistive device" }) {
            checklistOptions[index].isSelected = false
        }
        
        if isSelected {
            if !checkedOptions.contains(option) {
                checkedOptions.append(option)
            }
        } else {
            checkedOptions.removeAll { $0 == option }
        }
        
        self.checkedOptions = checkedOptions
        
        // If no selections, mark "no assistive device" as checked
        if checkedOptions.isEmpty {
            if let index = checklistOptions.firstIndex(where: { $0.value == "no assistive device" }) {
                checklistOptions[index].isSelected = true
            }
        }
    }
    
    /// Initializes a new instance.

    /// Sync initial state

    /// Sync initial state.
    private func syncInitialState() {
        // If nothing selected, default to "no assistive device"
        if let checkedOptions = checkedOptions, checkedOptions.isEmpty {
            if let index = checklistOptions.firstIndex(where: { $0.value == "no assistive device" }) {
                checklistOptions[index].isSelected = true
            }
        } else if let checkedOptions = checkedOptions {
            // Mark all matching options as selected
            for i in 0..<checklistOptions.count {
                checklistOptions[i].isSelected = checkedOptions.contains { $0.lowercased() == checklistOptions[i].value.lowercased() }
            }
        }
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ForEach(0..<checklistOptions.count, id: \.self){ index in
            ExclusiveCheckBox(isChecked: $checklistOptions[index].isSelected, title: checklistOptions[index].label, value: checklistOptions[index].value) { isChecked, option in
                self.coordinatedCheckedOption(isChecked, option)
                self.onOptionsSelected?(self.checkedOptions ?? [])
            }
        }
        .onAppear {
            syncInitialState()
        }
    }
}


struct ExclusiveCheckBox: View {
    @Binding var isChecked: Bool
    var checked: Bool = false
    var title:String = ""
    var value: String
    var size: CGFloat = 25
    var color: Color = Color.black
    var onOptionSelected: ((_ isChecked: Bool, _ option: String) -> Void)?
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        Button(action: {
            isChecked.toggle()
            if let onOptionSelected = self.onOptionSelected {
                onOptionSelected(self.isChecked, self.value)
            }
        }, label: {
            HStack {
                Image(systemName: isChecked ? "checkmark.square" : "square")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundStyle(Color.black)
                Spacer().frame(width:3)
                TextLabel(title).font(.subheadline).foregroundColor(color)
                Spacer()
            }
        })
        .foregroundStyle(Color.black)
    }
}

struct CheckBoxList: View {
    var options: [String]
    var enableMultipleSelection: Bool
    @State var checkedOptions: [String]?
    @State var selectedOption: String?
    var onOptionsSelected: ((_ options: [String]) -> Void)?
    
    /// Is in checked option.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isInCheckedOption(_ option: String) -> Bool {
        guard let checkedOptions = checkedOptions else {
            return false
        }
         
        for opt in checkedOptions {
            if opt.lowercased() == option.lowercased() {
                return true;
            }
        }
        return false
    }
    
    /// Coordinated checked option.
    /// - Parameters:
    ///   - _: Parameter description
    func coordinatedCheckedOption(_ isSelected: Bool, _ option: String) {
        if checkedOptions == nil {
            checkedOptions = [String]()
        }
        
        guard let checkedOptions = checkedOptions else {
            return
        }
        if isSelected {
            if !isInCheckedOption(option) {
                self.checkedOptions?.append(option)
            }
        }else{
            if isInCheckedOption(option){
                for i in 0..<checkedOptions.count {
                    if checkedOptions[i].lowercased() == option.lowercased() {
                        self.checkedOptions?.remove(at: i)
                        break
                    }
                }
            }
        }
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        if enableMultipleSelection{
            ForEach(0..<options.count, id: \.self){ index in
                CheckBox(isChecked: isInCheckedOption(self.options[index]), title: self.options[index]) { isChecked, option in
                    self.coordinatedCheckedOption(isChecked, option)
                    self.onOptionsSelected?(self.checkedOptions ?? [])
                }
            }
        }else{
            ForEach(0..<options.count, id: \.self){ index in
                RadioButton(isChecked: selectedOption?.lowercased() == options[index].lowercased(), title: options[index]){
                    if selectedOption == options[index] {
                        selectedOption = nil
                    }else{
                        selectedOption = options[index]
                        self.onOptionsSelected?([options[index]])
                    }
                }
            }
        }
    }
}

struct CheckBox: View {
	@State var isChecked: Bool
	var checked: Bool = false
	var title:String = ""
	var size: CGFloat = 25
	var color: Color = Color.black
    var onOptionSelected: ((_ isChecked: Bool, _ option: String) -> Void)?
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		Button(action: {
			isChecked.toggle()
            if let onOptionSelected = self.onOptionSelected {
                onOptionSelected(self.isChecked, self.title)
            }
		}, label: {
			HStack {
				Image(systemName: isChecked ? "checkmark.square" : "square")
					.renderingMode(.template)
					.resizable()
					.frame(width: size, height: size)
					.foregroundStyle(Color.black)
				Spacer().frame(width:3)
				TextLabel(title).font(.subheadline).foregroundColor(color)
				Spacer()
			}
		})
		.foregroundStyle(Color.black)
	}
}

struct RadioButton: View {
    var isChecked: Bool
    var title: String
    var size: CGFloat = 25
    var color: Color = Color.black
    var action: () -> Void

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image(systemName: isChecked ? "checkmark.square" : "square")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundStyle(Color.black)
                Spacer().frame(width:5)
                TextLabel(title).font(.subheadline).foregroundColor(color)
                Spacer()
            }
        }
        .foregroundColor(Color.black)
    }
}
