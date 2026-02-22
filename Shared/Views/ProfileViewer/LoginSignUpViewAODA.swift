//
//  LoginSignUpViewAODA.swift
//

import SwiftUI

struct LoginSignUpViewAODA: View {
    
    @Environment(\.openURL) var openURL
    @ObservedObject var viewModel = LoginSignUpModel.shared
    @State var username: String = ""
    @State var password: String = ""
    @State var isSignUp: Bool = false
    @State var userState : UserState = .login
    @State var showDialog = false
    @State var isEmailValid = true
    @State var isPasswordValid = true
    @State var isPasswordEmpty = false
    @State var errorMessage: String? = nil
    @State var uiViewColor: Color? = nil
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack{
            VStack{
                Spacer().frame(height: ScreenSize.safeTop())
                // MARK: - Header
                VStack{
                    ZStack{
                        HStack{
                            Image("customer_logo_icon")
                                .resizable()
                                .frame(width: FeatureConfig.shared.login_logo_width, height: FeatureConfig.shared.login_logo_height)
                                .background(Color.main)
                                .accessibilityHidden(true)
                        }
                        .frame(width: ScreenSize.width(), height: ScreenSize.height() * 0.12)
                        .background(Color.main)
                        
                        HStack {
                            Spacer().frame(width: 15)
                            if userState == .resetPassword{
                                Button {
                                    userState = .login
                                    isSignUp = false
                                } label: {
                                    Image(systemName: "arrow.backward.circle.fill")
                                        .resizable()
                                        .renderingMode(.template)
                                        .font(.body)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(Color.white)
                                        .frame(width: 30, height: 30)
                                }.addAccessibility(text: "Back Button Double tap to activate".localized())
                            }
                            Spacer()
                        }
                    }
                    
                    if !(userState == .resetPassword){
                        HStack(spacing: 0){
                            Button {
                                userState = .login
                                isSignUp = false
                            } label: {
                                VStack{
                                    TextLabel("Log In".localized(),isSignUp ? .regular : .bold,.title3)
                                        .foregroundColor(isSignUp ? .gray : .black)
                                    Rectangle()
                                        .fill(isSignUp ? .gray : .black)
                                        .frame(height: 1.3)
                                        .padding(.leading ,5)
                                }
                                
                            }.addAccessibility(text: "Log In Button, Double tap to activate".localized())
                                
                            Button {
                                isSignUp = true
                                userState = .signup
                            } label: {
                                VStack{
                                    TextLabel("Sign Up".localized(), isSignUp ? .bold : .regular, .title3)
                                        .foregroundColor(isSignUp ? .black : .gray)
                                    Rectangle()
                                        .fill(isSignUp ? .black : .gray)
                                        .frame(height: 1.3)
                                        .padding(.trailing, 5)
                                }
                            }.addAccessibility(text: "Sign up Button, Double tap to activate".localized())
                        }
                        .padding(.top, 5)
                        .frame(width:ScreenSize.width())
                        .accessibilityRemoveTraits(.isModal)
                    }
                }
                Spacer()
                
                // MARK: - Body
                ScrollView {
                    VStack{
                        if userState == .resetPassword {
                            ScrollView {
                                TextLabel("Please enter your email. We will send you an email to confirm the password change.".localized())
                                    .multilineTextAlignment(.center)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .padding()
                                    .addAccessibility(text: "Please enter your email. We will send you an email to confirm the password change.".localized())
                                
                                
                                AutoHeightTextField(text: $username, iconName: "ic_email", placeholder: "Email".localized()) { value in
                                    if let value = value {
                                        isEmailValid = isValidEmail(value)
                                    }
                                }
                                .roundedBorder(0,0)
                                .padding(.horizontal, 25)
                                
                                if !isEmailValid{
                                    TextLabel("Must be a valid email address".localized())
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .allowsHitTesting(false)
                                        .addAccessibility(text: "Must be a valid email address".localized())
                                        .onAppear {
                                            UIAccessibility.post(notification: .announcement, argument: "Must be a valid email address".localized())
                                        }
                                }
                            }
                            .onDisappear {
                                isEmailValid = true
                                isPasswordValid = true
                                isPasswordEmpty = false
                            }
                            
                        }else{
                                AutoHeightTextField(text: $username, iconName: "ic_email", placeholder: "Email".localized()) { value in
                                    if let value = value {
                                        isEmailValid = isValidEmail(value)
                                    }
                                }
                                .roundedBorder(0,0)
                                .padding(.horizontal, 25)
                                
                                if !isEmailValid{
                                    TextLabel("Must be a valid email address".localized())
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .addAccessibility(text: "Must be a valid email address".localized())
                                        .onAppear {
                                            UIAccessibility.post(notification: .announcement, argument: "Must be a valid email address".localized())
                                        }
                                }
                                
                                Spacer().frame(height:10)
                                
                                SecureIconField(text:$password, iconName: "ic_lock", placeholder:"Password".localized()) { text in
                                    viewModel.checkRegexConditions(inputText: text ?? "")
                                    isPasswordValid = isPasswordValid(text ?? "")
                                    isPasswordEmpty = !((text ?? "").count > 0)
                                }
                                
                                if isPasswordEmpty{
                                    TextLabel("Password can't be empty".localized())
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .onAppear {
                                            UIAccessibility.post(notification: .announcement, argument: "Password can't be empty".localized())
                                        }
                                }
                            
                            if isSignUp && !(userState == .resetPassword){
                                passwordConditionsViewAODA
                            }
                        }
                    }
                    //MARK: - bottom Login/SignUp/Reset Button
                    VStack(spacing:0){
                        if !isSignUp && !(userState == .resetPassword){
                            Button {
                                isEmailValid = true
                                isPasswordValid = true
                                isPasswordEmpty = false
                                userState = .resetPassword
                            } label: {
                                HStack{
                                    Spacer()
                                    TextLabel("Don't remember your password?".localized())
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }.background(Color.white)
                            }
                            .padding(0)
                            .addAccessibility(text: "Forgot Password Button, Double tap to activate".localized())
                            
                        }
                    }
                }
                BottomButtonView(username: $username, password: $password, errorMessage: $errorMessage, uiViewColor: $uiViewColor, isEmailValid: $isEmailValid, isPasswordValid: $isPasswordValid, isPasswordEmpty: $isPasswordEmpty, userState: userState, width:ScreenSize.width(), heignt: 70)
            }
            .background(Color.white)
            
            VStack {
                Spacer().frame(height: ScreenSize.safeTop() + 10)
                if !(errorMessage == nil){
                    HStack{
                        Image("ic_exclamation")
                            .resizable()
                            .frame(width: AccessibilityManager.shared.getFontSize(), height: AccessibilityManager.shared.getFontSize())
                        TextLabel(errorMessage ?? "")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(width: ScreenSize.width() - 20)
                    .background(!(uiViewColor == nil) ? uiViewColor : .red)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.errorMessage = nil
                        }
                    }
                    .addAccessibility(text: "%1".localized(errorMessage ?? ""))
                    
                }
                Spacer()
            }
            .accessibilityAddTraits(.isModal)
        }
        .onTapGesture {
            UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(true) // 4
        }
    }
    
    /// Password conditions view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var passwordConditionsViewAODA: some View {
        VStack(alignment: .leading){
            TextLabel("Your password must contain:".localized()).padding(.leading, 5)
            
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.eightChar) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(Color.black)
                }
                TextLabel("At least 8 characters".localized()).padding(.leading, 5).foregroundStyle(viewModel.passwordConditions.contains(.eightChar) ? Color.green : Color.black)
            }.padding(.leading, 5)
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.followingThree) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(Color.black)
                }
                TextLabel("At least 3 of the following:".localized()).padding(.leading, 5).foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
            }.padding(.leading, 5)
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.lowerCase) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Lower case letters (a-z)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.lowerCase) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }.padding(.leading, 5)
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.upperCase) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Upper case letters (A-Z)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.upperCase) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }.padding(.leading, 5)
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.numbers) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Numbers (0-9)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.numbers) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }.padding(.leading, 5)
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.specialChar) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/3, height: AccessibilityManager.shared.getFontSize()/3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: AccessibilityManager.shared.getFontSize()/4, height: AccessibilityManager.shared.getFontSize()/4)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Special characters (e.g. !@#$%^&*)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.specialChar) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }.padding(.leading, 5)
        }
        .frame(width: ScreenSize.width() - 50)
        .padding(.vertical, 10)
        .roundedBorder(0,0)
        .padding(.top, isPasswordEmpty ? 0 : 10)
    }
    
    /// Is valid email.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Is password valid.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Bool
    func isPasswordValid(_ password: String) -> Bool {
        var lowercaseCount = 0
        var uppercaseCount = 0
        var numberCount = 0
        var specialCharCount = 0

        for char in password {
            if char.isLowercase { lowercaseCount += 1 }
            else if char.isUppercase { uppercaseCount += 1 }
            else if char.isNumber { numberCount += 1 }
            else { specialCharCount += 1 }
        }

        let conditionsMet = [
            lowercaseCount > 0,
            uppercaseCount > 0,
            numberCount > 0,
            specialCharCount > 0
        ].filter { $0 }.count

        return password.count >= 8 && conditionsMet >= 3
    }
}


struct LoginSignUpViewAODA_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        LoginSignUpViewAODA(username: "", password: "")
    }
}
