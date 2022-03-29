//
//  Coordinate.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation
import CoreLocation

struct Coordinate {
	let latitude: Double
	let longitude: Double
}

extension Coordinate: CustomStringConvertible {
	var description: String {
		return "\(latitude),\(longitude)"
	}
	
	static var sampleCity: Coordinate {
		return Coordinate(latitude: 59.285069, longitude: 18.276614)
	}
}

extension CLLocation {
	var latitude: Double {
		return self.coordinate.latitude
	}
	
	var longitude: Double {
		return self.coordinate.longitude
	}
}

extension CLLocation {
	var asCoordinate: Coordinate {
		return Coordinate(latitude: self.latitude, longitude: self.longitude)
	}
}

extension CLLocationCoordinate2D {
	var asCoordinate: Coordinate {
		return Coordinate(latitude: self.latitude, longitude: self.longitude)
	}
}
