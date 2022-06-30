//
//  UserData.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-10-10.
//

import Foundation
import MapKit
import SwiftUI

public class UserData: ObservableObject {
	
	static let shared = UserData()
	
	// MARK: - Properties
	@Published var firstLaunch: Bool {
		didSet {
			UserDefaults.standard.set(firstLaunch, forKey: "firstLaunch")
		}
	}
	@Published var hasOpenedLocationSheet: Bool {
		didSet {
			UserDefaults.standard.set(hasOpenedLocationSheet, forKey: "hasOpenedLocationSheet")
		}
	}
	@Published var defaultLocation: CLLocationCoordinate2D? {
		didSet {
			if let defaultLocation = defaultLocation {
				UserDefaults.standard.set(defaultLocation, forKey: "defaultLocation")
			} else {
				UserDefaults.standard.removeObject(forKey: "defaultLocation")
			}
		}
	}
	@Published var colorScheme: Int {
		didSet {
			switch colorScheme {
			case 0...2:
				UserDefaults.standard.set(colorScheme, forKey: "colorScheme")
			default:
				UserDefaults.standard.removeObject(forKey: "colorScheme")
			}
		}
	}
	
	// Notifications
	@Published var notifications: Bool {
		didSet {
			UserDefaults.standard.set(notifications, forKey: "notifications")
			
			if notifications == false {
				notificationHighLevels = false
				notificationDailyOverview = false
			}
		}
	}
	@Published var notificationHighLevels: Bool {
		didSet {
			UserDefaults.standard.set(notificationHighLevels, forKey: "notificationHighLevels")
		}
	}
	@Published var notificationHighLevelsMinimumValue: Double {
		didSet {
			UserDefaults.standard.set(notificationHighLevelsMinimumValue, forKey: "notificationHighLevelsMinimumValue")
		}
	}
	
	@Published var notificationDailyOverview: Bool {
		didSet {
			UserDefaults.standard.set(notificationDailyOverview, forKey: "notificationDailyOverview")
		}
	}
	@Published var notificationDailyOverviewTime: Int {
		didSet {
			UserDefaults.standard.set(notificationDailyOverviewTime, forKey: "notificationDailyOverviewTime")
		}
	}
	@Published var notificationDailyOverviewMinimumValue: Double {
		didSet {
			UserDefaults.standard.set(notificationDailyOverviewMinimumValue, forKey: "notificationDailyOverviewMinimumValue")
		}
	}
	
	// Saved UV data
	@Published var savedLocations: [Location] {
		didSet {
			if let encoded = try? JSONEncoder().encode(savedLocations) {
				UserDefaults.standard.set(encoded, forKey: "savedLocations")
			}
		}
	}
	
	// Saved UV data
	@Published var data: [UV] {
		didSet {
			if let encoded = try? JSONEncoder().encode(data) {
				UserDefaults.standard.set(encoded, forKey: "data")
			}
		}
	}
	
	// MARK: - Private methods
	
	// The model's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {
		self.firstLaunch = UserDefaults.standard.object(forKey: "firstLaunch") as? Bool ?? true
		self.hasOpenedLocationSheet = UserDefaults.standard.object(forKey: "hasOpenedLocationSheet") as? Bool ?? false
		self.defaultLocation = UserDefaults.standard.object(forKey: "defaultLocation") as? CLLocationCoordinate2D
		self.colorScheme = UserDefaults.standard.object(forKey: "colorScheme") as? Int ?? 0
		
		self.notifications = UserDefaults.standard.object(forKey: "notifications") as? Bool ?? false
		self.notificationHighLevels = UserDefaults.standard.object(forKey: "notificationHighLevels") as? Bool ?? false
		self.notificationHighLevelsMinimumValue = UserDefaults.standard.object(forKey: "notificationHighLevelsMinimumValue") as? Double ?? 3
		
		self.notificationDailyOverview = UserDefaults.standard.object(forKey: "notificationDailyOverview") as? Bool ?? false
		self.notificationDailyOverviewTime = UserDefaults.standard.object(forKey: "notificationDailyOverviewTime") as? Int ?? 9
		self.notificationDailyOverviewMinimumValue = UserDefaults.standard.object(forKey: "notificationDailyOverviewMinimumValue") as? Double ?? 3
		
		// Saves user locations
		self.savedLocations = []
		if let savedItems = UserDefaults.standard.data(forKey: "savedLocations") {
			if let decodedItems = try? JSONDecoder().decode([Location].self, from: savedItems) {
				self.savedLocations = decodedItems
			}
		}
		
		// Saved UV data
		self.data = []
		if let savedItems = UserDefaults.standard.data(forKey: "data") {
			if let decodedItems = try? JSONDecoder().decode([UV].self, from: savedItems) {
				self.data = decodedItems
			}
		}
	}
}
