//
//  LocationTabView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-28.
//

import SwiftUI

struct LocationTabView: View {
	@StateObject private var model: LocationModel
	
	init(location: Location) {
		_model = StateObject(wrappedValue: LocationModel(location, isUserLocation: false))
	}
	
	var body: some View {
		DataView(model: model)
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
