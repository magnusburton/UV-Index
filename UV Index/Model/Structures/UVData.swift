//
//  UVData.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-11.
//

import Foundation

struct UVData: Codable {
	let data: [UV]
	let location: Location
	
	var startDate: Date? {
		data.first?.date
	}
}
