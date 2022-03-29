//
//  UserData.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-10-10.
//

import Foundation
import MapKit

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
	
	// MARK: - Private methods
	
	// The model's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {
		self.firstLaunch = UserDefaults.standard.object(forKey: "firstLaunch") as? Bool ?? true
		self.hasOpenedLocationSheet = UserDefaults.standard.object(forKey: "hasOpenedLocationSheet") as? Bool ?? false
		self.defaultLocation = UserDefaults.standard.object(forKey: "defaultLocation") as? CLLocationCoordinate2D
	}
}
