//
//  ConfigInterface.swift
//

import Foundation

/// This interface is used to control and manage the implementation of the configuration class. any configuration needs to comply and override function and method as below to this protocol
open class ConfigInterface {
	
	/// Used to update the config set variables for the configuration class
	open func update(configs: [String: Any]){
		assertionFailure("This update function of config interface has to be overrided. See BrandConfig, FeatureConfig and ThemeConfig example")
	}
	
	/// Flush the buffer configuration to disk. so that we can save the latest configuration in the disk for later use
 /// Flush.
	open func flush(){
		assertionFailure("This function of config interface has to be overrided. See BrandConfig, FeatureConfig and ThemeConfig example")
	}
}
