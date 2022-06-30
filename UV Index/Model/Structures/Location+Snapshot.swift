//
//  Location+Snapshot.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-04.
//

import Foundation
import MapKit

extension Location {
	func generateSnapshot(width: Double, height: Double) async -> UIImage? {
		let span: CLLocationDegrees = 0.8
		
		// The region the map should display.
		let region = MKCoordinateRegion(
			center: self.coordinates.as2DCoordinate,
			span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
		)
		
		// Map options.
		let mapOptions = MKMapSnapshotter.Options()
		mapOptions.region = region
		mapOptions.size = CGSize(width: width, height: height)
		mapOptions.showsBuildings = true
		mapOptions.pointOfInterestFilter = .excludingAll
		mapOptions.traitCollection = UITraitCollection(userInterfaceStyle: .dark)
		
		// Create the snapshotter and run it.
		let snapshotter = MKMapSnapshotter(options: mapOptions)
		
		do {
			let snapshot = try await snapshotter.start()
			return snapshot.image
		} catch {
			debugPrint(error.localizedDescription)
			return nil
		}
	}
}
