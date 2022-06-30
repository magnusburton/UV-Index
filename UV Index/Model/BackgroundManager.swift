//
//  BackgroundManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-09.
//

import Foundation
import BackgroundTasks

extension Store {
	public func registerAppRefresh() {
		// Exit if tasks already registered
		guard backgroundTasksRegistered == false else { return }
		
		logger.debug("Registering background tasks")
		
		// Register background tasks
		let taskScheduled = BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.magnusburton.UV-Index.refresh", using: nil) { task in
			self.handleAppRefresh(task: task as! BGAppRefreshTask)
		}
		
		// Returns true if scheduled
		backgroundTasksRegistered = taskScheduled
		
		if taskScheduled == false {
			logger.error("Tasks not scheduled")
		} else {
			logger.debug("Background tasks registered")
		}
	}
	
	func scheduleAppRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: "com.magnusburton.UV-Index.refresh")
		
		// Fetch no earlier than 2 hours from now.
		request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 3600)
		
		logger.debug("Scheduling app refresh")
		
		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			logger.error("Could not schedule app refresh: \(error.localizedDescription)")
			return
		}
		
		logger.debug("Successfully scheduled app refresh")
	}
	
	func handleAppRefresh(task: BGAppRefreshTask) {
		// Schedule a new refresh task.
		scheduleAppRefresh()
		
		logger.debug("Performing app refresh")
		let asyncTask = Task {
			// Create an operation that performs the main part of the background task.
			// Start the operation.
			let success = await appRefreshTaskAndScheduleNotifications()
			
			// Inform the system that the background task is complete
			// when the operation completes.
			task.setTaskCompleted(success: success)
		}
		
		// Provide the background task with an expiration handler that cancels the operation.
		task.expirationHandler = {
			self.logger.debug("Cancelling app refresh")
			asyncTask.cancel()
		}
	}
}

// MARK: - Background app refresh

extension Store {
	private func appRefreshTaskAndScheduleNotifications() async -> Bool {
		let location: Location
		
		do {
			location = try await locationManager.requestLocation()
		} catch {
			logger.error("Failed to retrieve location with error: \(error.localizedDescription)")
			
			// Return false indicating failure
			return false
		}
		
		let model = LocationModel(location, isUserLocation: true)
		await model.refresh(ignoreRecentFetches: true)
		
		// Schedule notifications that may be sent in the future
		await model.scheduleNotifications()
		
		// Return success
		return true
	}
}
