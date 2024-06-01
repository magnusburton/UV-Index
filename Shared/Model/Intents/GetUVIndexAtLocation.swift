//
//  GetUVIndexAtLocation.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-09-08.
//

import Foundation
import AppIntents
import SwiftUI
import CoreLocation

struct GetUVIndexAtLocation: AppIntent, PredictableIntent, WidgetConfigurationIntent {
	static var title: LocalizedStringResource = "Current UV Index"
	static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
	
	static var description = IntentDescription("Returns the current UV Index at a chosen location.")
	
	@Parameter(title: "Location")
	var location: CLPlacemark?
	
	static var openAppWhenRun: Bool = false
	
	static var parameterSummary: some ParameterSummary {
		Summary("UV Index in \(\.$location)")
	}
	
	static var predictionConfiguration: some IntentPredictionConfiguration {
		IntentPrediction(parameters: (\.$location)) { location in
			DisplayRepresentation(
				title: "UV Index",
				subtitle: "at \(location?.name ?? "my location")"
			)
		}
	}
	
	func perform() async throws -> some IntentResult & ReturnsValue<Int> & ShowsSnippetView & ProvidesDialog {
		let chosenLocation: CLPlacemark
		
		if let location {
			chosenLocation = location
		} else {
			do {
				chosenLocation = try await LocationManager.shared.requestLocation().placemark
			} catch {
				chosenLocation = try await $location.requestValue()
			}
		}
		
		let data = try await fetch(from: chosenLocation)
		
		guard let first = data.first else {
			throw LocationError.noData
		}
		
		let uvColor = UV(index: first.index, date: .now).color
		
		return .result(value: first.index, dialog: "It's currently index \(first.index)") {
			GradientText(
				text: Text(String(first.index))
					.font(.system(size: 120, weight: .heavy, design: .rounded)),
				gradient: LinearGradient(gradient: Gradient(colors: [uvColor, uvColor, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
			)
		}
	}
	
	private func fetch(from placemark: CLPlacemark) async throws -> [UV] {
		guard let location = placemark.location else {
			throw LocationError.noData
		}
		
		let weatherManager = WeatherManager.shared
		
		return try await weatherManager.fetch(at: location)
	}
}


