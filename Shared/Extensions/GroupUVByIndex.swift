//
//  GroupUVByIndex.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-06-09.
//

import Foundation

func groupUVByIndex(from data: [UV], location: Location) -> [UV] {
	var entries: [UV] = []
	
	var calendar = Calendar.current
	calendar.timeZone = location.timeZone
	
	let chunks = data.chunked(by: { $0.index == $1.index })
	for chunk in chunks {
		if chunk.isEmpty {
			continue
		}
		
		let first = chunk.first!
		
		let date = first.date
		let index = first.index
		let item: UV
		
		if chunk.count == 1 {
			item = UV(index: index, date: date)
		} else {
			let last = chunk.last!
			let endDate = last.date.addingTimeInterval(3600)
			
			item = UV(index: index, startDate: date, endDate: endDate)
		}
		
		entries.append(item)
	}
	
	return entries
}
