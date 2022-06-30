//
//  Coordinate.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation
import CoreLocation

struct Coordinate: Hashable, Codable {
	let latitude: Double
	let longitude: Double
}

extension Coordinate: CustomStringConvertible {
	var description: String {
		"\(latitude),\(longitude)"
	}
	
	static var sampleCity: Coordinate {
		Coordinate(latitude: 59.285069, longitude: 18.276614)
	}
}

extension Coordinate {
	var asCLLocation: CLLocation {
		CLLocation(latitude: self.latitude, longitude: self.longitude)
	}
	
	var as2DCoordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
	}
}

extension CLLocation {
	var latitude: Double {
		self.coordinate.latitude
	}
	
	var longitude: Double {
		self.coordinate.longitude
	}
}

extension CLLocation {
	var asCoordinates: Coordinate {
		Coordinate(latitude: self.latitude, longitude: self.longitude)
	}
}

extension CLLocationCoordinate2D {
	var asCoordinate: Coordinate {
		Coordinate(latitude: self.latitude, longitude: self.longitude)
	}
}
