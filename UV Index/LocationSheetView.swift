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

private let mapSize: Double = 50

struct LocationSheetView: View {
	@Environment(\.dismiss) private var dismiss
	
	@StateObject private var locationService = LocationSearchService()
	
	@ObservedObject var store: Store
	
    var body: some View {
		NavigationView {
			VStack {
				List {
					locationErrorView
					
					Section(header: Text("My locations")) {
						ForEach(store.savedLocations) { location in
							Button(action: {
								store.showLocationTab(location)
								store.presentSheet = false
							}) {
								SavedLocationRowView(location: location)
							}
							.swipeActions(edge: .trailing) {
								Button(role: .destructive) {
									withOptionalAnimation {
										store.removeLocation(location)
									}
								} label: {
									Label("Delete", systemImage: "trash")
								}
							}
						}
					}
					
					Section(header: Text("Search results")) {
						ForEach(results, id: \.self) { completion in
							Button(action: { update(completion) }) {
								LocationSheetRowView(completion: completion)
							}
						}
					}
				}
				.listStyle(.grouped)
			}
			.searchable(text: $locationService.query,
						placement: .navigationBarDrawer(displayMode: .always),
						prompt: Text("Search for a city or an airport"))
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
	
	private var results: [MKLocalSearchCompletion] {
		locationService.completions
	}
	
	private func update(_ completion: MKLocalSearchCompletion?) {
		guard let completion = completion else {
			return
		}
		
		Task {
			let mapItem = await locationService.getMapItem(from: completion)
			
			guard let location = Location(from: mapItem) else {
				return
			}
			
			withOptionalAnimation {
				store.addLocation(location)
			}
			
			dismiss()
		}
	}
	
	@ViewBuilder
	private var locationErrorView: some View {
		if store.authorized == false || store.currentLocation == nil {
			UnknownLocationView()
		}
	}
}

struct LocationSheetView_Previews: PreviewProvider {
    static var previews: some View {
		LocationSheetView(store: Store.shared)
		
		Group {
			SavedLocationRowView(location: Location(title: "Paris", subtitle: "France",
													coordinates: Coordinate(latitude: 48.8571906, longitude: 2.3529024),
													timeZone: .current))
			
			SavedLocationRowView(location: Location(title: "New York", subtitle: "USA",
													coordinates: Coordinate(latitude: 40.780881, longitude: -73.9595061),
													timeZone: .current))
		}
		.previewLayout(.fixed(width: 300, height: 200))
    }
}

struct LocationSheetRowView: View {
	let completion: MKLocalSearchCompletion
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text(attributedTitle)
				
				Text(attributedSubtitle)
					.font(.footnote)
			}
			
			Spacer()
			
			Image(systemName: "plus.circle")
				.accessibilityHidden(true)
		}
	}
	
	private var attributedTitle: AttributedString {
		highlightString(rangeArray: completion.titleHighlightRanges,
						string: completion.title)
	}
	
	private var attributedSubtitle: AttributedString {
		highlightString(rangeArray: completion.subtitleHighlightRanges,
						string: completion.subtitle)
	}
	
	private func highlightString(rangeArray: [NSValue], string: String) -> AttributedString {
		var attributedString = AttributedString(string)
		
		let ranges: [Range<AttributedString.Index>] = rangeArray.compactMap {
			guard let range = $0 as? NSRange else {
				return nil
			}
			
			return attributedString.range(from: range)
		}
		
		for range in ranges {
			attributedString[range].inlinePresentationIntent = .stronglyEmphasized
		}
		
		return attributedString
	}
}

struct SavedLocationRowView: View {
	let location: Location
	
	@State private var snapshotImage: UIImage?
	
	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text(location.title)
				
				Text(location.subtitle)
					.font(.footnote)
				
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
