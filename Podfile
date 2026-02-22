source 'https://github.com/CocoaPods/Specs.git'
project 'ATLRides.xcodeproj'
platform :ios, '13.0'
inhibit_all_warnings!
use_frameworks!

def shared_pods
	pod 'Mapbox-iOS-SDK', '~> 6.3.0'
	pod 'Lock', '~> 2.0'
	pod 'On-Device-Positioning-Pod', :git=>'https://github.com/Jibestream/On-Device-Positioning-Pod'
	pod 'NavigationKit-iOS-Pod', :git => 'https://github.com/Jibestream/NavigationKit-iOS-Pod.git'
	pod 'JMapiOSSDK', :git => 'https://github.com/Jibestream/JMap-iOS-SDK-Pod.git'
end

target 'GMap' do
		shared_pods
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    # strip the bitcode from Mapbox related frameworks
    if target.name == 'MapboxMobileEvents'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/MapboxMobileEvents/MapboxMobileEvents.xcframework/ios-arm64_armv7/MapboxMobileEvents.framework/MapboxMobileEvents -o Pods/MapboxMobileEvents/MapboxMobileEvents.xcframework/ios-arm64_armv7/MapboxMobileEvents.framework/MapboxMobileEvents`
    end

    if target.name == 'MapboxCommon'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/MapboxCommon/MapboxCommon.xcframework/ios-arm64_armv7/MapboxCommon.framework/MapboxCommon -o Pods/MapboxCommon/MapboxCommon.xcframework/ios-arm64_armv7/MapboxCommon.framework/MapboxCommon`
    end

    if target.name == 'MapboxCoreMaps'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/MapboxCoreMaps/MapboxCoreMaps.xcframework/ios-arm64_armv7/MapboxCoreMaps.framework/MapboxCoreMaps -o Pods/MapboxCoreMaps/MapboxCoreMaps.xcframework/ios-arm64_armv7/MapboxCoreMaps.framework/MapboxCoreMaps`
    end

    if target.name == 'Mapbox-iOS-SDK'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/Mapbox-iOS-SDK/dynamic/Mapbox.framework/Mapbox -o Pods/Mapbox-iOS-SDK/dynamic/Mapbox.framework/Mapbox`
    end

    if target.name == 'MapboxAccounts'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/MapboxAccounts/MapboxAccounts.xcframework/ios-arm64_armv7/MapboxAccounts.framework/MapboxAccounts -o Pods/MapboxAccounts/MapboxAccounts.xcframework/ios-arm64_armv7/MapboxAccounts.framework/MapboxAccounts`
    end

    if target.name == 'MapboxNavigationNative'
      `xcrun -sdk iphoneos bitcode_strip -r Pods/MapboxNavigationNative/MapboxNavigationNative.xcframework/ios-arm64_armv7/MapboxNavigationNative.framework/MapboxNavigationNative -o Pods/MapboxNavigationNative/MapboxNavigationNative.xcframework/ios-arm64_armv7/MapboxNavigationNative.framework/MapboxNavigationNative`
    end

    if target.name == "JMapiOSSDK"
      `xcrun bitcode_strip -r Pods/JMapiOSSDK/JMapiOSSDK4.0/Frameworks/JMapCoreKit.xcframework/ios-arm64_armv7/JMapCoreKit.framework/JMapCoreKit -o Pods/JMapiOSSDK/JMapiOSSDK4.0/Frameworks/JMapCoreKit.xcframework/ios-arm64_armv7/JMapCoreKit.framework/JMapCoreKit`
    end

    # Fix build settings for all targets
    target.build_configurations.each do |config|
      # Enable BUILD_LIBRARY_FOR_DISTRIBUTION for Swift frameworks
      if target.name == 'Auth0' || target.name == 'Lock' || target.name == 'JWTDecode' || target.name == 'SimpleKeychain'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end

      # Set IPHONEOS_DEPLOYMENT_TARGET to avoid warnings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

      # Exclude arm64 architecture for simulator builds to support x86_64
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'

      # Set ONLY_ACTIVE_ARCH to NO to build for x86_64
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'

      # Explicitly set valid architectures
      config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
      config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
    end

	end
end
