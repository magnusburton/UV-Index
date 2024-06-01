//
//  ContentView.swift
//  Watch WatchKit Extension
//
//  Created by Magnus Burton on 2022-07-24.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) private var scenePhase
	
	@EnvironmentObject private var userData: UserData
	@ObservedObject var store: Store
	
	@State private var tabSelection: TabSelection = .data
	
    var body: some View {
		TabView(selection: $tabSelection) {
			DataView(store)
				.tabItem {
					Image(systemName: "location")
				}
				.tag(TabSelection.data)
			
			SettingsView(store: store)
				.tag(TabSelection.settings)
		}
    }
	
	private enum TabSelection: Int, Hashable {
		case data = 0, settings
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(store: .shared)
			.environmentObject(UserData.shared)
	}
}
