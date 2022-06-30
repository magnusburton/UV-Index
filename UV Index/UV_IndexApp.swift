//
//  UV_IndexApp.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI
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
				.onChange(of: scenePhase) { newPhase in
					if newPhase == .active {
						Task { await store.getNotificationStatus() }
					} else if newPhase == .background {
						store.scheduleAppRefresh()
					}
				}
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		// Set notification delegate
		UNUserNotificationCenter.current().delegate = self
		
		// Register and initialize background tasks
		Store.shared.registerAppRefresh()
		
		return true
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
		let store = Store.shared
		
		store.sheet = .settings
		store.presentSheet = true
	}
}
