//
//  Store.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-28.
//

import Foundation
import os
import CoreLocation
import SwiftUI
import TelemetryClient
#if !os(watchOS)
import WidgetKit
#endif

@MainActor
class Store: ObservableObject {
	lazy var locationManager = LocationManager.shared
	lazy var notificationManager = NotificationManager.shared
	lazy var userData = UserData.shared
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.Store",
						category: "Store")
	
	/// A shared data provider for use within the main app bundle.
	static let shared = Store()
	
	// An actor used to save and load the model data away from the main thread.
	private let store = DataStore()
	
	// MARK: - Properties
	
	// Because this is @Published property,
	// Combine notifies any observers when a change occurs.
	@Published public private(set) var currentLocation: Location?
	
	// User's saved locations, may be empty
	@Published public private(set) var savedLocations: [Location] = []
	
	@Published public var renderedCurrentLocationImage: Image?
	
	/// Show current location by default
	/// Don't access this programatically!
	@Published public var tabSelection = 0
	
	/// Don't access this programatically!
	@Published public var presentSheet = false
	@Published public private(set) var sheet = PresentedSheet.location
	
	@Published public var notificationsAuthorized = false {
		didSet {
			TelemetryManager.send("notificationAuthorizationChanged", with: [
				"state": "\(notificationsAuthorized)"
			])
		}
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
	
	// Update the model with new location data from GPS.
	public func updateModel(with location: Location) async {
		logger.debug("Updating model with current location \(location).")
		
		self.currentLocation = location
		
#if !os(watchOS)
		WidgetCenter.shared.reloadAllTimelines()
#endif
	}
	
	public func showCurrentLocationTab() {
		logger.debug("Moving to current location tab.")
		
		withOptionalAnimation {
			tabSelection = 0
			presentSheet = false
		}
		
		TelemetryManager.send("showLocationTab", with: [
			"locationIndex": "0"
		])
	}
	
	public func showLocationTab(_ location: Location) {
		guard let index = savedLocations.firstIndex(of: location) else {
			logger.error("Moving to location \(location) tab failed.")
			return
		}
		
		logger.error("Moving to location \(location) tab.")
		
		withOptionalAnimation {
			tabSelection = index+1
			presentSheet = false
		}
		
		TelemetryManager.send("showLocationTab", with: [
			"locationIndex": "\(index)"
		])
	}
	
	public func showLocationTab(_ locationId: String) throws {
		guard let index = savedLocations.firstIndex(where: { $0.id == locationId }) else {
			logger.error("Moving to location id \(locationId) tab failed.")
			return
		}
		
		logger.error("Moving to location id \(locationId) tab.")
		
		withOptionalAnimation {
			tabSelection = index+1
			presentSheet = false
		}
		
		TelemetryManager.send("showLocationTab", with: [
			"locationIndex": "\(index)"
		])
	}
	
	// Add a location to the list of locations.
	public func addLocation(_ location: Location) {
		logger.debug("Adding a location.")
		
		// Create a local array to hold the changes.
		var locations = savedLocations
		
		// Prevent duplicates
		if locations.contains(location) {
			return
		}
		
		// Add the location to the array.
		locations.append(location)
		
		savedLocations = locations
		
		// Navigate to added location
		showLocationTab(location)
		
		// Save location information.
		Task {
			await self.locationsUpdated()
		}
		
		TelemetryManager.send("addLocation")
	}
	
	// Remove a location from the list of locations.
	public func removeLocation(_ location: Location) {
		logger.debug("Removing a location.")
		
		// Create a local array to hold the changes.
		var locations = savedLocations
		
		// Get index of location in array
		guard let index = locations.firstIndex(of: location) else {
			return
		}
		
		// Reset view to current location tab
		tabSelection = 0
		
		// Remove the location from the array.
		locations.remove(at: index)
		
		savedLocations = locations
		
		// Save location information.
		Task {
			await self.locationsUpdated()
			
			// TODO: Remove donated intents
		}
		
		TelemetryManager.send("removeLocation")
	}
	
	public func enableLocationFeatures() {
		logger.log("Enabling location features.")
		
		locationManager.beginMonitoring()
		
#if !os(watchOS)
		WidgetCenter.shared.reloadAllTimelines()
#endif
	}
	
	public func disableLocationFeatures() {
		logger.log("Disabling location features.")
		
		locationManager.cancelMonitoring()
		
		// Clear old location data
		UserData.clearLastLocation()
		
		// Clear old UV data
		userData.data = []
		
#if !os(watchOS)
		WidgetCenter.shared.reloadAllTimelines()
#endif
	}
	
	public func showSheet(_ sheet: PresentedSheet) {
		logger.error("Presenting \(sheet.rawValue) sheet.")
		
		withOptionalAnimation {
			self.sheet = sheet
			self.presentSheet = true
		}
		
		TelemetryManager.send("openSheet", with: [
			"sheet": sheet.rawValue
		])
	}
	
	public func hideSheet() {
		logger.error("Hiding sheet.")
		
		withOptionalAnimation {
			self.presentSheet = false
		}
		TelemetryManager.send("hideSheet")
	}
	
	// MARK: - Private methods
	
	// The model's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {
		locationManager.assign(self)
		
		Task {
			// Begin loading the data from disk.
			await load()
			
			await notificationManager.assign(self)
		}
	}
	
	// Begin loading the data from disk.
	func load() async {
		let locations = await store.load()
		
		// Assign loaded locations to model
		savedLocations = locations
		await locationsUpdated()
	}
	
	private func locationsUpdated() async {
		logger.debug("A value has been assigned to the current locations property.")
		
		// Begin saving the data.
		await store.save(savedLocations)
	}
	
	// MARK: - Enums
	
	enum PresentedSheet: String, Equatable {
		case location
		case settings
	}
}

