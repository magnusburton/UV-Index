//
//  Array+Extensions.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-29.
//

import Foundation

extension Array {
	func getElement(at index: Int) -> Element? {
		let isValidIndex = index >= 0 && index < count
		return isValidIndex ? self[index] : nil
	}
}
