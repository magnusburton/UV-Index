//
//  QuickActions.swift
//  UV Index
//
//  Created by Magnus Burton on 2023-03-16.
//

import Foundation
import UIKit

@MainActor
func addDynamicQuickActions(with locations: [Location]) {
	let defaultActions = [
		UIApplicationShortcutItem(
			type: "addLocation",
			localizedTitle: String(localized: "Add location"),
			localizedSubtitle: nil,
			icon: UIApplicationShortcutIcon(systemImageName: "plus"),
			userInfo: nil
		),
		UIApplicationShortcutItem(
			type: "currentLocation",
			localizedTitle: String(localized: "Current location"),
			localizedSubtitle: nil,
			icon: UIApplicationShortcutIcon(systemImageName: "location"),
			userInfo: nil
		)
	]
	
	UIApplication.shared.shortcutItems = defaultActions + locations.map { $0.shortcutItem }
}

@MainActor
func handleQuickActions(using appDelegate: AppDelegate) {
	guard let shortcutItem = appDelegate.shortcutItem else {
		return
	}
	
	if shortcutItem.type == "currentLocation" {
		Store.shared.showCurrentLocationTab()
	} else if shortcutItem.type == "addLocation" {
		Store.shared.showSheet(.location)
	} else {
		// Try to show location tab with supplied Id
		let locationId = shortcutItem.type
		
		try? Store.shared.showLocationTab(locationId)
	}
}

extension AppDelegate {
	var shortcutItem: UIApplicationShortcutItem? { AppDelegate.shortcutItem }
	
	fileprivate static var shortcutItem: UIApplicationShortcutItem?
	
	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		if let shortcutItem = options.shortcutItem {
			AppDelegate.shortcutItem = shortcutItem
		}
		
		let sceneConfiguration = UISceneConfiguration(
			name: "Scene Configuration",
			sessionRole: connectingSceneSession.role
		)
		sceneConfiguration.delegateClass = SceneDelegate.self
		
		return sceneConfiguration
	}
}

private final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	func windowScene(
		_ windowScene: UIWindowScene,
		performActionFor shortcutItem: UIApplicationShortcutItem,
		completionHandler: @escaping (Bool) -> Void
	) {
		AppDelegate.shortcutItem = shortcutItem
		completionHandler(true)
	}
}
