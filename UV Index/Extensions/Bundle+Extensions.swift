//
//  Bundle+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-11-05.
//

import Foundation

extension Bundle {
	var releaseVersionNumber: String? {
		return infoDictionary?["CFBundleShortVersionString"] as? String
	}
	var buildVersionNumber: String? {
		return infoDictionary?["CFBundleVersion"] as? String
	}
}
