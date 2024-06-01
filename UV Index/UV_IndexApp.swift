//
//  UV_IndexApp.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI
import TelemetryClient
import os

@main
struct UV_IndexApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	@Environment(\.scenePhase) private var scenePhase
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index", category: "Root View")

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
				.onChange(of: scenePhase) { _, newPhase in
					if newPhase == .active {
						Task { await store.getNotificationStatus() }
						
						handleQuickActions(using: appDelegate)
					} else if newPhase == .background {
						// App entered background
						addDynamicQuickActions(with: store.savedLocations)
						store.scheduleAppRefresh()
					}
				}
				.onOpenURL { url in
					guard url.scheme == "uvIndex" else { return }
					
					guard let path = url.host else { return }
					
					if path == "current" {
						// Navigate to current location
						store.showCurrentLocationTab()
					}
				}
        }
		.backgroundTask(.appRefresh("com.magnusburton.UV-Index.refresh")) {
			await store.refreshAppData()
			await store.scheduleAppRefresh()
		}
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		debugPrint("didFinishLaunchingWithOptions")
		
		// Set notification delegate
		UNUserNotificationCenter.current().delegate = self
		
		return true
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
		Task {
			await Store.shared.showSheet(.settings)
		}
		
	}
}
