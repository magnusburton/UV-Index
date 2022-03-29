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
	private weak var model: DataModel?
	
	private let client = apiClient()
	
	
	// MARK: - Initializers
	
	// The weather manager's initializer.
	init(withModel model: DataModel) {
		self.model = model
	}
	
	// MARK: - Public methods
	public func fetch(from location: CLPlacemark) async {
		guard let coordinates = location.location?.coordinate else { return }
		
		do {
			let data = try await self.client.fetch(at: coordinates.asCoordinate)
			
			await model?.updateModel(newData: data)
		} catch {
			logger.error("Failed to fetch UV data with error \(error.localizedDescription)")
			await model?.updateWithError()
		}
	}
	
	
	// MARK: - Private methods
}
