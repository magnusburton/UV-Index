//
//  AppRefresh.swift
//  UV Index
//
//  Created by Magnus Burton on 2023-04-09.
//

import Foundation
import BackgroundTasks
import NotificationCenter

extension Store {
	public func scheduleAppRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: "com.magnusburton.UV-Index.refresh")
		request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 5, to: .now)
		
		do {
			try BGTaskScheduler.shared.submit(request)
			logger.log("Background Task Scheduled!")
		} catch {
			logger.log("Scheduling background tasks with error: \(error.localizedDescription)")
			return
		}
	}
	
	public func refreshAppData() async {
		guard let location = UserData.loadLastLocation() else {
			logger.error("No saved location!")
			return
		}
		
		let weatherManager = WeatherManager.shared
		
		let weather = try? await weatherManager.fetch(at: location)
		
		if let weather {
			userData.data = weather
			
			// Schedule notifications
			await notificationManager.scheduleNotifications()
		}
	}
}
