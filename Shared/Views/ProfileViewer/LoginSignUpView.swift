//
//  LoginSignUpView.swift
//

import SwiftUI

enum UserState: String{
    case login = "LOGIN"
    case signup = "SIGN UP"
    case resetPassword = "SEND EMAIL"
}

struct SecureIconField: View {
	@Binding var text: String
	var iconName: String?
	var placeholder: String?
	var showEyeButton = true
	var keyboradType: UIKeyboardType = .default
	var onValueChange: ((String? ) -> Void)?
	
	@State var isSecured = true
	
 /// Body.
 /// - Parameters:
 ///   - some: Parameter description
	var body: some View {
		
		HStack{
			if let iconName = iconName {
				VStack{
					Spacer()
					Image(iconName)
						.resizable()
						.renderingMode(.template)
						.aspectRatio(contentMode: .fit)
						.font(.body)
						.frame(width: 20, height: 20, alignment: .center)
						.foregroundColor(Color.main)
						.padding(6)
						.padding(.leading, 8)
						.padding(.trailing, 8)
						.background(Color.gray_main)
					Spacer()
				}
				.background(Color.gray_main)
			}
			 
			 Spacer().frame(width: 15)
			 
			 VStack{
				 Spacer()
				 if isSecured {
					 SecureField(placeholder ?? "", text: $text)
						 .font(.body)
						 .multilineTextAlignment(TextAlignment.leading)
						 .keyboardType(.webSearch)
						 .autocapitalization(.none)
						 .onChange(of: text) { _ in
							 onValueChange?(text)
						 }
				 }else {
					 ZStack{
       /// Initializes a new instance.
						 TextLabel("\(text)").padding(5)	// place a text here for the caller to know the height when we try to set the initialize value.
						 TextEditor(text: $text)
							 .autocapitalization(.none)
							 .keyboardType(keyboradType)
							 .multilineTextAlignment(.leading)
							 .onSubmit {
								 UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(true)
							 }
							 .onChange(of: text) { _ in
								 onValueChange?(text)
							 }
							 .frame(minHeight: 40)
							 .padding(0)
					 }
					 .padding(0)
				 }
				 Spacer()
			 }
			
			 if showEyeButton {
				Button(action: {
					isSecured.toggle()
				}) {
					Image(systemName: self.isSecured ? "eye.slash.fill" : "eye.fill")
						.resizable()
						.renderingMode(.template)
						.aspectRatio(contentMode: .fit)
						.font(.body)
						.frame(width: 25, height: 25, alignment: .center)
						.foregroundColor(Color.gray)
				}
                .addAccessibility(text: self.isSecured ? "Show Password Button, Double tap to activate".localized() : "Hide Password Button, Double tap to activate".localized())
				.padding()
			}
		 }
        .addAccessibility(text: "Enter your %1, Double Tap to Enter %2".localized(placeholder ?? "text".localized(), placeholder ?? "text".localized()))
         .roundedBorder(0,0)
			 .padding(.horizontal, 25)
	}
}

public struct AutoHeightTextField: View {
	@Binding var text: String
	var iconName: String?
	var placeholder: String?
    var keyboradType: UIKeyboardType = .emailAddress
    var minHeight = 40.0
    var onValueChange: ((String? ) -> Void)?
    var onTapTrigger: (()->Void)?
	enum FocusedField {
		 case username
	}
	
	@FocusState private var focusedField: FocusedField?
	
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    public var body: some View {
		return HStack{
			if let iconName = iconName {
				VStack{
					Spacer()
					Image(iconName)
						.resizable()
						.renderingMode(.template)
						.aspectRatio(contentMode: .fit)
						.font(.body)
						.frame(width: 20, height: 20, alignment: .center)
						.foregroundColor(Color.main)
						.padding(6)
						.padding(.leading, 8)
						.padding(.trailing, 8)
						.background(Color.gray_main)
					Spacer()
				}
				.background(Color.gray_main)
			}
			 
			 Spacer().frame(width: 15)
			 
			 VStack{
				 Spacer()
				 ZStack{
      /// Initializes a new instance.
					 TextLabel("\(text)")	// place a text here for the caller to know the height when we try to set the initialize value.
					 TextEditor(text: $text)
                         .font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))
						 .autocapitalization(.none)
                         .keyboardType(keyboradType)
						 .multilineTextAlignment(.leading)
						 .onSubmit {
							 UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.endEditing(true)
						 }
						 .onChange(of: text) { _ in
							 onValueChange?(text)
						 }
						 .focused($focusedField, equals: .username)
                         .frame(minHeight: minHeight)
					 
					 if text.count <= 0 {
						 Button(action: {
							 focusedField = .username
                             onTapTrigger?()
						 }, label: {
							 HStack{
								 Spacer().frame(width:5)
								 TextLabel(placeholder ?? "")
									 .multilineTextAlignment(.leading)
									 .foregroundColor(Color.gray)
									 .opacity(0.6)
								 Spacer()
							 }
						 })
					 }
				 }
				 Spacer()
			 }
		 }
		.addAccessibility(text: "Enter your %1, Double Tap to Enter %2".localized(placeholder ?? "text", placeholder ?? "text"))
         .onTapGesture {
             onTapTrigger?()
         }
	}
}

