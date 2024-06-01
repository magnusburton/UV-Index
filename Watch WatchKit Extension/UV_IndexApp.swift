//
//  UV_IndexApp.swift
//  Watch WatchKit Extension
//
//  Created by Magnus Burton on 2022-07-24.
//

import SwiftUI
import os

@main
struct UV_IndexApp: App {
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.watch", category: "Root View")
	
	@Environment(\.scenePhase) private var scenePhase
	
	@StateObject var store: Store
	@StateObject var userData: UserData
	
	init() {
		_store = StateObject(wrappedValue: Store.shared)
		_userData = StateObject(wrappedValue: UserData.shared)
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView(store: store)
				.environmentObject(userData)
				.onChange(of: scenePhase) { newPhase in
					if newPhase == .active {
						Task { await store.getNotificationStatus() }
					} else if newPhase == .background {
						// App entered background
					}
				}
		}
	}
}
