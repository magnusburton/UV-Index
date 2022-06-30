//
//  WeatherManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import Foundation
import os
import CoreLocation

actor WeatherManager {
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.WeatherManager",
						category: "Weather")
	
	// MARK: - Properties
	
	// A weak link to the data model.
	private weak var model: LocationModel?
	
	private let client = apiClient()
	
	
	// MARK: - Initializers
	
	// The weather manager's initializer.
	init(withModel model: LocationModel) {
		self.model = model
	}
	
	// MARK: - Public methods
	@discardableResult
	public func fetch(from location: Location) async -> [UV]? {
		do {
			let data = try await self.client.fetch(at: location.coordinates)
			
			// Update the model
			await model?.updateModel(newData: data)
			
			// Return data
			return data
		} catch {
			logger.error("Failed to fetch UV data with error \(error.localizedDescription)")
			
			await model?.updateWithError()
			return nil
		}
	}
	
	
	// MARK: - Private methods
	
}
