//
//  LocationTabView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-28.
//

import SwiftUI
import AppIntents

struct LocationTabView: View {
	@StateObject private var model: LocationModel
	
	let location: Location
	
	init(location: Location) {
		self.location = location
		_model = StateObject(wrappedValue: LocationModel(location, isUserLocation: false))
	}
	
	var body: some View {
		DataView(model: model)
			.task {
				let intent = GetUVIndexAtLocation()
				intent.location = location.placemark
				IntentDonationManager.shared.donate(intent: intent)
			}
	}
}

struct LocationTabView_Previews: PreviewProvider {
	static var previews: some View {
		let stockholm = Location(title: "Stockholm", subtitle: "Sweden",
										coordinates: Coordinate(latitude: 59.3279943,
																longitude: 18.054674),
										timeZone: .current)
		
		LocationTabView(location: stockholm)
	}
}
