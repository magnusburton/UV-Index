//
//  DataView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-02.
//

import SwiftUI

struct DataView: View {
	@Environment(\.scenePhase) private var scenePhase
	
	@ObservedObject var model: LocationModel
	
	var body: some View {
		HStack {
			VStack(alignment: .center) {
				Spacer()
				
				HStack {
					Spacer()
					
					GradientText(
						text: Text(uvString)
							.font(.system(size: 120, weight: .heavy, design: .rounded)),
						gradient: LinearGradient(gradient: Gradient(colors: [uvColor, uvColor, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
					)
				}
				
				Spacer()
			}
			.accessibilityLabel("UV index \(uvString)")
			
			TimeSliderView(model: model, data: filteredData)
		}
		.padding(.vertical, 70)
		.padding(.horizontal)
		.onAppear {
			self.updateTime()
		}
		.onChange(of: scenePhase) { _, newPhase in
			guard newPhase == .active else { return }
			
			self.updateTime()
		}
	}
	
	private var uvIndex: UV? {
		for uv in model.data {
			let date = uv.date
			let range = date...date.addingTimeInterval(3600)
			
			if range.contains(model.date) {
				return uv
			}
		}
		
		return nil
	}
	
	private var uvString: String {
		if let uv = uvIndex {
			return "\(uv.index)"
		}
		return "0"
	}
	
	private var uvColor: Color {
		if let uv = uvIndex {
			return uv.color
		}
		return Color(red: 0/255, green: 189/255, blue: 166/255, opacity: 1.0)
	}
	
	private var filteredData: [UV] {
		let data = model.data
		
		let calendar = Calendar.current
		let currentHour = calendar.component(.hour, from: model.now)
		let pastHour = calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: model.now) ?? model.now
		
		let range = pastHour...pastHour.addingTimeInterval(2*24*3600)
		return data.filter { range.contains($0.date) }
	}
	
	private func updateTime() {
		let sliderDate = model.date
		let newNow = Date()
		let oldNow = model.now
		model.now = newNow
		
		if sliderDate <= newNow {
			model.date = newNow
		} else {
			let timeDiff = newNow - oldNow
			
			if timeDiff >= 2*24*3600 {
				model.date = newNow
			} else {
				model.date = Date(timeInterval: timeDiff, since: model.date)
			}
		}
		
		Task {
			await model.refresh()
		}
	}
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
		let stockholm = Location(title: "Stockholm", subtitle: "Sweden",
								 coordinates: Coordinate(latitude: 59.3279943,
														 longitude: 18.054674),
								 timeZone: .current)
		
		DataView(model: .init(stockholm, isUserLocation: false))
    }
}
