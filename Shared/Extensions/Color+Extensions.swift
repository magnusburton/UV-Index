//
//  Color.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI

#if os(iOS)
extension Color {
	static let systemBackground = Color(UIColor.systemBackground)
	static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
	static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
}
#elseif os(watchOS)
extension Color {
	static let systemBackground = Color(UIColor.black)
	static let secondarySystemBackground = Color(UIColor.black)
	static let tertiarySystemBackground = Color(UIColor.black)
}
#endif
