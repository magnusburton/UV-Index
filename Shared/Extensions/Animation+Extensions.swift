//
//  Animation+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-30.
//

import Foundation
import SwiftUI

func withOptionalAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
#if os(watchOS)
	if WKAccessibilityIsReduceMotionEnabled() {
		return try body()
	} else {
		return try withAnimation(animation, body)
	}
#else
	if UIAccessibility.isReduceMotionEnabled {
		return try body()
	} else {
		return try withAnimation(animation, body)
	}
#endif
}

extension Binding {
	/// Specifies an animation to perform when the binding value changes. Only animated if enivironment `.accessibilityReduceMotion` is false.
	///
	/// - Parameter animation: An animation sequence performed when the binding
	///   value changes.
	///
	/// - Returns: A new binding.
	public func optionalAnimation(_ animation: Animation? = .default) -> Binding<Value> {
#if os(watchOS)
		if WKAccessibilityIsReduceMotionEnabled() {
			return self
		} else {
			return self.animation(animation)
		}
#else
		if UIAccessibility.isReduceMotionEnabled {
			return self
		} else {
			return self.animation(animation)
		}
#endif
	}
}
