//
//  ServiceContainer.swift
//

import Foundation
import SwiftUI

/// Represents a service provider in the dependency injection container.
///
/// A ServiceProvider encapsulates the creation logic for a service instance.
/// It stores the service type name and a factory closure that creates instances
/// on demand.
///
/// Example:
/// ```swift
/// let provider = ServiceProvider { MyService() }
/// ```
public struct ServiceProvider {
	/// The name/identifier of the service (typically the type name)
	fileprivate let name: String

	/// Factory closure that creates service instances
	fileprivate let build: () -> Any

	/// Creates a new service provider with a factory closure.
	///
	/// - Parameters:
	///   - name: Optional custom name for the service. If nil, uses the type name.
	///   - build: Factory closure that creates instances of type T
	///
	/// Example:
	/// ```swift
	/// ServiceProvider { LoginAuthProvider() }
	/// ServiceProvider("CustomAuth") { CustomAuthProvider() }
	/// ```
	public init<T>(_ name: String? = nil, _ build: @escaping () -> T){
		self.name = name ?? String(describing: T.self)
		self.build = build
	}
}

/// Dependency injection container for managing service providers.
///
/// ServiceContainer implements the Service Locator pattern, providing centralized
/// management of service instances throughout the app. It supports:
/// - Type-safe service resolution
/// - Result builder syntax for declarative configuration
/// - Lazy service instantiation
/// - Named service registration
///
/// Architecture:
/// ```
/// ServiceContainer
///   ├── ServiceProvider (Auth)
///   ├── ServiceProvider (API)
///   └── ServiceProvider (Database)
/// ```
///
/// Example:
/// ```swift
/// let container = ServiceContainer {
///     ServiceProvider { AuthService() }
///     ServiceProvider { APIService() }
///     ServiceProvider { DatabaseService() }
/// }
///
/// // Resolve services
/// let authService: AuthService = container.resolve()
/// ```
open class ServiceContainer {

	/// Dictionary storing registered service providers by name
	private var services = [String: ServiceProvider]()

	/// Shared singleton instance of ServiceContainer.
	///
	/// - Note: In most cases, use `AppSession.shared.serviceContainer` instead,
	///   which is pre-configured with all app services.
	public static var shared: ServiceContainer = {
		let instance = ServiceContainer()
		return instance
	}()

	/// Creates a container with multiple service providers using result builder syntax.
	///
	/// This is the recommended initializer for configuring multiple services
	/// in a declarative way.
	///
	/// - Parameter providers: A closure that returns an array of ServiceProviders
	///
	/// Example:
	/// ```swift
	/// let container = ServiceContainer {
	///     ServiceProvider { AuthService() }
	///     ServiceProvider { APIService() }
	///     ServiceProvider { DatabaseService() }
	/// }
	/// ```
	public init(@ServiceBuilder _ providers: () -> [ServiceProvider] ) {
		providers().forEach { services[$0.name] = $0 }
	}

	/// Creates a container with a single service provider.
	///
	/// Use this initializer when registering only one service.
	///
	/// - Parameter provider: A closure that returns a ServiceProvider
	///
	/// Example:
	/// ```swift
	/// let container = ServiceContainer {
	///     ServiceProvider { AuthService() }
	/// }
	/// ```
	public init(@ServiceBuilder _ provider: () -> ServiceProvider) {
		let service = provider()
		services[service.name] = service
	}

	/// Creates an empty container.
	///
	/// Services can be registered later using other methods.
	public init() {}

	/// Cleans up all registered services when the container is deallocated.
	deinit {
		services.removeAll()
	}

	/// Resolves and returns a service instance of the specified type.
	///
	/// This method looks up the service provider by type name and creates
	/// an instance using the registered factory closure.
	///
	/// - Parameter name: Optional custom name for the service. If nil, uses the type name.
	/// - Returns: An instance of the requested service type
	///
	/// - Important: This method will crash with a fatal error if the service
	///   is not registered. Ensure all required services are registered before
	///   attempting to resolve them.
	///
	/// Example:
	/// ```swift
	/// let authService: LoginAuthProvider = container.resolve()
	/// let customService: MyService = container.resolve(for: "CustomName")
	/// ```
	func resolve<T>(for name: String? = nil) -> T{
		let name = name ?? String(describing: T.self)
		guard let provider = services[name], let service = provider.build() as? T  else {
			fatalError("Service '\(name)' implementation is not found")
		}
		return service
	}
}

/// Extension providing result builder support for declarative service registration.
public extension ServiceContainer {

	/// Result builder for constructing service provider arrays.
	///
	/// This builder enables SwiftUI-like declarative syntax for registering
	/// multiple services in a ServiceContainer.
	///
	/// Example:
	/// ```swift
	/// ServiceContainer {
	///     ServiceProvider { AuthService() }
	///     ServiceProvider { APIService() }
	/// }
	/// ```
	@resultBuilder
	struct ServiceBuilder {

		/// Builds an array of service providers from multiple providers.
		///
		/// - Parameter providers: Variadic list of ServiceProvider instances
		/// - Returns: Array of all provided ServiceProviders
		public static func buildBlock(_ providers: ServiceProvider...) -> [ServiceProvider] {
			return providers
		}

		/// Builds a single service provider.
		///
		/// - Parameter provider: A single ServiceProvider instance
		/// - Returns: The provided ServiceProvider
		public static func buildBlock(_ provider: ServiceProvider) -> ServiceProvider {
			return provider
		}
	}
}

/// Property wrapper for automatic dependency injection of services.
///
/// This property wrapper provides a convenient way to inject services from
/// the AppSession's ServiceContainer into your classes. It automatically
/// resolves the service on first access and caches the instance.
///
/// Features:
/// - Lazy resolution (service created only when first accessed)
/// - Type-safe injection
/// - Observable object support for SwiftUI
/// - Optional custom service names
///
/// Example:
/// ```swift
/// class MyViewModel: ObservableObject {
///     @Inject var authProvider: LoginAuthProvider
///     @Inject var apiService: APIService
///
///     func login() {
///         authProvider.login(username: "user", password: "pass")
///     }
/// }
/// ```
///
/// With custom name:
/// ```swift
/// @Inject("CustomAuth") var authProvider: LoginAuthProvider
/// ```
@propertyWrapper
public class Inject<ServiceProvider>: ObservableObject {
	/// Optional custom name for service resolution
	private let name: String?

	/// Cached service instance
	private var provider: ServiceProvider?

	/// The injected service instance.
	///
	/// On first access, this property resolves the service from AppSession's
	/// ServiceContainer and caches it for subsequent accesses.
	public var wrappedValue: ServiceProvider {
		provider ?? {
			let _provider: ServiceProvider = AppSession.shared.serviceContainer.resolve(for: name)
			provider = _provider
			return _provider
		}()
	}

	/// Creates an injector that resolves services by type name.
	///
	/// Example:
	/// ```swift
	/// @Inject var authProvider: LoginAuthProvider
	/// ```
	public init() {
		self.name = nil
	}

	/// Creates an injector that resolves services by custom name.
	///
	/// Use this when you have multiple implementations of the same type
	/// registered with different names.
	///
	/// - Parameter name: The custom name used when registering the service
	///
	/// Example:
	/// ```swift
	/// @Inject("PrimaryAuth") var authProvider: LoginAuthProvider
	/// ```
	public init(_ name: String){
		self.name = name
	}
}