struct LoginSignUpView: View {
    
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
        // Count occurrences of each character type
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

        // Check conditions for password validity
        let conditionsMet = [
            lowercaseCount > 0,
            uppercaseCount > 0,
            numberCount > 0,
            specialCharCount > 0
        ].filter { $0 }.count

        return password.count >= 8 && conditionsMet >= 3
    }
	
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
                                        }
                                        .frame(width: 40, height: 40)
                                        .addAccessibility(text: "Back Button Double tap to activate".localized())
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
                                        TextLabel("Log In".localized(), isSignUp ? .regular : .bold , .title3)
                                            .foregroundColor(isSignUp ? .gray : .black)
                                        Rectangle()
                                            .fill(isSignUp ? .gray : .black)
                                            .frame(height: 1.3)
                                            .padding(.leading ,5)
                                    }
                                    
                                }.frame(width:ScreenSize.width() / 2)
                                    .addAccessibility(text: "Log In Button, Double tap to activate".localized())
                                Button {
                                        isSignUp = true
                                    userState = .signup
                                } label: {
                                    VStack{
                                        TextLabel("Sign Up".localized(),isSignUp ? .bold : .regular,.title3)
                                            .foregroundColor(isSignUp ? .black : .gray)
                                        Rectangle()
                                            .fill(isSignUp ? .black : .gray)
                                            .frame(height: 1.3)
                                            .padding(.trailing, 5)
                                    }
                                }.frame(width:ScreenSize.width() / 2)
                                    .addAccessibility(text: "Sign up Button, Double tap to activate".localized())
                            }
                            .padding(.top, 5)
                            .frame(width:ScreenSize.width())
                        }
                    }
                    Spacer()
                    
                    // MARK: - Body
                    VStack{
                        if userState == .resetPassword {
                            TextLabel("Please enter your email. We will send you an email to confirm the password change.".localized())
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .foregroundColor(.black)
                                .padding()
                                .addAccessibility(text: "Please enter your email. We will send you an email to confirm the password change.".localized())
							
							ScrollView {
								
								Spacer().frame(height:150)
								
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
							Spacer()
								ScrollView {
									
									Spacer().frame(height:150)
									
                                    AutoHeightTextField(text: $username, iconName: "ic_email", placeholder: "Email".localized()) { value in
										if let value = value {
											isEmailValid = isValidEmail(value)
										}
									}
                                    .frame(minHeight: 50)
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
                                        passwordConditionsView
                                    }
								}
                        }
                    }
                    Spacer()
                
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
                                Spacer()
                            }.background(Color.white)
                        }
                        .padding(0)
                        .addAccessibility(text: "Forgot Password Button, Double tap to activate".localized())
                        
                    }
                    Rectangle().fill(Color.white).frame(height:20)
                    BottomButtonView(username: $username, password: $password, errorMessage: $errorMessage, uiViewColor: $uiViewColor, isEmailValid: $isEmailValid, isPasswordValid: $isPasswordValid, isPasswordEmpty: $isPasswordEmpty, userState: userState, width:ScreenSize.width(), heignt: 50)
                    
                }
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
    
    /// Password conditions view.
    /// - Parameters:
    ///   - some: Parameter description
    var passwordConditionsView: some View {
        VStack(alignment: .leading){
            TextLabel("Your password must contain:".localized())
            
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.eightChar) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(Color.black)
                }
                TextLabel("At least 8 characters".localized()).padding(.leading, 5).foregroundStyle(viewModel.passwordConditions.contains(.eightChar) ? Color.green : Color.black)
            }
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.followingThree) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(Color.black)
                }
                TextLabel("At least 3 of the following:".localized()).padding(.leading, 5).foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
            }
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.lowerCase) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Lower case letters (a-z)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.lowerCase) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.upperCase) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Upper case letters (A-Z)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.upperCase) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.numbers) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Numbers (0-9)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.numbers) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }
            HStack(spacing: 0){
                if viewModel.passwordConditions.contains(.specialChar) {
                    Image(systemName: "checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "circle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 5, height: 5)
                        .foregroundStyle(viewModel.passwordConditions.contains(.followingThree) ? Color.green : Color.black)
                }
                TextLabel("Special characters (e.g. !@#$%^&*)".localized()).padding(.leading, 15).foregroundStyle((viewModel.passwordConditions.contains(.specialChar) || viewModel.passwordConditions.contains(.followingThree)) ? Color.green : Color.black)
            }
        }
        .frame(width: ScreenSize.width() - 50)
        .padding(.vertical, 10)
        .roundedBorder(0,0)
        .padding(.top, isPasswordEmpty ? 0 : 10)
    }
}

