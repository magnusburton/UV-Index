//
//  UVDescriptionGenerator.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-06-09.
//

import Foundation
import Algorithms

extension LocationModel {
	public func describeDay(_ date: Date = .now) -> String? {
		guard let location = location else {
			logger.error("No location set, cancelling description")
			return nil
		}
		
		guard self.data.count > 0 else {
			logger.error("No data available, cancelling description")
			return nil
		}
		
		let data = self.data
		
		var calendar = Calendar.current
		calendar.locale = .current
		calendar.timeZone = location.timeZone
		
		// Remove data for nonselected days
		let dataToday = data.filter {
			calendar.isDate($0.date, inSameDayAs: date)
		}
		
		// Group by index
		let grouped = groupUVByIndex(from: dataToday, location: location)
		
		// Maximum daily index
		let max = grouped.max { a, b in a.index < b.index }
		guard let max = max else {
			logger.error("No max value available, cancelling description")
			return nil
		}
		
		// Get intervals considered high
		let todayDangerData = grouped.filter {
			$0.category != .none && $0.category != .low
		}
		
		// Handle low values, if the max is considered low
		if max.category == .none || max.category == .low {
			return String(localized: "Low levels all day. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
		}
		
		// From here, we handle only dangerous levels
		guard let firstHighValue = todayDangerData.first,
			  let lastHighValue = todayDangerData.last else {
			logger.error("No first & last value available, cancelling description")
			return nil
		}
		
		// Handle moderate values
		if max.category == .moderate {
			if todayDangerData.count == 1 {
				return String(localized: "Apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "Apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise moderate levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		// Handle high values
		if max.category == .high {
			if todayDangerData.count == 1 {
				return String(localized: "High levels of UV radiation, apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "High levels of UV radiation, apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise moderate levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		// Handle extreme values
		if max.category == .veryHigh || max.category == .extreme {
			if todayDangerData.count == 1 {
				return String(localized: "Extreme risk of harm with peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "Extreme risk of harm with peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise high levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		return nil
	}
}

