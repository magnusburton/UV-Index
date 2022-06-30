//
//  ColorScheme+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-13.
//

import Foundation
import SwiftUI

func colorSchemeFromInt(_ value: Int) -> ColorScheme? {
	switch value {
	case 1:
		return .light
	case 2:
		return .dark
	default:
		return .none
	}
}

func colorSchemeToInt(_ value: ColorScheme?) -> Int {
	switch value {
	case .light:
		return 1
	case .dark:
		return 2
	default:
		return 0
	}
}
