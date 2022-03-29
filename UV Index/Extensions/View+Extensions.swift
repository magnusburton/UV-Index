//
//  View+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import SwiftUI

extension View {
	public func gradientForeground(colors: [Color]) -> some View {
		self.overlay(
			LinearGradient(
				colors: colors,
				startPoint: .topTrailing,
				endPoint: .bottomLeading)
		)
			.mask(self)
	}
}
