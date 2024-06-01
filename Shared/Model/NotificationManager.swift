//
//  NotificationManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-09.
//

import Foundation
@preconcurrency import UserNotifications
import os

actor NotificationManager {
	
	private lazy var userData = UserData.shared
	
	/// A shared data provider for use within the main app bundle.
	static let shared = NotificationManager()
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.NotificationManager",
						category: "Notifications")
	
	// A weak link to the data store.
	private weak var model: Store?
	
	// MARK: - Properties
	private let center = UNUserNotificationCenter.current()
	
	// MARK: - Initializers
	private init() {}
	
	// MARK: - Public Methods
	public func assign(_ model: Store) {
		self.model = model
	}
	
	@discardableResult
	public func requestAuthorization() async -> Bool {
		do {
			try await center.requestAuthorization(options: [.providesAppNotificationSettings, .badge, .alert])
			
			// Update notification status
			await model?.updateNotificationStatus(true)
			
			return true
		} catch {
			logger.error("Error requesting notification authorization: \(error.localizedDescription)")
			
			// Update notification status
			await model?.updateNotificationStatus(false)
			
			return false
		}
	}
	
	public func updateAuthorizationStatus() async {
		let status = await getAuthorizationStatus()
		
		// Update notification status
		await model?.updateNotificationStatus(status == .authorized)
	}
	
	private func scheduleWith(_ type: NotificationType, data: UV) async {
		let status = await getAuthorizationStatus()
		
		// Check for authorization status
		guard status == .authorized else {
			logger.debug("Scheduling of \(type, privacy: .public) not possible due to authorization")
			return
		}
		
		let content = UNMutableNotificationContent()
		var trigger: UNCalendarNotificationTrigger?
		
		logger.debug("Scheduling notification of type \(type, privacy: .public)")
		
		// Set notification title if it exist
		if let title = type.title {
			content.title = title
		}
		
		// Notification trigger date
		let triggerDate: Date
		
		// Handling high level UV notifiations
		if type == .highLevel {
			let endDate = data.endDate
			
			let localizedBody = String(localized: "Levels of index \(data.index.formatted()) until \(endDate.formatted(date: .omitted, time: .shortened))", comment: "Body of high level notifications")
			
			content.body = localizedBody
			
			// Set date for trigger
			triggerDate = data.date
			let dateComponents = Calendar.current.dateComponents([.month, .day, .hour],
																 from: triggerDate)
			
			trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
			
			logger.debug("Added notification trigger with date \(triggerDate) and body \(content.body)")
		} else {
			logger.debug("Unhandled notification type \(type, privacy: .public) in scheduleWith function")
			return
		}
		
		// Set notification category
		content.categoryIdentifier = type.identifier
		
		// With trigger set to nil, this will deliver right away.
		let request = UNNotificationRequest(identifier: "\(type.identifier)+\(triggerDate.hashValue)",
											content: content,
											trigger: trigger)
		
		// Add notification to queue
		do {
			try await center.add(request)
			
			logger.debug("Scheduled notification of type \(type, privacy: .public)")
		} catch {
			logger.error("Scheduling notification of type \(type, privacy: .public) failed with error \(error.localizedDescription)")
		}
	}
	
	/// Note: Body must be already localized.
	private func scheduleWith(_ type: NotificationType, body: String, date: Date) async {
		let status = await getAuthorizationStatus()
		
		// Check for authorization status
		guard status == .authorized else {
			logger.debug("Scheduling of \(type, privacy: .public) not possible due to authorization")
			return
		}
		
		let content = UNMutableNotificationContent()
		var trigger: UNCalendarNotificationTrigger?
		
		logger.debug("Scheduling notification of type \(type, privacy: .public)")
		
		// Set notification title if it exist
		if let title = type.title {
			content.title = title
		}
		
		// Notification trigger date
		let triggerDate: Date
		
		if type == .dailyOverview {
			content.body = body
			
			// Set date trigger
			triggerDate = date
			let dateComponents = Calendar.current.dateComponents([.month, .day, .hour],
																 from: triggerDate)
			
			trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
			
			logger.debug("Added notification trigger with date \(triggerDate) and body \(content.body)")
		} else {
			logger.debug("Unhandled notification type \(type, privacy: .public) in scheduleWith function")
			return
		}
		
		// Set notification category
		content.categoryIdentifier = type.identifier
		
		// With trigger set to nil, this will deliver right away.
		let request = UNNotificationRequest(identifier: "\(type.identifier)+\(triggerDate.hashValue)",
											content: content,
											trigger: trigger)
		
		// Add notification to queue
		do {
			try await center.add(request)
			
			logger.debug("Scheduled notification of type \(type, privacy: .public)")
		} catch {
			logger.error("Scheduling notification of type \(type, privacy: .public) failed with error \(error.localizedDescription)")
		}
	}
	
	public func disableNotifications() {
		self.removePendingNotifications()
		self.removeAllDeliveredNotifications()
	}
	
	public func removePendingNotifications() {
		logger.debug("Removing pending notifications")
		
		center.removeAllPendingNotificationRequests()
	}
	
	public func scheduleNotifications() async {
		// Remove all pending notifications
		removePendingNotifications()
		
		guard userData.notifications else {
			// Only schedule notifications if they are turned on
			return
		}
		
		if userData.notificationHighLevels {
			await scheduleHighLevelNotifications()
		}
		
		if userData.notificationDailyOverview {
			await scheduleDailyOverviewNotifications()
		}
	}
	
	// MARK: - Private Methods
	
	private func getAuthorizationStatus() async -> UNAuthorizationStatus {
		await center.notificationSettings().authorizationStatus
	}
	
	private func removeAllDeliveredNotifications() {
		logger.info("Removing delivered notifications")
		
		center.removeAllDeliveredNotifications()
	}
	
	private func scheduleHighLevelNotifications() async {
		guard let location = UserData.loadLastLocation() else {
			logger.error("Unable to schedule high level notifications due to no last location")
			return
		}
		
		logger.debug("Scheduling high level notifications")
		
		let groupedData = groupUVByIndex(from: userData.data, location: location)
		
		let threshold = Int(userData.notificationHighLevelsMinimumValue)
		let filteredData = groupedData.filter {
			$0.index >= threshold
		}
		
		// Schedule new notifications
		for item in filteredData {
			// Don't schedule notifications in the past
			if item.date < .now { continue }
			
			await scheduleWith(.highLevel, data: item)
		}
	}
	
	private func scheduleDailyOverviewNotifications() async {
		guard let location = UserData.loadLastLocation() else {
			logger.error("Unable to schedule daily overview notifications due to no location")
			return
		}
		
		let data = userData.data
		
		logger.debug("Scheduling daily overview notifications")
		
		// Set calendar for current location
		var calendar = Calendar.current
		calendar.timeZone = location.timeZone
		
		// Group by day, into chunks
		let chunkedByDay = data.chunked(by: { calendar.isDate($0.date, inSameDayAs: $1.date) })
		
		// Remove days where data is below chosen threshold
		let filteredByLowUV = chunkedByDay.filter { items in
			var maxIndex = 0
			
			for item in items {
				if item.index > maxIndex {
					maxIndex = item.index
				}
			}
			
			// Returns true if max index is above threshold
			let threshold = Int(userData.notificationDailyOverviewMinimumValue)
			return maxIndex >= threshold
		}
		
		// Schedule new notifications
		for dailyData in filteredByLowUV {
			guard let first = dailyData.first else {
				continue
			}
			
			// Generate daily description
			guard let localizedDescription = describeDay(for: location, with: data, date: first.date) else {
				logger.error("Could not process description for date \(first.date, privacy: .public)")
				continue
			}
			
			// Calculate trigger time chosen by the user
			guard let triggerDate = calendar.date(bySettingHour: userData.notificationDailyOverviewTime,
												  minute: 0,
												  second: 0,
												  of: first.date) else {
				logger.error("Could not calculate trigger date for date \(first.date, privacy: .public)")
				continue
			}
			
			await scheduleWith(.dailyOverview, body: localizedDescription, date: triggerDate)
		}
	}
	
	private func describeDay(for location: Location, with data: [UV], date: Date = .now) -> String? {
		guard data.count > 0 else {
			logger.error("No data available, cancelling description")
			return nil
		}
		
		var calendar = Calendar.current
		calendar.locale = .current
		calendar.timeZone = location.timeZone
		
		// Remove data for nonselected days
		let dataToday = data.filter {
			calendar.isDate($0.date, inSameDayAs: date)
		}
		
		// Group by index
		let grouped = groupUVByIndex(from: dataToday, location: location)
		
		// Maximum daily index
		let max = grouped.max { a, b in a.index < b.index }
		guard let max = max else {
			logger.error("No max value available, cancelling description")
			return nil
		}
		
		// Get intervals considered high
		let todayDangerData = grouped.filter {
			$0.category != .none && $0.category != .low
		}
		
		// Handle low values, if the max is considered low
		if max.category == .none || max.category == .low {
			return String(localized: "Low levels all day. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
		}
		
		// From here, we handle only dangerous levels
		guard let firstHighValue = todayDangerData.first,
			  let lastHighValue = todayDangerData.last else {
			logger.error("No first & last value available, cancelling description")
			return nil
		}
		
		// Handle moderate values
		if max.category == .moderate {
			if todayDangerData.count == 1 {
				return String(localized: "Apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "Apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise moderate levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		// Handle high values
		if max.category == .high {
			if todayDangerData.count == 1 {
				return String(localized: "High levels of UV radiation, apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "High levels of UV radiation, apply sunscreen if you're outside. Peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise moderate levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		// Handle extreme values
		if max.category == .veryHigh || max.category == .extreme {
			if todayDangerData.count == 1 {
				return String(localized: "Extreme risk of harm with peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())).")
			} else {
				return String(localized: "Extreme risk of harm with peak levels of \(max.index.formatted()) between \((max.date..<max.endDate).formatted(.interval.hour().minute())). Otherwise high levels between \((firstHighValue.date..<lastHighValue.endDate).formatted(.interval.hour().minute())).")
			}
		}
		
		return nil
	}
}

enum NotificationType {
	case highLevel, dailyOverview
	
	var identifier: String {
		switch self {
		case .highLevel:
			return "com.magnusburton.UV-Index.notification.highLevel"
		case .dailyOverview:
			return "com.magnusburton.UV-Index.notification.dailyOverview"
		}
	}
	
	var title: String? {
		switch self {
		case .highLevel:
			return String(localized: "High levels", comment: "Title for high levels notification")
		case .dailyOverview:
			return String(localized: "Upcoming UV levels", comment: "Title for daily overview notification")
		}
	}
}

extension NotificationType: Identifiable {
	var id: String {
		self.identifier
	}
}

extension NotificationType: CustomStringConvertible {
	var description: String {
		self.identifier
	}
}


// MARK: -

extension Store {
	public func requestNotifications() async {
		await notificationManager.requestAuthorization()
	}
	
	public func getNotificationStatus() async {
		await notificationManager.updateAuthorizationStatus()
	}
	
	public func updateNotificationStatus(_ authorized: Bool) async {
		self.notificationsAuthorized = authorized
		
		if !authorized {
			await notificationManager.disableNotifications()
		}
	}
}

extension LocationModel {
	public func scheduleNotifications() async {
		await notificationManager.scheduleNotifications()
	}
}
