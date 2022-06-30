//
//  UV.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation
import SwiftUI

class UV: Codable {
	var index: Int
	var date: Date
	var duration: TimeInterval
	
	var endDate: Date {
		date.addingTimeInterval(duration)
	}
	var interval: DateInterval {
		DateInterval(start: date, duration: duration)
	}
	
	init(index: Int, date: Date) {
		self.index = index
		self.date = date
		self.duration = 3600
	}
	
	init(index: Int, startDate: Date, endDate: Date) {
		self.index = index
		self.date = startDate
		self.duration = DateInterval(start: startDate, end: endDate).duration
	}
	
	enum UVCategory {
		case none
		case low
		case moderate
		case high
		case veryHigh
		case extreme
	}
	
	var category: UVCategory {
		switch index {
		case 0:
			return .none
		case 1...2:
			return .low
		case 3...5:
			return .moderate
		case 6...7:
			return .high
		case 8...10:
			return .veryHigh
		default:
			return .extreme
		}
	}
	
	var description: LocalizedStringKey {
		switch category {
		case .none:
			return "uv.description.none"
		case .low:
			return "uv.description.low"
		case .moderate:
			return "uv.description.moderate"
		case .high:
			return "uv.description.high"
		case .veryHigh:
			return "uv.description.veryHigh"
		case .extreme:
			return "uv.description.extreme"
		}
	}
	
	var color: Color {
		var index = self.index
		
		if index > 11 {
			index = 11
		} else if index <= 0 {
			// Custom color for zero UV
			return Color(hue: 150/360, saturation: 1, brightness: 0.8)
		}
		
		let percentage = Double(index) / 11
		
		// When index is zero
//		let startHue = 120.0
		let startHue = 135.0
		
		// When index is 11 (or higher)
//		let endHue = 300.0
		let endHue = 280.0
		
		// Distance between startHue and endHue the long way
		let distance = 360 - endHue + startHue
		
		let weightedDistance = distance * percentage
		let scaledDistance = startHue - weightedDistance
		
		if scaledDistance < 0 {
			return Color(hue: (360 + scaledDistance) / 360, saturation: 1, brightness: 0.8)
		} else {
			return Color(hue: scaledDistance / 360, saturation: 1, brightness: 0.8)
		}
	}
}

extension UV: Equatable {
	static func == (lhs: UV, rhs: UV) -> Bool {
		lhs.index == rhs.index && lhs.date == rhs.date
	}
}

struct UV_Previews: PreviewProvider {
	static var previews: some View {
		ForEach(0..<12) { index in
			UV(index: index, date: .now).color
				.previewDisplayName("UV index \(index)")
		}
		.previewLayout(.fixed(width: 50, height: 50))
	}
}
