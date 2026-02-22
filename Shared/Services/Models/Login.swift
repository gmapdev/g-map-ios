//
//  Login.swift
//

import Foundation

// MARK: - This file will hold of all the Structure used in Auth0 & login flow


enum StoredValueKeys: String{
    case accessToken = "temp_A1"
    case username = "temp_A2"
    case password = "temp_A3"
    case expireIn = "temp_A4"
}

// MARK: - Token
struct Token: Codable {
    let accessToken, idToken, scope: String?
    let expiresIn: Int?
    let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case scope
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - AuthUserInfo

public struct AuthUserInfo: Codable {
    let sub : String
    let nickname, name: String?
    let picture: String?
    let updatedAt, email: String?
    let phoneNumber: String?
    let phoneNumberVerified: Bool?
    let emailVerified: Bool?

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case phoneNumber = "phone_number"
        case phoneNumberVerified = "phone_number_verified"
        case emailVerified = "email_verified"
        case sub, nickname, name, picture, email
    }
}

// MARK: - SignupResponse
struct SignupResponse: Codable {
    let id: String
    let emailVerified: Bool
    let email: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case emailVerified = "email_verified"
        case email
    }
}


