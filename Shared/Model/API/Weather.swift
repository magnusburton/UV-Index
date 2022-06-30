//
//  Weather.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation

struct Weather: Codable {
	let hourly: HourlyWeather
	
	init() {
		self.hourly = HourlyWeather()
	}
}

struct HourlyWeather: Codable {
	let data: [Data]
	
	struct Data: Codable {
		let time: Double
		let uvIndex: Int
	}
	
	init() {
		self.data = [Data]()
	}
}
