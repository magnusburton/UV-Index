//
//  BackgroundManager.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-09.
//

import Foundation
import BackgroundTasks

extension DataModel {
	public func registerAppRefresh() {
		guard !backgroundTasksRegistered else { return }
		
		logger.debug("Registering background tasks")
		
		BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.magnusburton.UV-Index.refresh", using: nil) { task in
			self.handleAppRefresh(task: task as! BGAppRefreshTask)
		}
		backgroundTasksRegistered = true
	}
	
	func scheduleAppRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: "com.magnusburton.UV-Index.refresh")
		
		// Fetch no earlier than 60 minutes from now.
		request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
		
		logger.debug("Scheduling app refresh")
		
		do {
			try BGTaskScheduler.shared.submit(request)
		} catch {
			logger.error("Could not schedule app refresh: \(error.localizedDescription)")
		}
	}
	
	func handleAppRefresh(task: BGAppRefreshTask) {
		// Schedule a new refresh task.
		scheduleAppRefresh()
		
		logger.debug("Performing app refresh")
		let asyncTask = Task {
			// Create an operation that performs the main part of the background task.
			// Start the operation.
			await updateModelWithCurrentLocation()
			
			// Inform the system that the background task is complete
			// when the operation completes.
			task.setTaskCompleted(success: true)
		}
		
		// Provide the background task with an expiration handler that cancels the operation.
		task.expirationHandler = {
			self.logger.debug("Cancelling app refresh")
			asyncTask.cancel()
		}
	}

}
