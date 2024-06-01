//
//  CurrentLocationTabView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-02.
//

import SwiftUI
import AppIntents

struct CurrentLocationTabView: View {
	@ObservedObject var store: Store
	@EnvironmentObject private var userData: UserData
	
	@Environment(\.displayScale) private var displayScale
	
	@StateObject private var model: LocationModel
	
	init(_ store: Store) {
		self.store = store
		
		_model = StateObject(wrappedValue: LocationModel(store.currentLocation, isUserLocation: true))
	}
	
	var body: some View {
		DataView(model: model)
		.onChange(of: store.currentLocation) { _, newValue in
			guard let newLocation = newValue else {
				return
			}
			
			model.updateLocation(newLocation)
		}
		.onChange(of: userData.notifications) { _, newValue in
			userData.notificationHighLevels = false
			userData.notificationDailyOverview = false
			
			scheduleNotifications()
		}
		.onChange(of: userData.notificationHighLevels) { _, newValue in
			guard newValue == true else { return }
			scheduleNotifications()
		}
		.onChange(of: userData.notificationHighLevelsMinimumValue) {
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverview) { _, newValue in
			guard newValue == true else { return }
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverviewMinimumValue) {
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverviewTime) {
			scheduleNotifications()
		}
		.onChange(of: userData.shareLocation) {
			render()
		}
		.onAppear {
			render()
		}
		.onChange(of: model.data) {
			render()
		}
		.task {
			let intent = GetUVIndexAtLocation()
			IntentDonationManager.shared.donate(intent: intent)
		}
	}
	
	private func scheduleNotifications() {
		Task { await model.scheduleNotifications() }
	}
	
	@MainActor
	func render() {
		guard let data = model.data.first(where: { $0.interval.contains(.now) }) else {
			debugPrint("Failed to find valid data")
			return
		}
		
		let renderer = ImageRenderer(
			content: ImageShareView(uv: data, location: model.location)
				.environmentObject(userData)
				.environment(\.locale, .autoupdatingCurrent)
		)
		
		// make sure and use the correct display scale for this device
		renderer.scale = displayScale
		
		if let uiImage = renderer.uiImage {
			store.renderedCurrentLocationImage = Image(uiImage: uiImage)
		}
	}
}

struct CurrentLocationTabView_Previews: PreviewProvider {
    static var previews: some View {
		CurrentLocationTabView(.shared)
			.environmentObject(UserData.shared)
    }
}
