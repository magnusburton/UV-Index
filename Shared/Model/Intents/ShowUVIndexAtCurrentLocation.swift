//
//  ShowUVIndexAtCurrentLocation.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-09-11.
//

import Foundation
@preconcurrency import AppIntents
import CoreLocation
import WeatherKit

struct ShowUVIndexAtCurrentLocation: AppIntent {
	static let title: LocalizedStringResource = "Show the UV Index at my location"
	static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
	
	static let description = IntentDescription("Opens the app and shows the UV Index at your location.")
	
	static let openAppWhenRun: Bool = true
	
	static var parameterSummary: some ParameterSummary {
		Summary("UV Index at my location")
	}
	
	@MainActor
	func perform() async throws -> some IntentResult {
		Store.shared.showCurrentLocationTab()
		return .result()
	}
}


