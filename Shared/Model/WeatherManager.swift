//
//  WeatherManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import Foundation
import os
import CoreLocation
@preconcurrency import WeatherKit

actor WeatherManager {
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.WeatherManager",
						category: "Weather")
	
	// MARK: - Properties
	
	static let shared = WeatherManager()
	
	
	// MARK: - Initializers
	
	// The weather manager's initializer.
	private init() {}
	
	// MARK: - Public methods
	public func fetch(at location: Location) async throws -> [UV] {
		try await fetch(at: location.coordinates.asCLLocation)
	}
	
	public func fetch(at location: CLLocation) async throws -> [UV] {
		let weather = try await WeatherService.shared.weather(for: location)
		
		logger.debug("Fetched new UV data for \(location, privacy: .sensitive(mask: .hash))")
		
		return UV.from(weather)
	}
	
	
	// MARK: - Private methods
	
}
