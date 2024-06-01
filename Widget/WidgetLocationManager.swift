//
//  WidgetLocationManager.swift
//  WidgetExtension
//
//  Created by Magnus Burton on 2022-07-18.
//

import Foundation
import CoreLocation
import os

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {

	let logger = Logger(subsystem: "com.magnusburton.UV-Index.Widget.WidgetLocationManager",
						category: "Location")

	// MARK: - Properties
	static let shared = WidgetLocationManager()

	public var isAuthorizedForWidgetUpdates: Bool {
		manager.isAuthorizedForWidgetUpdates
	}
	public var status: CLAuthorizationStatus {
		manager.authorizationStatus
	}

	private var locationContinuation: CheckedContinuation<Location, Error>?
	private let manager = CLLocationManager()
	private let geocoder = CLGeocoder()

	override init() {
		super.init()

		self.manager.delegate = self
		self.manager.desiredAccuracy = kCLLocationAccuracyReduced

		self.manager.requestWhenInUseAuthorization()
	}

	// MARK: - Public Methods
	public func requestLocation() async throws -> Location {
		try await withCheckedThrowingContinuation { continuation in
			locationContinuation = continuation
			manager.requestLocation()
		}
	}

	// MARK: - Private Methods
	private func reverseGeocode(_ location: CLLocation) async throws -> [CLPlacemark] {
		try await geocoder.reverseGeocodeLocation(location)
	}

	// MARK: - Delegate Methods
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		logger.debug("didUpdateLocations")

		guard let location = locations.last else {
			locationContinuation?.resume(throwing: LocationError.noData)
			return
		}

		Task {
			let geocode: [CLPlacemark]
			do {
				geocode = try await reverseGeocode(location)
			} catch {
				locationContinuation?.resume(throwing: LocationError.noData)
				return
			}
			
			guard let place = geocode.first else {
				locationContinuation?.resume(throwing: LocationError.noData)
				return
			}
			
			guard let formattedLocation = Location(from: place) else {
				locationContinuation?.resume(throwing: LocationError.noData)
				return
			}
			
			locationContinuation?.resume(returning: formattedLocation)
		}
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		logger.debug("didFailWithError")

		locationContinuation?.resume(throwing: error)
	}
}
