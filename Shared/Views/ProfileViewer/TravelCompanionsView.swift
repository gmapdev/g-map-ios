//
//  TravelCompanionsView.swift
//

import SwiftUI

class TravelCompanionsViewModel: ObservableObject {
    
    @Published var pubCompanions : [RelatedUser] = []
    @Published var pubDependents : [DependentUser] = []
    @Published var pubCompanionEmail: String = ""
    
    /// Shared.
    /// - Parameters:
    ///   - TravelCompanionsViewModel: Parameter description
    public static var shared: TravelCompanionsViewModel = {
        let mgr = TravelCompanionsViewModel()
        return mgr
    }()
    
    /// Get companion list
    /// - Returns: [String]
    /// Retrieves companion list.
    func getCompanionList() -> [String] {
        var allCompanionsEmails: [String] = []
        for item in pubCompanions{
            if let email = item.email,
               let status = item.status,
               status == "CONFIRMED"{
                allCompanionsEmails.append(email)
            }
        }
        return allCompanionsEmails
    }
    /// Get dependents mobility profile list
    /// Retrieves dependents mobility profile list.
    func getDependentsMobilityProfileList(){
        var allCompanionsEmails: [String] = ["Myself"]
        for item in pubDependents{
            allCompanionsEmails.append(item.email)
        }
        TripSettingsViewModel.shared.pubMobilityProfileDropdownItems = allCompanionsEmails
    }
    
    /// Get companion object.
    /// - Parameters:
    ///   - email: Parameter description
    /// - Returns: RelatedUser?
    func getCompanionObject(email: String) -> RelatedUser? {
        return pubCompanions.first(where: {$0.email == email})
    }
    /// Get observers object.
    /// - Parameters:
    ///   - observers: Parameter description
    /// - Returns: [RelatedUser]?
    /// Retrieves observers object.
    func getObserversObject(observers: [String]) -> [RelatedUser]? {
        // Create a dictionary for fast lookup
        let emailToUserMap = Dictionary(uniqueKeysWithValues: pubCompanions.map { ($0.email, $0) })
        
        // Use compactMap to efficiently filter and map observers to RelatedUser objects
        let observersArray = observers.compactMap { emailToUserMap[$0] }
        
        // Return nil if the array is empty, otherwise return the array
        return observersArray.isEmpty ? nil : observersArray
    }

    
    /// Set mobility for.
    /// - Parameters:
    ///   - selectedUser: Parameter description
    /// - Returns: String?
    func setMobilityFor(selectedUser : String) -> String? {
        for item in pubDependents{
            if item.email == selectedUser {
                return item.mobilityMode
            }
        }
        return nil
    }
}

struct TravelCompanionsView: View {
    
    @Inject var userAccountProvider: UserAccountProvider
    @ObservedObject var viewModel = TravelCompanionsViewModel.shared
    @State var isEmailValid = true
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return VStack{
            Spacer().frame(height:15)
            VStack{
                HStack{
                    TextLabel("Travel Companions".localized(), .bold, .title2)
                    Spacer()
                }
                HStack{
                    TextLabel("Invite an existing G-MAP user to be a travel companion by entering their email. When they accept, their status will change to \"verified\", and you can share your trip status and plan trips based on one another's mobility profile.".localized(), .bold, .subheadline).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 5)
                    Spacer()
                }
                HStack{
                    VStack{
                        HStack{
                            TextLabel("Current travel companions:".localized(), .bold, .subheadline).foregroundColor(Color.black)
                            Spacer()
                        }
                        VStack{
                            if viewModel.pubCompanions.count > 0 {
                                ForEach(0..<viewModel.pubCompanions.count, id:\.self){ index in
                                    HStack{
                                        Spacer().frame(width: 12)
                                        Image(systemName: "person.fill").resizable().frame(width:16, height:16)
                                        Spacer()
                                        TextLabel(viewModel.pubCompanions[index].email ?? "", .regular, .subheadline).foregroundColor(Color.black)
                                        Spacer()
                                        let companion = viewModel.pubCompanions[index]
                                        
                                        TextLabel(companion.status == "CONFIRMED" ? "Verified".localized() :
                                                    companion.status == "PENDING" ? "Pending".localized() :
                                                    companion.status == "INVALID" ? "Invalid".localized() :
                                                    "Pending".localized(),
                                                  .bold, .subheadline)
                                        .padding(3)
                                        .background(companion.status == "CONFIRMED" ? Color.green :
                                                        companion.status == "PENDING" ? Color.orange :
                                                        companion.status == "INVALID" ? Color.gray :
                                                        Color.orange)
                                        .foregroundColor(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        Spacer()
                                        Button {
                                            let targetCompanion = viewModel.pubCompanions[index]
                                            if let companionIndex = viewModel.pubCompanions.firstIndex(where: { $0.email == targetCompanion.email }) {
                                                viewModel.pubCompanions.remove(at: companionIndex)
                                            }
                                            userAccountProvider.storeUserInfoToServer { success in }
                                        } label: {
                                            Image(systemName: "trash.fill").resizable().foregroundColor(.black).frame(width:20, height:20)
                                        }
                                        Spacer()
                                    }
                                }
                                Spacer()
                            }else{
                                HStack{
                                    TextLabel("You do not have any existing travel companions.".localized(), .regular, .subheadline).foregroundColor(Color.black)
                                        .padding(.vertical, 5)
                                }
                            }
                            
                        }
                    }
                }
                HStack{
                    TextLabel("Add a new travel companion".localized(), .bold, .subheadline).foregroundColor(Color.black)
                    Spacer()
                }.padding(.vertical, 5)
                VStack{
                    HStack{
                        AutoHeightTextField(text: self.$viewModel.pubCompanionEmail, placeholder: "friend.email@example.com".localized(), keyboradType: .emailAddress, onValueChange: { newValue in
                            if let newValue = newValue {
                                isEmailValid = newValue == "" ? true : Helper.shared.isValidEmail(newValue)
                                if isEmailValid{
                                    viewModel.pubCompanionEmail = newValue
                                }
                            }
                        }, onTapTrigger: {
                            
                        })
                        .roundedBorder(0,0)
                    }

                    if !isEmailValid{
                        TextLabel("Must be a valid email address".localized())
                            .font(.body)
                            .foregroundColor(.red)
                            .addAccessibility(text: "Must be a valid email address".localized())
                            .onAppear {
                                UIAccessibility.post(notification: .announcement, argument: "Must be a valid email address".localized())
                            }
                    }
                    Spacer().frame(height: 10)
                    HStack{
                        Button(action: {
                            if Helper.shared.isValidEmail(viewModel.pubCompanionEmail){
                                viewModel.pubCompanions.append(RelatedUser(email: viewModel.pubCompanionEmail, status: "PENDING"))
                                userAccountProvider.storeUserInfoToServer { success in
                                    if success {
                                        viewModel.pubCompanionEmail = ""
                                        UIApplication.shared.dismissKeyboard()
                                    }
                                }
                            }else{
                                isEmailValid = false
                            }
                        }, label: {
                            HStack{
                                TextLabel("Send invitation".localized()).padding(10)
                                    .font(.body)
                            }
                            .background(isEmailValid ? Color.main : Color.gray_main)
                            .foregroundColor(Color.white)
                            /// Corner radius: 10)
                            /// Initializes a new instance.
                            /// - Parameters:

                            ///   - RoundedRectangle.init(cornerRadius: 10
                            .clipShape(RoundedRectangle.init(cornerRadius: 10))
                        })
                    }
                }
            }
            .padding(.horizontal, 15)
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
            }
        }
    }
}

#Preview {
    TravelCompanionsView()
}
