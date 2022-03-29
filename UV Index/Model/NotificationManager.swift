//
//  NotificationManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-09.
//

import Foundation
import UserNotifications
import os

actor NotificationManager {
	
	/// A shared data provider for use within the main app bundle.
	static let shared = NotificationManager()
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.NotificationManager",
						category: "Notifications")
	
	// MARK: - Properties
	
	private let center = UNUserNotificationCenter.current()
	
	// MARK: - Public Methods
	
	@discardableResult
	public func requestAuthorization(provisional: Bool = true) async -> Bool {
		do {
			if provisional {
				try await center.requestAuthorization(options: [.providesAppNotificationSettings, .provisional, .alert])
			} else {
				try await center.requestAuthorization(options: [.providesAppNotificationSettings, .alert])
			}
			return true
		} catch {
			logger.error("Error requesting notification authorization: \(error.localizedDescription)")
			return false
		}
	}
	
	public func getAuthorizationStatus() async -> UNAuthorizationStatus {
		await center.notificationSettings().authorizationStatus
	}
	
	public func send(_ type: NotificationType) async {
		let content = UNMutableNotificationContent()
		content.title = "New data available"
		content.body = "Fresh data has been fetched and are available in the app!"
		
		// With trigger set to nil, this will deliver right away.
		let request = UNNotificationRequest(identifier: "com.magnusburton.UV-Index.notification.update",
											content: content,
											trigger: nil)
		
		// Add notification to queue
		try? await center.add(request)
	}
	
	// MARK: - Private methods
	
	// The manager's initializer. Do not call this method.
	// Use the shared instance instead.
	private init() {}
}

enum NotificationType {
	case alert, update
}
