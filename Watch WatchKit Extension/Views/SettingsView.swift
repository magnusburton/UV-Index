//
//  SettingsView.swift
//  Watch WatchKit Extension
//
//  Created by Magnus Burton on 2022-07-24.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var userData: UserData
	
	@ObservedObject var store: Store
	
    var body: some View {
		NavigationView {
			Form {
				// Notifications
				
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
		}
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
		SettingsView(store: .shared)
			.environmentObject(UserData.shared)
    }
}
