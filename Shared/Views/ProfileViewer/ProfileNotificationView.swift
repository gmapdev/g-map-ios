//
//  ProfileNotificationView.swift
//

import Foundation
import SwiftUI
import Combine

struct ProfileNotificationView: View {
    var title = "Notification preferences:"
    var spacing: CGFloat = 20
    
    @ObservedObject var session = AppSession.shared
    @ObservedObject var profileManager = ProfileManager.shared
    
    @State var pageLastUpdated = Date().timeIntervalSince1970
    
    @State var verificationCode = ""
    @State var enableChangePhoneNumber = false
    
    @Inject var notificationProvider: NotificationProvider
    var sendTextCallBack: (() -> Void)?
    var changeNumberCallBack: (() -> Void)?
    
    /// Title:  string = " notification preferences:", spacing: c g float = 20, send text call back: (() ->  void)? = nil, change number call back: (() ->  void)? = nil
    /// Initializes a new instance.
    /// - Parameters:
    ///   - title: String = "Notification preferences:"
    ///   - spacing: CGFloat = 20
    ///   - sendTextCallBack: ((
    /// - Returns: Void)? = nil, changeNumberCallBack: (() -> Void)? = nil)
    init(title: String = "Notification preferences:", spacing:CGFloat = 20, sendTextCallBack: (() -> Void)? = nil, changeNumberCallBack: (() -> Void)? = nil) {
        
        self.title = title
        self.spacing = spacing
        self.sendTextCallBack = sendTextCallBack
        self.changeNumberCallBack = changeNumberCallBack
        
        //this changes the "thumb" that selects between items
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.main
        //and this changes the color for the whole "bar" background
        UISegmentedControl.appearance().backgroundColor = .white
        
        //this will change the font size
        UISegmentedControl.appearance().setTitleTextAttributes([.font : UIFont.preferredFont(forTextStyle: .largeTitle)], for: .normal)
        
        //these lines change the text color for various states
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.black], for: .normal)
    }
    
    /// Get available notification methods.
    /// - Parameters:
    ///   - configString: Parameter description
    /// - Returns: [String]
    func getAvailableNotificationMethods(configString: String) -> [String] {
        let array = configString.components(separatedBy: ",")
        return array
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let phoneIsVerified = (AppSession.shared.loginInfo?.phoneVerified ?? false)
        let loginEmail = AppSession.shared.loginInfo?.email ?? "Not Available"
        let pushDevices = AppSession.shared.loginInfo?.pushDevices ?? 0
        let availableMethods = getAvailableNotificationMethods(configString: FeatureConfig.shared.available_notification_methods)
        let checkBoxSize = AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize()/2 : 20
        return VStack{
            Spacer().frame(height:self.spacing)
            VStack{
                HStack{
                    TextLabel(title, .bold, .title2).foregroundColor(Color.black)
                    Spacer()
                }.padding(.bottom, 5)
				.onTapGesture {
					UIApplication.shared.dismissKeyboard()
				}
                
                HStack{
                    TextLabel("You can receive notifications about trips you frequently take.".localized(), .bold, .subheadline).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(.bottom, 5)
				.onTapGesture {
					UIApplication.shared.dismissKeyboard()
				}
                
                HStack{
                    TextLabel("How would you like to receive notifications?".localized(), .bold, .subheadline).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
				.onTapGesture {
					UIApplication.shared.dismissKeyboard()
				}
                /*
                HStack{
                    GeometryReader { geo in
                        Picker(selection: self.$profileManager.pubNotificationTypeIndex, label:TextLabel("How would you like to receive notifications?".localized())){
                            TextLabel("Email".localized()).tag(0)
                            TextLabel("SMS".localized()).tag(1)
                            TextLabel("Don't notify me".localized()).lineLimit(nil).fixedSize(horizontal: false, vertical: true).tag(2)
                        }
                        .frame(width: geo.size.width, height:60)
                        .pickerStyle(SegmentedPickerStyle())
                        .scaledToFit()
                        .scaleEffect(CGSize(width: 1, height: 1.1))
                    }
                }.padding(.bottom, 50)
                */
                VStack {
                    if availableMethods.contains("Email") {
                        HStack {
                            CheckBoxView(isChecked: profileManager.isEmailOpen, title: "Email", icon: "", checboxSize: checkBoxSize) {
                                profileManager.isEmailOpen.toggle()
                                if profileManager.isEmailOpen {
                                    appendString(value: "email")
                                } else {
                                    removeString(value: "email")
                                }
                            }
                        }
                        if profileManager.isEmailOpen {
                            Spacer().frame(height: 10)
							HStack{
								Spacer().frame(width:30)
								VStack{
									HStack{
										TextLabel("Notification emails will be sent to:".localized(), .bold, .body).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
										Spacer()
									}
									
									HStack{
										TextLabel(loginEmail).font(.body).lineLimit(nil).foregroundColor(Color.black)
										Spacer()
									}
								}
							}
                            Spacer().frame(height: 10)
                        }
                    }
                    if availableMethods.contains("SMS") {
                        CheckBoxView(isChecked: profileManager.isSMSOpen, title: "SMS", icon: "", checboxSize: checkBoxSize) {
                            profileManager.isSMSOpen.toggle()
                            if profileManager.isSMSOpen {
                                appendString(value: "sms")
                            } else {
                                removeString(value: "sms")
                            }
                        }
                        if profileManager.isSMSOpen {
                            Spacer().frame(height: 10)
							HStack{
								Spacer().frame(width:30)
								VStack{
									if !enableChangePhoneNumber && (AppSession.shared.loginInfo?.phoneNumber ?? "").count > 0 {
										
										HStack{
											TextLabel("SMS notifications will be sent to:".localized(), .bold, .body).lineLimit(nil).foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
											Spacer()
										}
										if phoneIsVerified{
											if AccessibilityManager.shared.pubIsLargeFontSize {
												VStack(alignment: .leading, spacing: 10){
                                                    TextLabel(AppSession.shared.loginInfo?.phoneNumber ?? "", .regular ,.subheadline)
                                                        .lineLimit(nil)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
                                                        .foregroundColor(Color.black)
													TextLabel( phoneIsVerified ? "Verified".localized() : "Pending".localized(), .bold, .subheadline)
                                                        
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
														.padding(3).background(phoneIsVerified ? Color.green : Color.orange)
														.foregroundColor(Color.white)
                                                        /// Corner radius: 5)
                                                        /// Initializes a new instance.
                                                        /// - Parameters:

                                                        ///   - RoundedRectangle.init(cornerRadius: 5
                                                        .clipShape(RoundedRectangle.init(cornerRadius: 5))
													Button(action: {
														self.enableChangePhoneNumber = true
														changeNumberCallBack?()
													}, label: {
														HStack{
															TextLabel("Change number".localized()).font(.subheadline)
																.fixedSize(horizontal: false, vertical: true)
														}
              /// Corner radius: 10)
              /// Initializes a new instance.
              /// - Parameters:

              ///   - RoundedRectangle.init(cornerRadius: 10
														.clipShape(RoundedRectangle.init(cornerRadius: 10))
													}).roundedBorder()
												}.padding(.vertical, 15)
											} else {
												HStack{
													TextLabel(AppSession.shared.loginInfo?.phoneNumber ?? "", .regular, .subheadline)
                                                        .lineLimit(nil)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
                                                        .foregroundColor(Color.black)
													TextLabel( phoneIsVerified ? "Verified".localized() : "Pending".localized(), .bold, .subheadline)
                                                        
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
                                                        .padding(3)
                                                        .background(phoneIsVerified ? Color.green : Color.orange)
                                                        .foregroundColor(Color.white)
                                                        /// Corner radius: 5)
                                                        /// Initializes a new instance.
                                                        /// - Parameters:

                                                        ///   - RoundedRectangle.init(cornerRadius: 5
                                                        .clipShape(RoundedRectangle.init(cornerRadius: 5))
													Spacer()
													Button(action: {
														self.enableChangePhoneNumber = true
														changeNumberCallBack?()
													}, label: {
														HStack{
															TextLabel("Change number".localized()).font(.subheadline)
																.fixedSize(horizontal: false, vertical: true)
														}
              /// Corner radius: 10)
              /// Initializes a new instance.
              /// - Parameters:

              ///   - RoundedRectangle.init(cornerRadius: 10
														.clipShape(RoundedRectangle.init(cornerRadius: 10))
													}).roundedBorder()
												}.padding(.vertical, 15)
											}
										}
										else {
											if AccessibilityManager.shared.pubIsLargeFontSize {
												VStack(alignment: .leading, spacing: 10){
													TextLabel(AppSession.shared.loginInfo?.phoneNumber ?? "", .regular, .subheadline)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .foregroundColor(Color.black)
                                                    TextLabel( phoneIsVerified ? "Verified".localized() : "Pending".localized(), .bold, .subheadline)
                                                        
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
														.padding(3)
                                                        .background(phoneIsVerified ? Color.green : Color.orange)
														.foregroundColor(Color.white)
                                                        /// Corner radius: 5)
                                                        /// Initializes a new instance.
                                                        /// - Parameters:

                                                        ///   - RoundedRectangle.init(cornerRadius: 5
                                                        .clipShape(RoundedRectangle.init(cornerRadius: 5))
													Button(action: {
														self.enableChangePhoneNumber = true
														changeNumberCallBack?()
													}, label: {
														HStack{
															TextLabel("Change number".localized()).font(.subheadline)
																.fixedSize(horizontal: false, vertical: true)
														}
              /// Corner radius: 10)
              /// Initializes a new instance.
              /// - Parameters:

              ///   - RoundedRectangle.init(cornerRadius: 10
														.clipShape(RoundedRectangle.init(cornerRadius: 10))
													}).roundedBorder()
												}.padding(.vertical, 15)
											} else {
												HStack{
													TextLabel(AppSession.shared.loginInfo?.phoneNumber ?? "", .regular, .subheadline)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(nil)
                                                        .foregroundColor(Color.black)
													TextLabel( phoneIsVerified ? "Verified".localized() : "Pending".localized(), .bold, .subheadline)
                                                        
                                                        .fixedSize(horizontal: false, vertical: true)
                                                        .multilineTextAlignment(.leading)
														.padding(3)
                                                        .background(phoneIsVerified ? Color.green : Color.orange)
														.foregroundColor(Color.white)
                                                        /// Corner radius: 5)
                                                        /// Initializes a new instance.
                                                        /// - Parameters:

                                                        ///   - RoundedRectangle.init(cornerRadius: 5
                                                        .clipShape(RoundedRectangle.init(cornerRadius: 5))
													Spacer()
													Button(action: {
														self.enableChangePhoneNumber = true
														changeNumberCallBack?()
													}, label: {
														HStack{
															TextLabel("Change number".localized()).font(.subheadline)
																.fixedSize(horizontal: false, vertical: true)
														}
              /// Corner radius: 10)
              /// Initializes a new instance.
              /// - Parameters:

              ///   - RoundedRectangle.init(cornerRadius: 10
														.clipShape(RoundedRectangle.init(cornerRadius: 10))
													}).roundedBorder()
												}.padding(.vertical, 15)
											}
											
											TextLabel("Please check the SMS messaging app on your mobile phone for a text message with a verification code, and enter the code below (code expires after 10 minutes).".localized()).font(.body).lineLimit(nil).foregroundColor(Color.black)
												.fixedSize(horizontal: false, vertical: true)
											if AccessibilityManager.shared.pubIsLargeFontSize {
												verificationCodeViewAODA
											} else {
												verificationCodeView
											}
											HStack{
												Button(action:{
													self.notificationProvider.sendSMSVerificationCode(phonenumber: Helper.shared.unmaskPhoneNumber(self.profileManager.pubNotificationPhoneNumber)) { success, errorMessage in
														if success {
															AppSession.shared.loginInfo?.phoneNumber = self.profileManager.pubNotificationPhoneNumber
															AlertManager.shared.presentAlert(message: "Verification code has been sent, Please check".localized())
														}else{
															AlertManager.shared.presentAlert(message: "Failed to request a new code for the phone number".localized())
														}
													}
												}, label:{
													TextLabel("Request a new code".localized()).font(.subheadline)
												})
												Spacer()
											}
										}
									}
									else{
										HStack{
                                            TextLabel("Enter your phone number for SMS notifications:".localized(), .bold, .body).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
												.foregroundColor(Color.black)
											Spacer()
                                        }.padding(.bottom, 5)
										AutoHeightTextField(text: self.$profileManager.pubNotificationPhoneNumber, placeholder: "Enter your phone number".localized(), keyboradType: .numberPad,
															onValueChange: { newValue in
											if let newValue = newValue {
												profileManager.pubNotificationPhoneNumber = Helper.shared.formatPhoneNumber(newValue)
											}
										}, onTapTrigger: {
											changeNumberCallBack?()
										})
										.roundedBorder(0,0)
										.onAppear(perform: {profileManager.pubValidPhoneNumberLimit = true})
										
										if !self.profileManager.pubValidPhoneNumberLimit {
											HStack{
												TextLabel("Please enter a valid phone number.".localized(), .bold, .subheadline)
													.foregroundColor(Color.redForeground).lineLimit(nil)
													.foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
												Spacer()
											}
										}
										if AccessibilityManager.shared.pubIsLargeFontSize {
											VStack{
												Button(action: {
													Helper.shared.validatePhoneNumber(profileManager.pubNotificationPhoneNumber)
													if self.profileManager.pubValidPhoneNumberLimit {
														self.enableChangePhoneNumber = false
														self.notificationProvider.sendSMSVerificationCode(phonenumber: Helper.shared.unmaskPhoneNumber(self.profileManager.pubNotificationPhoneNumber)) { success, errorMessage in
															if success {
																AppSession.shared.loginInfo?.phoneVerified = false
																profileManager.pubLastTripListUpdate = Date().timeIntervalSince1970
																sendTextCallBack?()
																AppSession.shared.loginInfo?.phoneNumber = self.profileManager.pubNotificationPhoneNumber
																AlertManager.shared.presentAlert(message: "Verification code has been sent, please check".localized())
															}else{
																AlertManager.shared.presentAlert(message: "Failed to request a new code for the phone number".localized())
															}
														}
													}
												}, label: {
													HStack{
														Spacer()
														TextLabel("Send verification text".localized(), .regular, .body).padding(10)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                            .multilineTextAlignment(.leading)
														Spacer()
													}
													.background(self.profileManager.pubNotificationPhoneNumber.isEmpty ? Color.gray_main : Color.main)
													.foregroundColor(Color.white)
             /// Corner radius: 10)
             /// Initializes a new instance.
             /// - Parameters:

             ///   - RoundedRectangle.init(cornerRadius: 10
													.clipShape(RoundedRectangle.init(cornerRadius: 10))
												})
												Spacer().frame(height: 10)
												Button(action: {
													self.enableChangePhoneNumber = false
												}, label: {
													HStack{
														Spacer()
														TextLabel("Cancel".localized(), .regular, .body).padding(10)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                            .multilineTextAlignment(.leading)
														Spacer()
													}
             /// Hex: "#eeeeee")
             /// Initializes a new instance.
             /// - Parameters:

             ///   - Color.init(hex: "#eeeeee"
													.background(Color.init(hex: "#eeeeee"))
             /// Corner radius: 10)
             /// Initializes a new instance.
             /// - Parameters:

             ///   - RoundedRectangle.init(cornerRadius: 10
													.clipShape(RoundedRectangle.init(cornerRadius: 10))
												})
											}
											.padding(.top, 5)
											.padding(.bottom, 10)
										} else {
											HStack{
												Button(action: {
													Helper.shared.validatePhoneNumber(profileManager.pubNotificationPhoneNumber)
													if self.profileManager.pubValidPhoneNumberLimit {
														self.enableChangePhoneNumber = false
														self.notificationProvider.sendSMSVerificationCode(phonenumber: Helper.shared.unmaskPhoneNumber(self.profileManager.pubNotificationPhoneNumber)) { success, errorMessage in
															if success {
																AppSession.shared.loginInfo?.phoneVerified = false
																profileManager.pubLastTripListUpdate = Date().timeIntervalSince1970
																sendTextCallBack?()
																AppSession.shared.loginInfo?.phoneNumber = self.profileManager.pubNotificationPhoneNumber
																AlertManager.shared.presentAlert(message: "Verification code has been sent, please check".localized())
															}else{
																AlertManager.shared.presentAlert(message: "Failed to request a new code for the phone number".localized())
															}
														}
													}
												}, label: {
													HStack{
														Spacer()
														TextLabel("Send verification text".localized()).padding(10)
															.font(.body)
														Spacer()
													}
													.background(self.profileManager.pubNotificationPhoneNumber.isEmpty ? Color.gray_main : Color.main)
													.foregroundColor(Color.white)
             /// Corner radius: 10)
             /// Initializes a new instance.
             /// - Parameters:

             ///   - RoundedRectangle.init(cornerRadius: 10
													.clipShape(RoundedRectangle.init(cornerRadius: 10))
												})
												Spacer()
												Button(action: {
													self.enableChangePhoneNumber = false
												}, label: {
													HStack{
														TextLabel("Cancel".localized()).padding(10)
															.font(.body)
													}
             /// Hex: "#eeeeee")
             /// Initializes a new instance.
             /// - Parameters:

             ///   - Color.init(hex: "#eeeeee"
													.background(Color.init(hex: "#eeeeee"))
             /// Corner radius: 10)
             /// Initializes a new instance.
             /// - Parameters:

             ///   - RoundedRectangle.init(cornerRadius: 10
													.clipShape(RoundedRectangle.init(cornerRadius: 10))
												})
											}
											.padding(.top, 5)
											.padding(.bottom, 10)
										}
                                        HStack{
                                            TextLabel("By providing your phone number, you agree to receive verification and trip monitoring SMS messages. Additional costs from your phone carrier may apply.".localized(), .bold, .subheadline)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer()
                                        }
									}
								}
							}
                            Spacer().frame(height: 10)
                        }
                    }
                    if availableMethods.contains("PushNotification") {
                        CheckBoxView(isChecked: profileManager.isPushNotificationOpen, title: "Push Notification", icon: "", checboxSize: checkBoxSize) {
                            profileManager.isPushNotificationOpen.toggle()
                            if profileManager.isPushNotificationOpen {
                                appendString(value: "push")
                            } else {
                                removeString(value: "push")
                            }
                        }
                        if profileManager.isPushNotificationOpen {
                            HStack{
                                Spacer().frame(width:30)
                                TextLabel("\(pushDevices) \(pushDevices > 1 ?"devices".localized() : "device".localized()) \("registered".localized())", .regular, .subheadline)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                    if availableMethods.contains("HapticFeedback") {
                        CheckBoxView(isChecked: profileManager.isHapticFeedbackOpen, title: "Haptic Feedback", icon: "", checboxSize: checkBoxSize) {
                            profileManager.isHapticFeedbackOpen.toggle()
                            if profileManager.isHapticFeedbackOpen {
                                appendString(value: "haptic")
                            } else {
                                removeString(value: "haptic")
                            }
                        }
                    }
                }
                .onTapGesture {
                    UIApplication.shared.dismissKeyboard()
                }
				.onTapGesture {
					UIApplication.shared.dismissKeyboard()
				}
				
            }.padding(spacing)
        }
    }
    
    /// Append string.
    /// - Parameters:
    ///   - value: Parameter description
    func appendString(value: String) {
        profileManager.pubNotificationType.append(value)
        AppSession.shared.loginInfo?.notificationChannel = profileManager.pubNotificationType.joined(separator: ",")
    }
    
    /// Remove string.
    /// - Parameters:
    ///   - value: Parameter description
    /// Removes string.
    func removeString(value: String){
        profileManager.pubNotificationType = profileManager.pubNotificationType.filter({$0 != value})
        AppSession.shared.loginInfo?.notificationChannel = profileManager.pubNotificationType.joined(separator: ",")
    }
    
    /// Verification code view.
    /// - Parameters:
    ///   - some: Parameter description
    var verificationCodeView: some View {
        VStack {
            HStack{
                TextLabel("Verification code:".localized(), .bold, .body).lineLimit(nil).foregroundColor(Color.black)
                Spacer()
            }.padding(.top, 10)
            HStack{
                TextField("123456", text: self.$verificationCode).frame(height: 30).padding(5).border(Color.gray, width: 1).id(102)
                    .keyboardType(.numberPad)
                    .onTapGesture {
                        sendTextCallBack?()
                    }
                Button(action: {
                    self.notificationProvider.verifySMSCode(smsCode: self.verificationCode){ success, status, errorMessage in
                        if success {
                            if status == "approved" {
                                UIApplication.shared.dismissKeyboard()
                                AppSession.shared.loginInfo?.phoneVerified = true
                                DispatchQueue.main.async {
                                    profileManager.pubLastTripListUpdate = Date().timeIntervalSince1970
                                }
                            }else{
                                AlertManager.shared.presentAlert(message: "Failed to verify, Invalid verification code")
                            }
                        }else{
                            AlertManager.shared.presentAlert(message: "Failed to verify the code for the phone number. \(errorMessage ?? "")")
                        }
                    }
                }, label: {
                    HStack{
                        TextLabel("Verify".localized()).padding(10)
                    }
                    .background(Color.main)
                    .foregroundColor(Color.white)
                    /// Corner radius: 10)
                    /// Initializes a new instance.
                    /// - Parameters:

                    ///   - RoundedRectangle.init(cornerRadius: 10
                    .clipShape(RoundedRectangle.init(cornerRadius: 10))
                })
            }
        }
        .id(80)
    }
    
    /// Verification code view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var verificationCodeViewAODA: some View {
        VStack {
            HStack{
                TextLabel("Verification code:".localized(), .bold, .body).lineLimit(nil).foregroundColor(Color.black)
                Spacer()
            }.padding(.top, 10)
            VStack(alignment: .leading){
                TextField("123456", text: self.$verificationCode).padding(5).border(Color.gray, width: 1).id(102)
                    .keyboardType(.numberPad)
                    .onTapGesture {
                        sendTextCallBack?()
                    }
                HStack {
                    Button(action: {
                        self.notificationProvider.verifySMSCode(smsCode: self.verificationCode){ success, status, errorMessage in
                            if success {
                                if status == "approved" {
                                    UIApplication.shared.dismissKeyboard()
                                    AppSession.shared.loginInfo?.phoneVerified = true
                                    DispatchQueue.main.async {
                                        profileManager.pubLastTripListUpdate = Date().timeIntervalSince1970
                                    }
                                }else{
                                    AlertManager.shared.presentAlert(message: "Failed to verify, Invalid verification code")
                                }
                            }else{
                                AlertManager.shared.presentAlert(message: "Failed to verify the code for the phone number. \(errorMessage ?? "")")
                            }
                        }
                    }, label: {
                        HStack{
                            TextLabel("Verify".localized()).padding(10)
                        }
                        .background(Color.main)
                        .foregroundColor(Color.white)
                        /// Corner radius: 10)
                        /// Initializes a new instance.
                        /// - Parameters:

                        ///   - RoundedRectangle.init(cornerRadius: 10
                        .clipShape(RoundedRectangle.init(cornerRadius: 10))
                    })
                    Spacer()
                }
            }
        }
        .id(80)
    }
}

public struct ProfileNotificationView_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    public static var previews: some View {
        ProfileNotificationView()
    }
}
