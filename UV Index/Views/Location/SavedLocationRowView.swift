//
//  SavedLocationRowView.swift
//  UV Index
//
//  Created by Magnus Burton on 2023-03-16.
//

import SwiftUI

struct SavedLocationRowView: View {
	@ScaledMetric private var mapSize = 50.0
	
	let location: Location
	var currentLocation = false
	
	@State private var snapshotImage: UIImage?
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text(location.title)
				
				Text(location.subtitle)
					.font(.footnote)
				
				if currentLocation {
					Label("Current location", systemImage: "location")
						.font(.caption)
						.foregroundColor(.secondary)
						.labelStyle(.titleAndIcon)
				}
				
				Spacer()
			}
			
			Spacer()
			
			Group {
				if let image = snapshotImage {
					Image(uiImage: image)
				} else {
					ProgressView()
						.frame(width: mapSize, height: mapSize)
						.background(Color.secondary.opacity(0.1))
				}
			}
			.cornerRadius(10)
		}
		.task {
			if let image = await location.generateSnapshot(width: mapSize, height: mapSize) {
				snapshotImage = image
			}
		}
	}
}


struct SavedLocationRowView_Previews: PreviewProvider {
    static var previews: some View {
		SavedLocationRowView(location: Location(title: "Paris", subtitle: "France",
												coordinates: Coordinate(latitude: 48.8571906, longitude: 2.3529024),
												timeZone: .current))
		
		SavedLocationRowView(location: Location(title: "Paris", subtitle: "France",
												coordinates: Coordinate(latitude: 48.8571906, longitude: 2.3529024),
												timeZone: .current), currentLocation: true)
    }
}