private actor DataStore {
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.DataStore",
						category: "ModelIO")
	
	// Use this value to determine whether you have changes that can be saved to disk.
	private var savedValue: [Location] = []
	
	// Begin saving the location data to disk.
	func save(_ currentLocations: [Location]) {
		
		// Don't save the data if there haven't been any changes.
		if currentLocations == savedValue {
			logger.debug("The location list hasn't changed. No need to save.")
			return
		}
		
		// Save as a binary plist file.
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .binary
		
		let data: Data
		
		do {
			// Encode the currentLocations array.
			data = try encoder.encode(currentLocations)
		} catch {
			logger.error("Encoding the data failed: \(error.localizedDescription)")
			return
		}
		
		do {
			// Write the data to disk
			try data.write(to: self.dataURL, options: [.atomic])
			
			// Update the saved value.
			self.savedValue = currentLocations
			
			self.logger.debug("Saved!")
		} catch {
			self.logger.error("Saving the data failed: \(error.localizedDescription)")
		}
	}
	
	// Begin loading the data from disk.
	func load() -> [Location] {
		logger.debug("Loading the model.")
		
		let locations: [Location]
		
		do {
			// Load the drink data from a binary plist file.
			let data = try Data(contentsOf: self.dataURL)
			
			// Decode the data.
			let decoder = PropertyListDecoder()
			locations = try decoder.decode([Location].self, from: data)
			logger.debug("Data loaded from disk.")
			
		} catch CocoaError.fileReadNoSuchFile {
			logger.error("No file found--creating an empty location list.")
			locations = []
		} catch {
			fatalError("*** An unexpected error occurred while loading the location list: \(error.localizedDescription) ***")
		}
		
		// Update the saved value.
		savedValue = locations
		return locations
	}
	
	// Returns the URL for the plist file that stores the location data.
	private var dataURL: URL {
		get throws {
			try FileManager
				.default
				.url(for: .documentDirectory,
					 in: .userDomainMask,
					 appropriateFor: nil,
					 create: false)
			// Append the file name to the directory.
				.appendingPathComponent("UVIndex.plist")
		}
	}
}
