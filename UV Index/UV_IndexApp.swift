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
	@Environment(\.scenePhase) private var scenePhase
	
	let logger = Logger(subsystem: "com.magnusburton.UV-Index", category: "Root View")

	@StateObject var model: DataModel
	
	init() {
		_model = StateObject(wrappedValue: DataModel.shared)
		
		// Register and initialize background tasks
		
	}
	
    var body: some Scene {
        WindowGroup {
			ContentView(model: model)
				.environmentObject(UserData.shared)
				.onAppear {
					model.registerAppRefresh()
				}
				.onContinueUserActivity("com.magnusburton.UV-Index.acitivity.currentUV", perform: { activity in
					logger.debug("Received request to continue user activity: \(activity)")
					
					Task {
						await model.updateModelWithCurrentLocation()
						model.setCurrentTime()
					}
				})
				.onChange(of: scenePhase) { newPhase in
					if newPhase == .background {
						model.scheduleAppRefresh()
					}
				}
        }
    }
}
