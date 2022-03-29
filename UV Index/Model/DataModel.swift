//
//  DataModel.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-07.
//

import Foundation
import os
import CoreLocation
import WidgetKit

@MainActor
class DataModel: ObservableObject {
	lazy var weatherManager = WeatherManager(withModel: self)
	lazy var locationManager = LocationManager.shared
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.DataModel",
						category: "Model")
	
	/// A shared data provider for use within the main app bundle.
	static let shared = DataModel()
	
	// MARK: - Properties
	
	// Because this is @Published property,
	// Combine notifies any observers when a change occurs.
	@Published public private(set) var data: [UV] = []
	@Published public private(set) var status: DataModelStatus = .idle
	@Published public private(set) var currentLocation: CLPlacemark? = nil
	@Published public private(set) var customLocation: CLPlacemark? = nil
	@Published public private(set) var locationIsCurrent = true
	
	@Published public var date = Date()
	@Published public var now = Date()
	@Published public private(set) var resetSliderDate = Date()
	
	@Published public var presentSheet = false
	@Published public var sheet = PresentedSheet.location
	
	public var location: CLPlacemark? {
		if locationIsCurrent {
			return currentLocation
		} else {
			return customLocation
		}
	}
	
	public var locationTitle: String? {
		location?.formatted
	}
	public var locationName: String? {
		location?.name
	}
	public var locationCity: String? {
		location?.subAdministrativeArea ?? location?.administrativeArea ?? location?.country
	}
	public var locationTimeZone: TimeZone {
		location?.timeZone ?? .current
	}
	
	public var authorizationStatus: CLAuthorizationStatus {
		locationManager.status
	}
	public var authorized: Bool {
		self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways
	}
	public var widgetAuthorized: Bool {
		locationManager.isAuthorizedForWidgetUpdates
	}
	
	internal var backgroundTasksRegistered = false
	
	// MARK: - Public Methods
	
	// Schedule fetch for new data at chosen location
	public func fetchUV() async {
		guard let location = location else { return }
		
		logger.debug("Fetching new UV for \(location)")
		
		// Set the status
		self.status = .searching
		
		// Fetch new UV data
		await weatherManager.fetch(from: location)
		
		// Update widget timeline
		WidgetCenter.shared.reloadTimelines(ofKind: "UVIndexWidget")
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
		
		// Set the status
		self.status = .results
	}
	
	// Update the model with new location data from GPS.
	public func updateModel(with location: CLPlacemark) async {
		logger.debug("Updating model with current location \(location)")
		
		self.currentLocation = location
		
		if self.locationIsCurrent {
			await self.fetchUV()
		}
		
		// Set user activity
		self.setUserActivity(.current)
	}
	
	// Set custom location as current location.
	public func updateModelWithCustomLocation(_ location: CLPlacemark) async {
		logger.debug("Attempting to update model with custom location \(location)")
		
		guard let placemark = await locationManager.reverseGeocode(from: location) else {
			logger.error("Reverse geocode returned nil.")
			return
		}
		
		logger.debug("Updating model with custom location placemark \(placemark) from \(location)")
		
		self.locationIsCurrent = false
//		self.customLocation = placemark
		self.customLocation = location
		
		await self.fetchUV()
		self.setCurrentTime()
	}
	
	// Update the model with current location.
	public func updateModelWithCurrentLocation() async {
		let wasPreviouslyCurrent = locationIsCurrent
		self.locationIsCurrent = true
		
		guard let location = location else {
			logger.error("No current location available!")
			return
		}
		
		// We don't need to request location since it's always updating in the background
		logger.debug("Updating model with current location placemark \(location)")
		
		if wasPreviouslyCurrent == false {
			await self.fetchUV()
		}
		self.setCurrentTime()
	}
	
	// Update the model with default preference location.
	public func updateModelWithDefaultLocation() async {
		
	}
	
	public func requestCurrentLocation() async -> CLPlacemark? {
		do {
			return try await locationManager.requestLocation()
		} catch {
			logger.error("Failed to request current location with error: \(error.localizedDescription)")
			return nil
		}
	}
	
	public func updateWithError() {
		self.status = .error
	}
	
	public func setCurrentTime() {
		let currentDate = Date()
		
		self.now = currentDate
		self.date = currentDate
		self.resetSliderDate = .now
	}
	
	// MARK: - Private methods
	
	// The model's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {
		locationManager.assign(self)
	}
	
	private func describeUV() -> String? {
		let data = self.data
		
		var calendar = Calendar.current
		calendar.locale = .current
		calendar.timeZone = locationTimeZone
		
		let todayLowData = data.filter {
			calendar.isDateInToday($0.date) && $0.index >= 1 && $0.index <= 2
		}
		let todayDangerData = data.filter {
			calendar.isDateInToday($0.date) && $0.index >= 3
		}
		
		// Any low UV left today?
		if todayLowData.count > 0 {
			return "Low levels all day."
		}
		
		// Any dangerous UV left today?
		if todayDangerData.count > 0, let last = todayDangerData.last {
			guard let nextHour = calendar.nextDate(after: last.date, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) else {
				return nil
			}
			
			let lastFormatted = nextHour.formatted(date: .omitted, time: .shortened)
			return "Apply sunscreen if you're outside until \(lastFormatted)."
		}
		
		return nil
	}
	
	private func setUserActivity(_ type: UserActivityType, placemark: CLPlacemark? = nil) {
		let userActivity = NSUserActivity(activityType: type.activityType)
		
		switch type {
		case .current:
			userActivity.title = "Se nuvarande nivåer"
		case .customLocation:
			if let placemark = placemark {
				if let locationName = placemark.name {
					userActivity.title = "\(locationName)"
					
					userActivity.addUserInfoEntries(from: [
						"locationName": locationName
					])
				} else {
					return
				}
				
				if let location = placemark.location {
					userActivity.addUserInfoEntries(from: [
						"locationLongitude": location.longitude,
						"locationLatitude": location.latitude
					])
				}
			}
		}
		
		userActivity.isEligibleForSearch = true
		userActivity.isEligibleForHandoff = false
		userActivity.isEligibleForPrediction = true
		userActivity.becomeCurrent()
	}
}

extension DataModel {
	enum DataModelStatus: Equatable {
		case idle
		case searching
		case error
		case results
	}
	
	enum UserActivityType: Equatable {
		case current
		case customLocation
	}
	
	enum PresentedSheet: Equatable {
		case location
		case settings
	}
}

extension DataModel.UserActivityType {
	var activityType: String {
		switch self {
		case .current:
			return "com.magnusburton.UV-Index.activity.currentUV"
		case .customLocation:
			return "com.magnusburton.UV-Index.activity.customUV"
		}
	}
}
