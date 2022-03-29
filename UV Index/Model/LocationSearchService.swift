//
//  LocationSearchService.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import Foundation
import Combine
import MapKit

class LocationSearchService: ObservableObject {
	
	enum LocationStatus: Equatable {
		case idle
		case noResults
		case isSearching
		case error(String)
		case result
	}
	
	@Published var query: String = ""
	@Published private(set) var status: LocationStatus = .idle
	@Published private(set) var searchResults: [MKMapItem] = []
	
	private var queryCancellable: AnyCancellable?
	private let request = MKLocalSearch.Request()
	
	init() {
		queryCancellable = $query
			.receive(on: DispatchQueue.main)
			// Debounce search
			.debounce(for: .milliseconds(250), scheduler: RunLoop.main, options: nil)
			.sink(receiveValue: { query in
				self.request.naturalLanguageQuery = query
				self.request.pointOfInterestFilter = .init(including: [.airport, .nationalPark, .university])
				self.request.resultTypes = .address
				
				if !query.isEmpty && query.count > 1 {
					self.status = .isSearching
					self.search(self.request)
				} else {
					self.status = .idle
					self.searchResults = []
				}
			})
	}
	
	private func search(_ request: MKLocalSearch.Request) {
		Task {
			let search = MKLocalSearch(request: request)
			
			do {
				let response = try await search.start()

				await updateStatus(response.mapItems.isEmpty ? .noResults : .result)
				await updateResults(response.mapItems)
			} catch {
				await updateStatus(.error(error.localizedDescription))
				debugPrint("Error searching for locations with error: \(error.localizedDescription)")
			}
		}
	}
	
	@MainActor
	private func updateStatus(_ status: LocationStatus) {
		self.status = status
	}
	
	@MainActor
	private func updateResults(_ results: [MKMapItem]) {
		self.searchResults = results
	}
}
