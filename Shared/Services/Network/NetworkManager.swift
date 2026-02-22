//
//  NetworkManager.swift
//

import Foundation

/// Manages URLSession configuration and lifecycle for network requests.
///
/// This singleton class provides centralized management of URLSession instances
/// with configurable timeout values, connection limits, and caching policies.
/// It serves as the foundation for all network communication in the app.
///
/// The default configuration includes:
/// - Request timeout: 120 seconds
/// - Resource timeout: 300 seconds
/// - Waits for connectivity when network is unavailable
/// - Maximum connections per host: 4
/// - No caching (always fetches fresh data)
///
/// Example:
/// ```swift
/// let session = NetworkManager.shared.session
/// session.dataTaskPublisher(for: request)
///     .sink { completion in
///         // Handle completion
///     } receiveValue: { data, response in
///         // Handle response
///     }
/// ```
public class NetworkManager {
    /// The URLSession instance used for all network requests.
    ///
    /// This session is configured with the default or custom configuration
    /// and should be used for all data tasks in the app.
    public var session: URLSession

    /// The current URLSession configuration.
    ///
    /// This configuration defines timeout values, caching policies,
    /// and connection limits for the session.
    private var configuration: URLSessionConfiguration

    /// Shared singleton instance of NetworkManager.
    ///
    /// Use this instance throughout the app to ensure consistent
    /// network configuration and session management.
    public static let shared = NetworkManager()

    /// Initializes a new NetworkManager with default configuration.
    ///
    /// The default configuration includes:
    /// - Request timeout from NetworkConstants
    /// - Resource timeout from NetworkConstants
    /// - Waits for connectivity
    /// - Maximum connections per host from NetworkConstants
    /// - No caching policy
    public init() {
        configuration = NetworkManager.defaultConfig()
        session = URLSession(configuration: configuration)
    }

    /// Resets the URLSession to use the default configuration.
    ///
    /// Call this method to restore the default network configuration
    /// after using a custom configuration. This recreates the URLSession
    /// with default timeout values and policies.
    public func resetConfiguration() {
        setupDefaultConfig()
    }

    /// Sets up the default URLSession configuration.
    ///
    /// This private method creates a new URLSession with the default
    /// configuration and replaces the current session.
    private func setupDefaultConfig() {
        configuration = NetworkManager.defaultConfig()
        session = URLSession(configuration: configuration)
    }
}

public extension NetworkManager {
    /// Creates and returns the default URLSession configuration.
    ///
    /// This configuration is optimized for the app's network requirements:
    /// - **Request Timeout**: Time to wait for initial response (from NetworkConstants)
    /// - **Resource Timeout**: Total time allowed for entire request (from NetworkConstants)
    /// - **Waits for Connectivity**: Automatically retries when network becomes available
    /// - **Max Connections**: Limits concurrent connections per host (from NetworkConstants)
    /// - **Cache Policy**: Disabled to always fetch fresh data
    ///
    /// - Returns: A configured URLSessionConfiguration with app-specific settings
    ///
    /// Example:
    /// ```swift
    /// let config = NetworkManager.defaultConfig()
    /// let customSession = URLSession(configuration: config)
    /// ```
    static func defaultConfig() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NetworkConstants.requestTimeout
        configuration.timeoutIntervalForResource = NetworkConstants.resourceTimeout
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = NetworkConstants.httpMaximumConnections
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = .none
        return configuration
    }

    /// Replaces the current URLSession with one using a custom configuration.
    ///
    /// Use this method when you need to temporarily change network settings
    /// for specific requests. Call `resetConfiguration()` to restore defaults.
    ///
    /// - Parameter config: The custom URLSessionConfiguration to use
    ///
    /// Example:
    /// ```swift
    /// let customConfig = URLSessionConfiguration.default
    /// customConfig.timeoutIntervalForRequest = 60
    /// NetworkManager.shared.setupCustomConfig(customConfig)
    /// // Make requests with custom config
    /// NetworkManager.shared.resetConfiguration() // Restore defaults
    /// ```
    func setupCustomConfig(_ config: URLSessionConfiguration) {
        session = URLSession(configuration: config)
    }
}
