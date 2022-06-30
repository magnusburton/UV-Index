//
//  CurrentLocationTabView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-02.
//

import SwiftUI

struct CurrentLocationTabView: View {
	@ObservedObject var store: Store
	@EnvironmentObject private var userData: UserData
	
	@StateObject private var model: LocationModel
	
	init(_ store: Store) {
		self.store = store
		
		_model = StateObject(wrappedValue: LocationModel(store.currentLocation, isUserLocation: true))
	}
	
	var body: some View {
		DataView(model: model)
		.onChange(of: store.currentLocation) { newValue in
			guard let newLocation = newValue else {
				return
			}
			
			model.updateLocation(newLocation)
		}
		.onChange(of: userData.notifications) { newValue in
			userData.notificationHighLevels = false
			userData.notificationDailyOverview = false
			
			scheduleNotifications()
		}
		.onChange(of: userData.notificationHighLevels) { newValue in
			guard newValue == true else { return }
			scheduleNotifications()
		}
		.onChange(of: userData.notificationHighLevelsMinimumValue) { _ in
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverview) { newValue in
			guard newValue == true else { return }
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverviewMinimumValue) { _ in
			scheduleNotifications()
		}
		.onChange(of: userData.notificationDailyOverviewTime) { _ in
			scheduleNotifications()
		}
	}
	
	private func scheduleNotifications() {
		Task { await model.scheduleNotifications() }
	}
}

struct CurrentLocationTabView_Previews: PreviewProvider {
    static var previews: some View {
		CurrentLocationTabView(.shared)
			.environmentObject(UserData.shared)
    }
}
