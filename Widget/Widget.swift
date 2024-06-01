//
//  Widget.swift
//  Widget
//
//  Created by Magnus Burton on 2021-10-11.
//

import WidgetKit
import SwiftUI
import Algorithms
import AppIntents
import os

struct Provider: TimelineProvider {
	let logger = Logger(subsystem: "com.magnusburton.UV-Index.WidgetProvider",
						category: "Widget")
	
	private var locationManager = WidgetLocationManager.shared
	private var weatherManager = WeatherManager.shared
	private var userData = UserData.shared
	
	func placeholder(in context: Context) -> UVEntry {
		UVEntry(
			date: Date(),
			result: .success([UV(index: 4, date: .now)]),
			location: sampleLocation
		)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (UVEntry) -> ()) {
		let entry = UVEntry(
			date: Date(),
			result: .success([UV(index: 4, date: .now)]),
			location: sampleLocation
		)
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		
		guard locationManager.isAuthorizedForWidgetUpdates else {
			logger.debug("Model not authorized for location services")
			
			completion(timelineFromError(LocationError.noPermission))
			return
		}
		
		logger.debug("Getting current location")
		
		Task {
			let entries: [UVEntry]
			let location: Location
			
			do {
				location = try await locationManager.requestLocation()
			} catch {
				logger.error("Failed to retrieve location with error: \(error.localizedDescription)")
				
				completion(timelineFromError(error))
				return
			}
			
			UserData.saveLocation(location)
			
			let data: [UV]
			
			do {
				data = try await weatherManager.fetch(at: location)
			} catch {
				logger.error("Failed to fetch UV data with error: \(error.localizedDescription)")
				
				let oldData = userData.data
				
				guard oldData.count > 0 else {
					logger.error("Old data contained no data.")
					
					completion(timelineFromError(LocationError.noData))
					return
				}
				
				data = oldData
			}
			
			userData.data = data
			
			logger.debug("Generating widget entries")
			entries = generateEntries(from: data, location: location)
			
			logger.debug("Generated \(entries.count, privacy: .public) widget entries")
			
			let timeline = Timeline(entries: entries, policy: .after(.now.addingTimeInterval(6*3600)))
			completion(timeline)
		}
	}
}

struct UVEntry: TimelineEntry {
	let date: Date
	let result: Result<[UV], Error>
	let location: Location?
	var relevance: TimelineEntryRelevance?
}

struct WidgetEntryView: View {
	@Environment(\.widgetFamily) var family
	@Environment(\.widgetRenderingMode) var renderingMode
	
	var entry: Provider.Entry
	
	private let userData = UserData.shared
	
