//
//  DailyOverviewSettingsView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-04.
//

import SwiftUI

struct DailyOverviewSettingsView: View {
	@EnvironmentObject private var userData: UserData
	
    var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			if userData.notificationDailyOverviewMinimumValue > 0 {
				Text("Daily reports delivered at **\(dateFromHour(hour).formatted(date: .omitted, time: .shortened))** on days with levels of **\(userData.notificationDailyOverviewMinimumValue.formatted())** or higher.")
			} else {
				Text("Daily reports delivered daily at **\(dateFromHour(hour).formatted(date: .omitted, time: .shortened))**.")
			}
			
			NotificationSliderView(value: $userData.notificationDailyOverviewMinimumValue, minimum: 0)
		}
    }
	
	private var hour: Int {
		userData.notificationDailyOverviewTime
	}
	
	private func dateFromHour(_ hour: Int) -> Date {
		Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
	}
}

struct DailyOverviewSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DailyOverviewSettingsView()
			.environmentObject(UserData.shared)
    }
}
