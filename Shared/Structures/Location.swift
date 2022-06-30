//
//  Location.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-05.
//

import Foundation
import MapKit

struct Location: Hashable, Codable {
	let title: String
	let subtitle: String
	let coordinates: Coordinate
	
	let timeZone: TimeZone
	
	init(title: String, subtitle: String, coordinates: Coordinate, timeZone: TimeZone) {
		self.title = title
		self.subtitle = subtitle
		self.coordinates = coordinates
		self.timeZone = timeZone
	}
	
	init?(from placemark: CLPlacemark) {
		guard let name = placemark.name,
			  let subtitle = placemark.formattedSubtitle,
			  let location = placemark.location else {
			
			debugPrint("Failed to generate Location object due to bad input data.")
			return nil
		}
		
		self.title = name
		self.subtitle = subtitle
		self.coordinates = location.asCoordinates
		self.timeZone = placemark.timeZone ?? .current
	}
	
	init?(from mapItem: MKMapItem?) {
		guard let mapItem = mapItem else {
			return nil
		}
		guard let name = mapItem.placemark.name,
			  let subtitle = mapItem.placemark.formattedSubtitle,
			  let location = mapItem.placemark.location else {
			
			debugPrint("Failed to generate Location object due to bad input data.")
			return nil
		}
		guard let timeZone = (mapItem.placemark.timeZone ?? mapItem.timeZone) else {
			
			debugPrint("Failed to generate Location object due to bad time zone data.")
			return nil
		}
		
		self.title = name
		self.subtitle = subtitle
		self.coordinates = location.asCoordinates
		self.timeZone = timeZone
	}
}

extension Location: Identifiable {
	var id: String {
		"\(title)+\(subtitle)"
	}
}

extension Location: CustomStringConvertible {
	var description: String {
		"\(title), \(subtitle)"
	}
}