	@ViewBuilder
	var body: some View {
		Group {
			switch family {
				case .systemSmall:
					switch entry.result {
						case .success(let data):
							if let first = data.first {
								SmallUVWidget(uv: first)
									.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
									.widgetURL(URL(string: "uvIndex://current")!)
							} else {
								SmallUVWidgetWithError(error: LocationError.noData)
							}
						case .failure(let error):
							SmallUVWidgetWithError(error: error)
					}
				case .accessoryCircular:
					switch entry.result {
						case .success(let data):
							if let first = data.first {
								Gauge(value: Double(first.index), in: 0...11) {
									Text("UV")
								} currentValueLabel: {
									Text(first.index.formatted())
								}
								.gaugeStyle(.accessoryCircular)
								.widgetAccentable(true)
								.widgetURL(URL(string: "uvIndex://current")!)
							} else {
								Gauge(value: 0, in: 0...11) {
									Text("-")
								}
								.gaugeStyle(.accessoryCircular)
								.widgetAccentable(true)
							}
						case .failure(_):
							Gauge(value: 0, in: 0...11) {
								Text("-")
							}
							.gaugeStyle(.accessoryCircular)
							.widgetAccentable(true)
					}
				case .accessoryInline:
					switch entry.result {
						case .success(let data):
							if let first = data.first {
								ViewThatFits {
									Text("UV \(first.index) until \(first.endDate.formatted(date: .omitted, time: .shortened))")
									
									HStack {
										Text("UV")
										Text(first.index.formatted())
									}
								}
								.widgetURL(URL(string: "uvIndex://current")!)
							} else {
								ViewThatFits {
									Text(LocationError.noData.localizedDescription)
									
									Text("UV unavailable")
								}
							}
						case .failure(let error):
							ViewThatFits {
								Text(error.localizedDescription)
								
								Text("UV unavailable")
							}
					}
				case .accessoryRectangular:
					switch entry.result {
						case .success(let data):
							if let first = data.first {
								VStack(alignment: .leading) {
									HStack(alignment: .lastTextBaseline) {
										if renderingMode == .fullColor {
											GradientText(
												text: Text(first.index.formatted())
													.font(.system(.title, design: .rounded, weight: .heavy)),
												gradient: LinearGradient(gradient: Gradient(colors: [first.color, first.color, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
											)
										} else {
											Text(first.index.formatted())
												.font(.system(.title, design: .rounded, weight: .heavy))
												.widgetAccentable(true)
										}
										
										Text(first.description)
											.lineLimit(1...3)
										
										Spacer()
									}
								}
								.widgetURL(URL(string: "uvIndex://current")!)
							} else {
								Text(LocationError.noData.localizedDescription)
									.lineLimit(1...3)
							}
						case .failure(let error):
							Text(error.localizedDescription)
								.lineLimit(1...3)
					}
				case .systemMedium:
					switch entry.result {
						case .success(let data):
							MediumUVWidgetView(uv: data)
								.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
								.widgetURL(URL(string: "uvIndex://current")!)
						case .failure(let error):
							SmallUVWidgetWithError(error: error)
					}
				default:
					switch entry.result {
						case .success(let data):
							if let first = data.first {
								SmallUVWidget(uv: first)
									.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
									.widgetURL(URL(string: "uvIndex://current")!)
							} else {
								SmallUVWidgetWithError(error: LocationError.noData)
							}
						case .failure(let error):
							SmallUVWidgetWithError(error: error)
					}
			}
		}
		.containerBackground(Color.secondarySystemBackground, for: .widget)
	}
}

@main
struct UVWidget: Widget {
	let kind: String = "UVIndexWidget"
	
	var supportedFamilies: [WidgetFamily] {
#if os(watchOS)
		return [.accessoryCircular, .accessoryRectangular, .accessoryInline]
#else
		return [.accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall]
#endif
	}
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			WidgetEntryView(entry: entry)
				.unredacted()
		}
		.configurationDisplayName("UV Index")
		.description("widget.currentLocation.description")
		.supportedFamilies(supportedFamilies)
	}
}

struct Widget_Previews: PreviewProvider {
	static var previews: some View {
		
		Group {
			WidgetEntryView(entry: UVEntry(date: Date(), result: .failure(LocationError.noPermission), location: nil))
			
			WidgetEntryView(entry: UVEntry(date: Date(), result: .failure(LocationError.noData), location: nil))
			
			WidgetEntryView(entry: UVEntry(date: Date(), result: .failure(LocationError.noTimeZone), location: nil))
		}
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: UVEntry(date: Date(), result: .success([UV(index: 6, date: Date())]), location: sampleLocation))
		}
		.environment(\.colorScheme, .dark)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: UVEntry(date: Date(), result: .success([UV(index: 2, date: Date())]), location: sampleLocation))
		}
		.environment(\.colorScheme, .light)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: generateEntries(from: sampleFullData, location: sampleLocation).first!)
			
			WidgetEntryView(entry: UVEntry(date: Date(), result: .failure(LocationError.noData), location: nil))
		}
		.previewContext(WidgetPreviewContext(family: .systemMedium))
		.previewLayout(.sizeThatFits)
	}
}

private func generateEntries(from data: [UV], location: Location) -> [UVEntry] {
	var entries: [UVEntry] = []
	
	var calendar = Calendar.current
	calendar.timeZone = location.timeZone
	
	let chunks: [UV] = data
		.chunked(by: { $0.index == $1.index })
		.compactMap { chunk in
			guard let first = chunk.first else {
				return nil
			}
			
			let date = first.date
			let uv = first
			
			let newUV: UV
			
			if chunk.count == 1 {
				newUV = UV(index: uv.index, startDate: date, endDate: date.addingTimeInterval(3600))
			} else {
				let last = chunk.last!
				let endDate = last.date.addingTimeInterval(3600)
				
				newUV = UV(index: uv.index, startDate: date, endDate: endDate)
			}
			
			return newUV
		}
	
	for (index, uv) in chunks.enumerated() {
		// Return upcoming UV entries including the current one
		let currentAndUpcoming = Array(chunks.suffix(from: index))
		
		let relevance = TimelineEntryRelevance(score: Float(uv.index), duration: uv.duration)
		let entry = UVEntry(
			date: uv.date,
			result: .success(currentAndUpcoming),
			location: location,
			relevance: relevance
		)
		
		entries.append(entry)
	}
	
	return entries
}

private func timelineFromError(_ error: Error) -> Timeline<UVEntry> {
	let entry = UVEntry(
		date: .now,
		result: .failure(error),
		location: nil
	)
	
	return Timeline(entries: [entry], policy: .never)
}

private let sampleFullData: [UV] = [
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

private let sampleLocation = Location(
	title: "Stockholm",
	subtitle: "Sweden",
	coordinates: Coordinate(latitude: 59.3279943, longitude: 18.054674),
	timeZone: .current
)
