//
//  InfoSheetView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import SwiftUI
import SwiftUIExtensions

struct SettingsSheetView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var userData: UserData
	
	@StateObject private var locationService = LocationSearchService()
	
	@ObservedObject var store: Store
	
	var body: some View {
		NavigationView {
			Form {
				Section(content: {
					ForEach(InformationType.allCases) { type in
						InformationRowView(type)
					}
				}, header: {
					Text("UV Index")
				})
				
				Section(content: {
					
					Picker("theme.header", selection: $userData.colorScheme) {
						Text("theme.system.text")
							.tag(0)
						
						Text("theme.light.text")
							.tag(1)
						
						Text("theme.dark.text")
							.tag(2)
					}
					
				}, header: {
					Text("General settings")
				})
				
				Section(content: {
					if store.notificationsAuthorized == false {
						Button("Review notification permissions", action: requestNotifications)
					}
					
					Toggle(isOn: $userData.notifications.optionalAnimation()) {
						Label("Notifications", systemImage: "bubble.left")
					}
					.disabled(store.notificationsAuthorized == false)
					
					Toggle(isOn: $userData.notificationHighLevels.optionalAnimation()) {
						Label("High levels", systemImage: "exclamationmark.triangle")
					}
					.disabled(userData.notifications == false)
					
					if userData.notificationHighLevels {
						VStack(alignment: .leading, spacing: 0) {
							Text("Notifications sent for levels **\(userData.notificationHighLevelsMinimumValue.formatted())** and higher.")
							
							NotificationSliderView(value: $userData.notificationHighLevelsMinimumValue)
						}
					}
					
					Toggle(isOn: $userData.notificationDailyOverview.optionalAnimation()) {
						Label("Daily report", systemImage: "calendar")
					}
					.disabled(userData.notifications == false)
					
					if userData.notificationDailyOverview {
						TimePickerView()
					}
					
					if userData.notificationDailyOverview {
						DailyOverviewSettingsView()
					}
				}, header: {
					Text("Notifications")
				})
				
				Section(content: {
					Text("uv.medical")
						.padding(.vertical, 8)
				}, header: {
					Text("uv.medical.title")
				})
				
				Section {
					Text("UV Index is powered by Dark Sky")
				}
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarItems(
				trailing:
					Button("Done") {
						dismiss()
					}
			)
		}
	}
	
	private func requestNotifications() {
		Task {
			await store.requestNotifications()
		}
	}
}

struct SettingsSheetView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsSheetView(store: Store.shared)
			.environmentObject(UserData.shared)
	}
}
