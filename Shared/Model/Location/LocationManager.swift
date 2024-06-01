//
//  LocationManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation
import CoreLocation
import os

class LocationManager: NSObject {
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.LocationManager",
						category: "Location")
	
	// A weak link to the data store.
	private weak var model: Store?
	
	// MARK: - Properties
	static let shared = LocationManager()
	
	public var isAuthorizedForWidgetUpdates: Bool {
		#if os(watchOS)
		return false
		#else
		return manager.isAuthorizedForWidgetUpdates
		#endif
	}
	public var status: CLAuthorizationStatus {
		manager.authorizationStatus
	}
	
	private var locationContinuation: CheckedContinuation<Location, Error>?
	private let manager = CLLocationManager()
	private let geocoder = CLGeocoder()
	
	// MARK: - Initializers
	private override init() {
		super.init()
		
		self.manager.delegate = self
		self.manager.desiredAccuracy = kCLLocationAccuracyReduced
//		self.manager.distanceFilter = 2000
//		
//		#if !os(watchOS)
//		self.manager.pausesLocationUpdatesAutomatically = true
//		self.manager.showsBackgroundLocationIndicator = false
//		self.manager.allowsBackgroundLocationUpdates = true
//		#endif
		
		self.manager.requestWhenInUseAuthorization()
		
		beginMonitoring()
	}
	
	// MARK: - Public Methods
	public func assign(_ model: Store) {
		self.model = model
		
		loadLastLocation()
	}
	
	public func requestLocation() async throws -> Location {
		try await withCheckedThrowingContinuation { continuation in
			locationContinuation = continuation
			manager.requestLocation()
		}
	}
	
	public func beginMonitoring() {
		self.manager.startMonitoringSignificantLocationChanges()
	}
	
	public func cancelMonitoring() {
		self.manager.stopMonitoringSignificantLocationChanges()
	}
	
	// MARK: - Private Methods
	
	private func reverseGeocode(_ location: CLLocation) async throws -> [CLPlacemark] {
		try await geocoder.reverseGeocodeLocation(location)
	}
	
	private func loadLastLocation() {
		guard let location = UserData.loadLastLocation() else {
			return
		}
		
		Task {
			await model?.updateModel(with: location)
		}
	}
}

extension LocationManager: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		logger.debug("didUpdateLocations")
		
		guard let model = model else {
			locationContinuation?.resume(throwing: LocationError.noModel)
			return
		}
		guard let location = locations.last else {
			locationContinuation?.resume(throwing: LocationError.noData)
			return
		}
		
		Task {
			do {
				// TODO: This results in no location being returned if out in the sea or no name can be found.
			
				let geocode = try await reverseGeocode(location)
				
				guard let place = geocode.first else {
					locationContinuation?.resume(throwing: LocationError.noData)
					return
				}
				
				guard let formattedLocation = Location(from: place) else {
					locationContinuation?.resume(throwing: LocationError.noData)
					return
				}
				
				await model.updateModel(with: formattedLocation)
				
				UserData.saveLocation(formattedLocation)
				
				locationContinuation?.resume(returning: formattedLocation)
			} catch {
				locationContinuation?.resume(throwing: LocationError.noData)
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		logger.debug("didFailWithError")
		
		locationContinuation?.resume(throwing: error)
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		logger.debug("didChangeAuthorization")
		
		switch status {
		case .restricted, .denied:
			Task { await model?.disableLocationFeatures() }
			break
			
		case .authorizedAlways, .authorizedWhenInUse:
			Task { await model?.enableLocationFeatures() }
			break
			
		case .notDetermined:
			// User has not picked an authorization status
			Task { await model?.disableLocationFeatures() }
			break
			
		@unknown default:
			fatalError()
		}
	}
}
