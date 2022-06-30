//
//  LocationModel.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-07.
//

import Foundation
import os
import CoreLocation
#if canImport(WidgetKit)
import WidgetKit
#endif
import MapKit

@MainActor
class LocationModel: ObservableObject {
	lazy var weatherManager = WeatherManager(withModel: self)
	lazy var locationManager = LocationManager.shared
	lazy var notificationManager = NotificationManager.shared
	lazy var userData = UserData.shared
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.LocationModel",
						category: "Model")
	
	// MARK: - Properties
	
	public private(set) var location: Location?
	public let isUserLocation: Bool
	
	// Because this is @Published property,
	// Combine notifies any observers when a change occurs.
	@Published public private(set) var data: [UV] = []
	@Published public private(set) var status: LocationModelStatus = .idle
	
	@Published public var date = Date()
	@Published public var now = Date()
	@Published public private(set) var resetSliderDate = Date()
	
	// To calculate if we should fetch new data
	private var lastUpdate: Date?
	
	// MARK: - Initializers
	
	init(_ location: Location?, isUserLocation: Bool) {
		self.location = location
		self.isUserLocation = isUserLocation
		
		if isUserLocation {
			self.data = userData.data
		}
	}
	
	// MARK: - Public Methods
	
	// Schedule fetch for new data at chosen location
	public func refresh(ignoreRecentFetches: Bool = false) async {
		guard let location = location else {
			logger.error("No location set, cancelling UV fetch")
			return
		}
		
		if ignoreRecentFetches == false {
			// Don't update if data were updated in the last 20 minutes
			if let lastUpdate = lastUpdate {
				guard Date() > lastUpdate.addingTimeInterval(20*60) else {
					logger.error("Recently refreshed, cancelling UV fetch")
					return
				}
			}
		}
		
		logger.debug("Fetching new UV for \(location)")
		
		// Set the status
		withOptionalAnimation {
			self.status = .searching
		}
		
		// Fetch new UV data
		await weatherManager.fetch(from: location)
		
		#if canImport(WidgetKit)
		// Update widget timeline
		WidgetCenter.shared.reloadTimelines(ofKind: "UVIndexWidget")
		#endif
	}
	
	// Update the model with new UV data.
	public func updateModel(newData: [UV]) async {
		
		guard !newData.isEmpty else {
			logger.debug("No data to add.")
			return
		}
		
		var newData = newData
		
		// Sort the array by date.
		newData.sort { $0.date < $1.date }
		
		// Add the new samples.
		data = newData
		
		// Update date for this update
		lastUpdate = .now
		
		// Set the status
		withOptionalAnimation {
			self.status = .results
		}
		
		// Signal that the model was updated
		updated()
	}
	
	public func updateWithError() {
		withOptionalAnimation {
			self.status = .error
		}
	}
	
	public func setCurrentTime() {
		let currentDate = Date()
		
		self.now = currentDate
		self.date = currentDate
		self.resetSliderDate = .now
	}
	
	public func updateLocation(_ newLocation: Location) {
		logger.debug("Updating location in model")
		
		self.location = newLocation
		
		Task { await refresh(ignoreRecentFetches: true) }
	}
	
	// MARK: - Private methods
	
	private func updated() {
		if isUserLocation {
			// Update UserDefaults if this model is assigned to the user's current location
			userData.data = data
		}
		
		Task {
			// Schedule relevant notifications. These'll be overridden whenever new ones are created
			await scheduleNotifications()
		}
	}
}

extension LocationModel {
	enum LocationModelStatus: Equatable {
		case idle
		case searching
		case error
		case results
	}
	
	enum UserActivityType: Equatable {
		case currentLocation
		case customLocation
	}
}

extension LocationModel.UserActivityType {
	var activityType: String {
		switch self {
		case .currentLocation:
			return "com.magnusburton.UV-Index.activity.currentUV"
		case .customLocation:
			return "com.magnusburton.UV-Index.activity.customUV"
		}
	}
}
