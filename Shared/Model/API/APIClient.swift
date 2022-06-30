//
//  APIClient.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import Foundation
import CoreLocation

enum apiError: Error {
	case requestFailed
	case responseUnsuccessful(statusCode: Int)
	case invalidData
	case jsonParsingFailure
	case invalidURL
}

actor apiClient {
	fileprivate let key = "1c82fcda6f77a913c3a3a87c5067cd42"
	
	lazy var baseUrl: URL = {
		return URL(string: "https://api.darksky.net/forecast/\(self.key)/")!
	}()
	
	let decoder = JSONDecoder()
	let session: URLSession
	
	private init(configuration: URLSessionConfiguration) {
		self.session = URLSession(configuration: configuration)
	}
	
	convenience init() {
		self.init(configuration: .default)
	}
	
	func fetch(at coordinate: Coordinate) async throws -> [UV] {
		guard let url = URL(string: coordinate.description, relativeTo: baseUrl) else {
			throw apiError.invalidURL
		}
		
		let request = URLRequest(url: url)
		
		return try await withCheckedThrowingContinuation { continuation in
			let task = session.dataTask(with: request) { data, response, error in
				if let data = data {
					guard let httpResponse = response as? HTTPURLResponse else {
						continuation.resume(throwing: apiError.requestFailed)
						return
					}
					
					guard httpResponse.statusCode == 200 else {
						continuation.resume(throwing: apiError.invalidData)
						return
					}
					
					do {
						let weather = try self.decoder.decode(Weather.self, from: data)
						let uvWeather = weather.hourly.data.map {
							UV(index: $0.uvIndex, date: Date(timeIntervalSince1970: $0.time))
						}
						
						continuation.resume(returning: uvWeather)
					} catch let error {
						continuation.resume(throwing: error)
					}
				} else if let error = error {
					continuation.resume(throwing: error)
				}
			}
			
			task.resume()
		}
	}
}
