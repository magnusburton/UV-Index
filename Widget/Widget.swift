//
//  Widget.swift
//  Widget
//
//  Created by Magnus Burton on 2021-10-11.
//

import WidgetKit
import SwiftUI
import Algorithms
import os

struct Provider: TimelineProvider {
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.WidgetProvider",
						category: "Widget")

	private var store: Store = .shared
	private var locationManager = LocationManager.shared
	private var userData = UserData.shared

	private let client = apiClient()

	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(
			date: Date(),
			uv: UV(index: 4, date: Date()),
			fullData: sampleFullData,
			location: sampleLocation
		)
	}

	func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let entry = SimpleEntry(
			date: Date(),
			uv: UV(index: 4, date: Date()),
			fullData: sampleFullData,
			location: sampleLocation
		)
		completion(entry)
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		
		let entries: [SimpleEntry]
		
		guard locationManager.isAuthorizedForWidgetUpdates else {
			logger.debug("Model not authorized for location services")

			entries = []

			let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(24*3600)))
			completion(timeline)
			return
		}

		logger.debug("Getting current location")

		Task {
			let entries: [SimpleEntry]
			let location: Location

			do {
				location = try await locationManager.requestLocation()
			} catch {
				logger.error("Failed to retrieve location with error: \(error.localizedDescription)")

				entries = []
				let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(24*3600)))

				completion(timeline)
				return
			}

			let data: [UV]

			do {
				data = try await self.client.fetch(at: location.coordinates)
			} catch {
				logger.error("Failed to fetch UV data with error: \(error.localizedDescription)")

				entries = []

				let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(24*3600)))

				completion(timeline)
				return
			}

			logger.debug("Generating widget entries")

			entries = generateEntries(from: data, location: location)

			logger.debug("Generated \(entries.count, privacy: .public) widget entries")

			let timeline = Timeline(entries: entries, policy: .after(.now.addingTimeInterval(6*3600)))
			completion(timeline)
		}
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let uv: UV
	let fullData: [UV]
	let location: Location
	var relevance: TimelineEntryRelevance?
}

struct WidgetEntryView: View {
	@Environment(\.widgetFamily) var family
	var entry: Provider.Entry
	
	private let userData = UserData.shared

	@ViewBuilder
	var body: some View {
		switch family {
		case .systemSmall:
			SmallUVWidget(uv: entry.uv)
				.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
//		case .systemMedium:
//			MediumUVWidget(entry: entry)
		default:
			SmallUVWidget(uv: entry.uv)
		}
	}
}

@main
struct UVWidget: Widget {
	let kind: String = "UVIndexWidget"
	
	var supportedFamilies: [WidgetFamily] {
		return [.systemSmall, /*.systemMedium*/]
	}

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			WidgetEntryView(entry: entry)
		}
		.configurationDisplayName("UV Index")
		.description("widget.currentLocation.description")
		.supportedFamilies(supportedFamilies)
	}
}

struct Widget_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 0, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 4, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 7, date: Date()), fullData: sampleFullData, location: sampleLocation))
		}
		.environment(\.colorScheme, .dark)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 2, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 6, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 11, date: Date()), fullData: sampleFullData, location: sampleLocation))
		}
		.environment(\.colorScheme, .light)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 0, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 4, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 7, date: Date()), fullData: sampleFullData, location: sampleLocation))
		}
		.environment(\.colorScheme, .dark)
		.previewContext(WidgetPreviewContext(family: .systemMedium))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 2, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 6, date: Date()), fullData: sampleFullData, location: sampleLocation))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 11, date: Date()), fullData: sampleFullData, location: sampleLocation))
		}
		.environment(\.colorScheme, .light)
		.previewContext(WidgetPreviewContext(family: .systemMedium))
		.previewLayout(.sizeThatFits)
	}
}

private func generateEntries(from data: [UV], location: Location) -> [SimpleEntry] {
	var entries: [SimpleEntry] = []
	
	var calendar = Calendar.current
	calendar.timeZone = location.timeZone
	
	let chunks = data.chunked(by: { $0.index == $1.index })
	for chunk in chunks {
		if chunk.isEmpty {
			continue
		}
		
		let first = chunk.first!
		
		let date = first.date
		let uv = first
		let score = Float(first.index)
		let entry: SimpleEntry
		
		let fullDayData = data.filter({ calendar.isDate($0.date, inSameDayAs: date) })
		
		if chunk.count == 1 {
			let relevanceScore = TimelineEntryRelevance(score: score, duration: 3600-1)
			
			entry = SimpleEntry(date: date, uv: uv, fullData: fullDayData, location: location, relevance: relevanceScore)
		} else {
			let last = chunk.last!
			let endDate = last.date.addingTimeInterval(3600-1)
			let interval = DateInterval(start: date, end: endDate)
			
			let relevanceScore = TimelineEntryRelevance(score: score, duration: interval.duration)
			
			entry = SimpleEntry(date: date, uv: uv, fullData: fullDayData, location: location, relevance: relevanceScore)
		}
		
		entries.append(entry)
	}
	
	return entries
}

private let sampleFullData = [
	UV(index: 0, date: .now.addingTimeInterval(3600*0)),
	UV(index: 0, date: .now.addingTimeInterval(3600*1)),
	UV(index: 0, date: .now.addingTimeInterval(3600*2)),
	UV(index: 0, date: .now.addingTimeInterval(3600*3)),
	UV(index: 0, date: .now.addingTimeInterval(3600*4)),
	UV(index: 0, date: .now.addingTimeInterval(3600*5)),
	UV(index: 0, date: .now.addingTimeInterval(3600*6)),
	UV(index: 0, date: .now.addingTimeInterval(3600*7)),
	UV(index: 1, date: .now.addingTimeInterval(3600*8)),
	UV(index: 1, date: .now.addingTimeInterval(3600*9)),
	UV(index: 2, date: .now.addingTimeInterval(3600*10)),
	UV(index: 3, date: .now.addingTimeInterval(3600*11)),
	UV(index: 4, date: .now.addingTimeInterval(3600*12)),
	UV(index: 4, date: .now.addingTimeInterval(3600*13)),
	UV(index: 3, date: .now.addingTimeInterval(3600*14)),
	UV(index: 3, date: .now.addingTimeInterval(3600*15)),
	UV(index: 2, date: .now.addingTimeInterval(3600*16)),
	UV(index: 1, date: .now.addingTimeInterval(3600*17)),
	UV(index: 1, date: .now.addingTimeInterval(3600*18)),
	UV(index: 1, date: .now.addingTimeInterval(3600*19)),
	UV(index: 0, date: .now.addingTimeInterval(3600*20)),
	UV(index: 0, date: .now.addingTimeInterval(3600*21)),
	UV(index: 0, date: .now.addingTimeInterval(3600*22)),
	UV(index: 0, date: .now.addingTimeInterval(3600*23))
]

private let sampleLocation = Location(title: "Stockholm", subtitle: "Sweden",
								 coordinates: Coordinate(latitude: 59.3279943,
														 longitude: 18.054674),
								 timeZone: .current)
