//
//  TimePickerView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-04.
//

import SwiftUI

struct TimePickerView: View {
	@EnvironmentObject private var userData: UserData
	
    var body: some View {
		Picker("Delivery time", selection: $userData.notificationDailyOverviewTime) {
			ForEach(4..<12) { hour in
				Text("\(dateFromHour(hour).formatted(date: .omitted, time: .shortened))")
					.tag(hour)
			}
		}
    }
	
	private func dateFromHour(_ hour: Int) -> Date {
		Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
	}
}

struct TimePickerView_Previews: PreviewProvider {
    static var previews: some View {
        TimePickerView()
			.environmentObject(UserData.shared)
    }
}
