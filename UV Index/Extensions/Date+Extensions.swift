//
//  Date.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-08-02.
//

import Foundation

extension Date {
	static func - (lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
	
	var startOfDay: Date {
		return Calendar.current.startOfDay(for: self)
	}
	
	var endOfDay: Date {
		return Calendar.current.endOfDay(for: self)
	}
	
	func endOfDay(timezone: TimeZone) -> Date {
		return Calendar.current.endOfDay(for: self, timezone: timezone)
	}
	
	var tomorrow: Date? {
		return Calendar.current.date(byAdding: .day, value: +1, to: self)
	}
}

extension Calendar {
	func endOfDay(for date: Date, timezone: TimeZone? = nil) -> Date {
		var calendar = self
		var components = DateComponents()
		components.day = 1
		components.second = -1
		
		if let timezone = timezone {
			components.timeZone = timezone
			calendar.timeZone = timezone
		}
		
		let start = calendar.startOfDay(for: date)
		return calendar.date(byAdding: components, to: start)!
	}
}
