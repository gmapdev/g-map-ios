//
//  LoginSignUpModel.swift
//

import Foundation

enum PasswordMatchingConditions: String {
    case passwordValid = "Password is valid"
    case eightChar = "At least 8 characters"
    case followingThree = "At least 3 of the following:"
    case lowerCase = "Lower case letters (a-z)"
    case upperCase = "Upper case letters (A-Z)"
    case numbers = "Numbers (0-9)"
    case specialChar = "Special characters (e.g. !@#$%^&*)"
}

class LoginSignUpModel: ObservableObject {
    
    @Published var passwordConditions: [PasswordMatchingConditions] = []
    
    /// Shared.
    /// - Parameters:
    ///   - LoginSignUpModel: Parameter description
    static var shared: LoginSignUpModel = {
        let model = LoginSignUpModel()
        return model
    }()
    
    /// Check regex conditions.
    /// - Parameters:
    ///   - inputText: Parameter description
    /// Checks regex conditions.
    func checkRegexConditions(inputText: String) {
        let regex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*]).{8,}$"
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        
        var conditionsMatched: [PasswordMatchingConditions] = []
        var subConditionsMatched: [PasswordMatchingConditions] = []
        
        if predicate.evaluate(with: inputText) {
            conditionsMatched.append(.passwordValid)
        }
            
            if let lowerString = Helper.shared.extractSubstring(inputText, regex: "([a-z])"), !lowerString.isEmpty {
                conditionsMatched.append(.lowerCase)
                subConditionsMatched.append(.lowerCase)
            }
            if let upperString = Helper.shared.extractSubstring(inputText, regex: "([A-Z])"), !upperString.isEmpty {
                conditionsMatched.append(.upperCase)
                subConditionsMatched.append(.upperCase)
            }
            if let numberString = Helper.shared.extractSubstring(inputText, regex: "([0-9])"), !numberString.isEmpty {
                conditionsMatched.append(.numbers)
                subConditionsMatched.append(.numbers)
            }
            if let cahrString = Helper.shared.extractSubstring(inputText, regex: "([!@#$%^&*])"), !cahrString.isEmpty {
                conditionsMatched.append(.specialChar)
                subConditionsMatched.append(.specialChar)
            }
            
            if (inputText.count >= 8) {
                conditionsMatched.append(.eightChar)
            }
            
            if subConditionsMatched.count >= 3 {
                conditionsMatched.append(.followingThree)
            }
        
        passwordConditions = conditionsMatched
    }
}
