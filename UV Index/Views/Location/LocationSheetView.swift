//
//  LocationSheetView.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-09-17.
//

import SwiftUI
import CoreLocation
@preconcurrency import MapKit
import Algorithms
import AppIntents

struct LocationSheetView: View {
	@Environment(\.dismiss) private var dismiss
	
	@StateObject private var locationService = LocationSearchService()
	@State private var locationSheetLocation: Location?
	
	@ObservedObject var store: Store
	
	var body: some View {
		NavigationView {
			VStack {
				//				SiriTipView(intent: GetUVIndexAtLocation())
				//					.padding(.horizontal)
				
				List {
					locationErrorView
					
					Section(header: Text("My locations")) {
						if let currentLocation = store.currentLocation {
							Button(action: currentLocationTapped) {
								SavedLocationRowView(location: currentLocation, currentLocation: true)
							}
						}
						
						ForEach(store.savedLocations) { location in
							Button(action: {
								savedLocationTapped(location)
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
					.isHidden(store.savedLocations.isEmpty && store.currentLocation == nil, remove: true)
					
					Section(header: Text("Search results")) {
						if results.isEmpty {
							ContentUnavailableView.search
						} else {
							ForEach(results.compactMap({ $0 }), id: \.self) { completion in
								Button(action: { preview(completion) }) {
									LocationSheetRowView(completion: completion)
								}
							}
						}
					}
					.isHidden(locationService.query.isEmpty, remove: true)
				}
				.listStyle(.grouped)
				.sheet(item: $locationSheetLocation) { location in
					NavigationView {
						LocationTabView(location: location)
							.navigationBarItems(
								leading: Button("Cancel") {
									locationSheetLocation = nil
								},
								trailing:
									Button("Add") {
										addFavorite(location)
									}
							)
					}
				}
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
	
	private func addFavorite(_ location: Location) {
		withOptionalAnimation {
			locationSheetLocation = nil
			store.addLocation(location)
		}
		
		dismiss()
		locationService.query = ""
	}
	
	private func preview(_ completion: MKLocalSearchCompletion) {
		Task {
			await preview(completion)
		}
	}
	
	private func preview(_ completion: MKLocalSearchCompletion) async {
		let mapItem = await locationService.getMapItem(from: completion)
		
		guard let mapItem else {
			debugPrint("Invalid mapItem")
			return
		}
		
		guard let location = Location(from: mapItem) else {
			debugPrint("Invalid mapItem")
			return
		}
		
		

		debugPrint("Opening mapItem")
		withOptionalAnimation {
			locationSheetLocation = location
		}
	}
	
	@ViewBuilder
	private var locationErrorView: some View {
		if store.authorized == false || store.currentLocation == nil {
			UnknownLocationView(store: store)
		}
	}
	
	private func currentLocationTapped() {
		store.showCurrentLocationTab()
	}
	
	private func savedLocationTapped(_ location: Location) {
		store.showLocationTab(location)
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
		VStack(alignment: .leading) {
			Text(attributedTitle)
			
			Text(attributedSubtitle)
				.font(.footnote)
		}
		.foregroundColor(.primary)
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
