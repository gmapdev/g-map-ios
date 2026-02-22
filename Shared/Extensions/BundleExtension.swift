//
//  BundleExtension.swift
//

import Foundation

extension Bundle {

    /// Short version.
    /// - Parameters:
    ///   - String: Parameter description
    var shortVersion: String {
        if let result = infoDictionary?["CFBundleShortVersionString"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    /// Build version.
    /// - Parameters:
    ///   - String: Parameter description
    var buildVersion: String {
        if let result = infoDictionary?["CFBundleVersion"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    /// Full version.
    /// - Parameters:
    ///   - String: Parameter description
    var fullVersion: String {
        return "\(shortVersion)(\(buildVersion))"
    }
}
