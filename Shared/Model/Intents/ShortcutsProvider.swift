//
//  ShortcutsProvider.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-09-08.
//

import Foundation
import AppIntents
import CoreLocation

struct UVIndexShortcutsProvider: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		return [
			AppShortcut(
				intent: GetUVIndexAtLocation(),
				phrases: [
					"Get current \(.applicationName)",
					"Get \(.applicationName)",
					"What is the \(.applicationName)?",
					"Get current \(.applicationName) at \(\.$location)",
					"Get \(.applicationName) at \(\.$location)",
					"What is the \(.applicationName) at \(\.$location)?"
				],
				shortTitle: "Current UV Index",
				systemImageName: "sun.max"
			)
		]
	}
}

func updateRelevantIntents() async {
	var relevantIntents = [RelevantIntent]()
	
	async let store = Store.shared
	if let currentLocation = await store.currentLocation {
		let intent = GetUVIndexAtLocation()
		
		let result = try? await WeatherManager.shared.fetch(at: currentLocation)
		
		for uv in result ?? [] {
			if uv.index > 0 {
				let relevantUVIndexContext = RelevantContext.date(from: uv.date, to: uv.endDate)
				
				let relevantUVIndexIntent = RelevantIntent(intent, widgetKind: "UVIndexWidget", relevance: relevantUVIndexContext)
				relevantIntents.append(relevantUVIndexIntent)
			}
		}
		
		// Wake up intent
		let relevantUVIndexContext = RelevantContext.sleep(.wakeup)
		let relevantUVIndexIntent = RelevantIntent(intent, widgetKind: "UVIndexWidget", relevance: relevantUVIndexContext)
		relevantIntents.append(relevantUVIndexIntent)
	}
	
	try? await RelevantIntentManager.shared.updateRelevantIntents(relevantIntents)
}
