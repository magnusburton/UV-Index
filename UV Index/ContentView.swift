//
//  ContentView.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) private var scenePhase
	
	@EnvironmentObject private var userData: UserData
	@ObservedObject var model: DataModel
//	@EnvironmentObject private var model: DataModel
	
	var body: some View {
		VStack {
			HStack {
				VStack(alignment: .leading) {
					Button(action: {
						model.sheet = .location
						model.presentSheet = true
						withAnimation {
							userData.hasOpenedLocationSheet = true
						}
					}) {
						Label(locationString, systemImage: "location.fill")
					}
					.foregroundColor(.accentColor)
					.accessibilityAddTraits([.isModal])
					
					if model.status == .searching {
						Text("Fetching data...")
							.foregroundColor(.secondary)
							.font(.footnote)
					} else if model.status == .error {
						Text("An error occured!")
							.foregroundColor(.secondary)
							.font(.footnote)
					}
					
					if !userData.hasOpenedLocationSheet {
						Text("Press here to change location!")
							.foregroundColor(.secondary)
							.font(.footnote)
					}
				}
				
				Spacer()
				
				Button(action: {
					model.sheet = .settings
					model.presentSheet = true
				}, label: {
					Image(systemName: "ellipsis.circle")
						.font(.body.bold())
						.imageScale(.large)
				})
				.accessibilityAddTraits([.isModal])
				.accessibilityLabel("Settings")
			}
			.padding()
			
			Spacer()
			
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
			
			Spacer()
			
			Text("UV Index is powered by Dark Sky")
				.padding()
				.foregroundColor(.gray)
		}
		.sheet(isPresented: $model.presentSheet, content: {
			switch model.sheet {
			case .location: LocationSheetView(model: model)
			case .settings: InfoSheetView(model: model)
			}
		})
		.background(Color.secondarySystemBackground
						.ignoresSafeArea())
		.onAppear {
			userData.firstLaunch = false
			
			self.updateTime()
		}
		.onChange(of: scenePhase) { newPhase in
			guard newPhase == .active else { return }
			
			self.updateTime()
		}
	}
	
	private var locationString: LocalizedStringKey {
		let authorized = model.authorized
		
		if !authorized {
			return LocalizedStringKey("Location permission not granted")
		}
		
		if let title = model.locationTitle {
			return "\(title)" as LocalizedStringKey
		}
		
		return LocalizedStringKey("Unknown location")
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
			await model.fetchUV()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(model: DataModel.shared)
			.environmentObject(UserData.shared)
	}
}
