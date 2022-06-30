//
//  LocationSearchService.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import Foundation
import Combine
import MapKit

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
	
	enum LocationStatus: Equatable {
		case idle
		case noResults
		case isSearching
		case error(String)
		case result
	}
	
	@Published var query = ""
	@Published private(set) var status: LocationStatus = .idle
	
	var completer: MKLocalSearchCompleter
	@Published var completions: [MKLocalSearchCompletion] = []
	var cancellable: AnyCancellable?
	
	override init() {
		completer = MKLocalSearchCompleter()
		completer.resultTypes = [.address, .pointOfInterest]
		completer.pointOfInterestFilter = .init(including: [.airport])
		
		super.init()
		
		cancellable = $query.assign(to: \.queryFragment, on: self.completer)
		completer.delegate = self
	}
	
	public func getMapItem(from completion: MKLocalSearchCompletion) async -> MKMapItem? {
		let request = MKLocalSearch.Request(completion: completion)
		
		let search = MKLocalSearch(request: request)
		
		do {
			let response = try await search.start()
			
			return response.mapItems[0]
		} catch {
			debugPrint("Error searching for locations with error: \(error.localizedDescription)")
			return nil
		}
	}
	
	@MainActor
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.completions = completer.results
	}
	
	@MainActor
	private func updateStatus(_ status: LocationStatus) {
		self.status = status
	}
}

extension MKLocalSearchCompletion: Identifiable {}
