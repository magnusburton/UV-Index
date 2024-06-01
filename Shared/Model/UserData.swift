//
//  UserData.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-10-10.
//

import Foundation
import MapKit
import SwiftUI
import TelemetryClient

final class UserData: ObservableObject {
	
	static let suiteName = "group.com.magnusburton.UV-Index"
	static let shared = UserData()
	
	private let sharedUserDefaults = UserDefaults(suiteName: suiteName)
	
	// MARK: - Properties
	@Published var firstLaunch: Bool {
		didSet {
			sharedUserDefaults?.set(firstLaunch, forKey: "firstLaunch")
		}
	}
	@Published var hasOpenedLocationSheet: Bool {
		didSet {
			sharedUserDefaults?.set(hasOpenedLocationSheet, forKey: "hasOpenedLocationSheet")
		}
	}
	@Published var defaultLocation: CLLocationCoordinate2D? {
		didSet {
			if let defaultLocation = defaultLocation {
				sharedUserDefaults?.set(defaultLocation, forKey: "defaultLocation")
			} else {
				sharedUserDefaults?.removeObject(forKey: "defaultLocation")
			}
		}
	}
	@Published var colorScheme: Int {
		didSet {
			switch colorScheme {
			case 0...2:
				sharedUserDefaults?.set(colorScheme, forKey: "colorScheme")
			default:
				sharedUserDefaults?.removeObject(forKey: "colorScheme")
			}
			TelemetryManager.send("colorSchemeSettingsChanged", with: [
				"state": "\(colorScheme)"
			])
		}
	}
	@Published var shareLocation: Bool {
		didSet {
			sharedUserDefaults?.set(shareLocation, forKey: "shareLocation")
			TelemetryManager.send("shareLocationSettingsChanged", with: [
				"state": "\(shareLocation)"
			])
		}
	}
	
	// Notifications
	@Published var notifications: Bool {
		didSet {
			sharedUserDefaults?.set(notifications, forKey: "notifications")
			
			if notifications == false {
				notificationHighLevels = false
				notificationDailyOverview = false
			}
		}
	}
	@Published var notificationHighLevels: Bool {
		didSet {
			sharedUserDefaults?.set(notificationHighLevels, forKey: "notificationHighLevels")
			TelemetryManager.send("notificationHighLevelsChanged", with: [
				"state": "\(notificationHighLevels)"
			])
		}
	}
	@Published var notificationHighLevelsMinimumValue: Double {
		didSet {
			sharedUserDefaults?.set(notificationHighLevelsMinimumValue, forKey: "notificationHighLevelsMinimumValue")
			TelemetryManager.send("notificationHighLevelsMinimumValueChanged", with: [
				"minimumValue": "\(notificationHighLevelsMinimumValue)"
			])
		}
	}
	
	@Published var notificationDailyOverview: Bool {
		didSet {
			sharedUserDefaults?.set(notificationDailyOverview, forKey: "notificationDailyOverview")
			TelemetryManager.send("notificationDailyOverviewChanged", with: [
				"state": "\(notificationDailyOverview)"
			])
		}
	}
	@Published var notificationDailyOverviewTime: Int {
		didSet {
			sharedUserDefaults?.set(notificationDailyOverviewTime, forKey: "notificationDailyOverviewTime")
			TelemetryManager.send("notificationDailyOverviewTimeChanged", with: [
				"notificationDailyOverviewTime": "\(notificationDailyOverviewTime)"
			])
		}
	}
	@Published var notificationDailyOverviewMinimumValue: Double {
		didSet {
			sharedUserDefaults?.set(notificationDailyOverviewMinimumValue, forKey: "notificationDailyOverviewMinimumValue")
			TelemetryManager.send("notificationDailyOverviewMinimumValueChanged", with: [
				"minimumValue": "\(notificationDailyOverviewMinimumValue)"
			])
		}
	}
	
	// Saved UV data
	var data: [UV] {
		get {
			guard let data = try? sharedUserDefaults?.getObject(forKey: "uvData", castTo: [UV].self) else {
				return []
			}
			return data
		}
		set {
			sharedUserDefaults?.removeObject(forKey: "uvData")
			try? sharedUserDefaults?.setObject(newValue, forKey: "uvData")
		}
	}

	// MARK: - Public methods
	
	static func loadLastLocation() -> Location? {
		try? UserDefaults(suiteName: UserData.suiteName)?.getObject(forKey: "lastLocation", castTo: Location.self)
	}
	
	static func saveLocation(_ location: Location) {
		UserDefaults(suiteName: UserData.suiteName)?.removeObject(forKey: "lastLocation")
		try? UserDefaults(suiteName: UserData.suiteName)?.setObject(location, forKey: "lastLocation")
	}
	
	static func clearLastLocation() {
		UserDefaults(suiteName: UserData.suiteName)?.removeObject(forKey: "lastLocation")
	}
	
	// MARK: - Private methods
	
	// The model's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {
		self.firstLaunch = sharedUserDefaults?.object(forKey: "firstLaunch") as? Bool ?? true
		self.hasOpenedLocationSheet = sharedUserDefaults?.object(forKey: "hasOpenedLocationSheet") as? Bool ?? false
		self.defaultLocation = sharedUserDefaults?.object(forKey: "defaultLocation") as? CLLocationCoordinate2D
		self.colorScheme = sharedUserDefaults?.object(forKey: "colorScheme") as? Int ?? 0
		self.shareLocation = sharedUserDefaults?.object(forKey: "shareLocation") as? Bool ?? true
		
		self.notifications = sharedUserDefaults?.object(forKey: "notifications") as? Bool ?? false
		self.notificationHighLevels = sharedUserDefaults?.object(forKey: "notificationHighLevels") as? Bool ?? false
		self.notificationHighLevelsMinimumValue = sharedUserDefaults?.object(forKey: "notificationHighLevelsMinimumValue") as? Double ?? 3
		
		self.notificationDailyOverview = sharedUserDefaults?.object(forKey: "notificationDailyOverview") as? Bool ?? false
		self.notificationDailyOverviewTime = sharedUserDefaults?.object(forKey: "notificationDailyOverviewTime") as? Int ?? 9
		self.notificationDailyOverviewMinimumValue = sharedUserDefaults?.object(forKey: "notificationDailyOverviewMinimumValue") as? Double ?? 3
		
		// Saved UV data
		self.data = []
		if let savedItems = sharedUserDefaults?.data(forKey: "data") {
			if let decodedItems = try? JSONDecoder().decode([UV].self, from: savedItems) {
				self.data = decodedItems
			}
		}
	}
}
