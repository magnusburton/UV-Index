//
//  LocationSheetView.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-09-17.
//

import SwiftUI
import CoreLocation
import MapKit
import Algorithms

struct LocationSheetView: View {
	@Environment(\.dismiss) private var dismiss
	
//	@EnvironmentObject private var model: DataModel
	@StateObject private var locationService = LocationSearchService()
	
	@ObservedObject var model: DataModel
	
    var body: some View {
		NavigationView {
			VStack {
				List {
					Button(action: { update(nil) }) {
						Label("Current location", systemImage: "location.fill")
							.foregroundColor(.accentColor)
					}
					
					ForEach(results, id: \.self) { mapItem in
						Button(action: { update(mapItem.placemark) }) {
							LocationSheetRowView(placemark: mapItem.placemark)
						}
					}
				}
			}
			.searchable(text: $locationService.query,
						placement: .navigationBarDrawer(displayMode: .always),
						prompt: Text("Search for a city or an airport", comment: "Placeholder for textfield in location sheet"))
			.navigationTitle("Location")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarItems(
				trailing:
					Button("Done") {
						dismiss()
					}
			)
		}
    }
	
	private var results: [MKMapItem] {
		locationService.searchResults
	}
	
	private func update(_ placemark: MKPlacemark?) {
		Task {
			if let placemark = placemark {
				await model.updateModelWithCustomLocation(placemark)
			} else {
				await model.updateModelWithCurrentLocation()
			}
		}
		
		dismiss()
	}
}

struct LocationSheetView_Previews: PreviewProvider {
    static var previews: some View {
		LocationSheetView(model: DataModel.shared)
    }
}

struct LocationSheetRowView: View {
	
	let placemark: CLPlacemark
	
	var body: some View {
		VStack(alignment: .leading) {
			if let name = name {
				Text(name)
			}
			
			if let subtitle = formattedSubtitle {
				Text("\(subtitle)")
					.font(.footnote)
			}
		}
	}
	
	private var name: String? {
		placemark.name
	}
	
	private var formattedSubtitle: String? {
		placemark.formattedSubtitle
	}
}
