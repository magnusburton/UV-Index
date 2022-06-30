//
//  String+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-31.
//

import Foundation

extension String {
	func range(from nsRange: NSRange) -> Range<String.Index>? {
		Range(nsRange, in: self)
	}
}

extension AttributedString {
	func range(from nsRange: NSRange) -> Range<AttributedString.Index>? {
		Range(nsRange, in: self)
	}
}