struct BottomButtonView: View{
    
    @ObservedObject var flowManager = LoginFlowManager.shared
    @Inject var loginAuthProvider: LoginAuthProvider
    @State var isProcessing : Bool = false
    @Binding var username : String
    @Binding var password : String
    @Binding var errorMessage : String?
    @Binding var uiViewColor: Color?
    @Binding var isEmailValid: Bool
    @Binding var isPasswordValid : Bool
    @Binding var isPasswordEmpty : Bool
    var userState : UserState
    var width : Double
    var heignt: Double
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        VStack(spacing: 0){
            VStack{
                
                    Button(action: {
                        buttonTapped()
                    }, label: {
                        Text(userState.rawValue.localized())
                            .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.title3.size))
                            .foregroundColor(.white)
                        + Text(" >")
                            .font(Font.custom(CustomFontWeight.bold.fontName, size: CustomFontStyle.title2.size))
                            .foregroundColor(.white)
                    })
                }
            .frame(width: width, height: heignt)
            .padding(.bottom, 0)
            .padding(.bottom, 10)
            .background(Color.main)
            .opacity(isProcessing ? 0.5 : 1)
            .addAccessibility(text: "%1 Button, Double tap to activate".localized(userState.rawValue))
            .accessibilityAction {
                buttonTapped()
            }
            HStack {
                Spacer()
            }.frame(height: ScreenSize.safeBottom())
                .background(Color.main)
        }
    }
    
    /// Button tapped
    /// Button tapped.
    func buttonTapped() {
            if username == "" && password == "" && username.isEmpty && password.isEmpty{
                errorMessage = "Email and password must be valid or must not empty"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    UIAccessibility.post(notification: .announcement, argument: "Email and password must be valid or must not empty".localized())
                })
            }
            else if username == "" && username.isEmpty {
                isEmailValid = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    UIAccessibility.post(notification: .announcement, argument: "Must be a valid email address".localized())
                })
            } else if userState != .resetPassword && password == "" && password.isEmpty {
                isPasswordEmpty = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    UIAccessibility.post(notification: .announcement, argument: "Password can't be empty".localized())
                })
            } else if userState == .signup && !isPasswordValid {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    UIAccessibility.post(notification: .announcement, argument: "Password must be valid".localized())
                })
            }
            else if isEmailValid && isPasswordValid && !isPasswordEmpty{
                isProcessing = true
                if !Env.shared.isNetworkConnected {
                    errorMessage = "No Internet Connection".localized()
                    isProcessing = false
                    return
                }
                switch userState {
                case .login:
                    loginAuthProvider.getAuth0AccessToken(username: username, password: password) { success, errMessge, _ in
                        if success{
                            loginAuthProvider.getUserInfo {
                                isProcessing = false
                                DispatchQueue.main.async {
                                    TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
									TabBarMenuManager.shared.configureTabs(isLoggedIn: true)
                                    LoginFlowManager.shared.pubPresentLoginPage = false
                                }
                            }
                        }else{
                            isProcessing = false
                            
                            errorMessage = errMessge
                        }
                    }
                    isProcessing = false
                case .signup:
                    isProcessing = false
                    loginAuthProvider.signUpAuth0(username: username, password: password) { success, errMessage, _ in
                        if success{
                            loginAuthProvider.getAuth0AccessToken(username: username, password: password) { success, errString, token in
                                if success{
                                    loginAuthProvider.getUserInfo {
                                        isProcessing = false
                                        DispatchQueue.main.async {
                                            TabBarMenuManager.shared.seletedTab = TabBarItem(type: TabBarMenuManager.shared.previousItemTab)
											TabBarMenuManager.shared.configureTabs(isLoggedIn: true)
                                        }
                                    }
                                }
                            }
                        }else{
                            isProcessing = false
                            errorMessage = errMessage
                        }

                    }
                case .resetPassword:
                    loginAuthProvider.resetPassword(username: username) { success, errMessage, responseMessage in
                        if success{
                            isProcessing = false
                            uiViewColor = .green
                            errorMessage = responseMessage
                        }else{
                            isProcessing = false
                            errorMessage = errMessage
                        }
                    }
                }
            }
            else{
                switch userState {
                case .login: errorMessage = "Please Enter valid Credentials".localized()
                case .signup: errorMessage = "Please Enter valid Credentials".localized()
                case.resetPassword: errorMessage = "Must be a valid email address".localized()
                }
            }
        
    }
    
}

struct LoginSignUpView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        LoginSignUpView(username: "", password: "")
    }
}
