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
	let model = DataModel.shared
	
	private let client = apiClient()
	
	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(
			date: Date(),
			uv: UV(index: 4, date: Date())
		)
	}
	
	func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		let entry = SimpleEntry(
			date: Date(),
			uv: UV(index: 4, date: Date())
		)
		completion(entry)
	}
	
	func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		Task {
			var entries: [SimpleEntry] = []
			
			if await !model.widgetAuthorized {
				logger.debug("Model not authorized for location services")
				
				let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(24*3600)))
				completion(timeline)
				return
			}
			
			logger.debug("Getting current location")
			
			let placemarkOrNil = await model.requestCurrentLocation()
			
			guard let placemark = placemarkOrNil,
				  let coordinates = placemark.location?.coordinate else {
				let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(24*3600)))
				completion(timeline)
				return
			}
			
			let data: [UV]
			
			do {
				data = try await self.client.fetch(at: coordinates.asCoordinate)
			} catch {
				logger.error("Failed to fetch UV data with error \(error.localizedDescription)")
				
				data = []
			}
			
			logger.debug("Generating widget entries")
			
//			var previousZero = false
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
				
				if chunk.count == 1 {
					entry = SimpleEntry(date: date,
											uv: uv,
											relevance: .init(score: score,
															 duration: 3600-1))
				} else {
					let last = chunk.last!
					let duration = DateInterval(start: first.date,
												end: last.date.addingTimeInterval(3600-1)).duration
					
					entry = SimpleEntry(date: date,
										uv: uv,
										relevance: .init(score: score,
														 duration: duration))
				}
				
				entries.append(entry)
			}
			
			logger.debug("Generated \(entries.count, privacy: .public) widget entries")
			
			let timeline = Timeline(entries: entries, policy: .after(.now.addingTimeInterval(6*3600)))
			completion(timeline)
		}
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let uv: UV
	var relevance: TimelineEntryRelevance? = nil
}

struct IntervalEntry: TimelineEntry {
	var date: Date {
		interval.start
	}
	let interval: DateInterval
	let uv: UV
	var relevance: TimelineEntryRelevance? = nil
}

struct WidgetEntryView: View {
	@Environment(\.widgetFamily) var family
	var entry: Provider.Entry
	
	@ViewBuilder
	var body: some View {
		switch family {
			case .systemSmall:
				SmallUVWidget(uv: entry.uv)
			default:
				SmallUVWidget(uv: entry.uv)
		}
	}
}

struct SmallUVWidget: View {
	var uv: UV

	var body: some View {
		ZStack {
			Color.secondarySystemBackground
			
			VStack(alignment: .leading, spacing: -12) {
				Text("Currently")
					.font(.subheadline.bold())
					.padding(.top, 16)
				
				HStack {
					GradientText(
						text: Text(uvString)
							.font(.system(size: 80, weight: .heavy, design: .rounded)),
						gradient: LinearGradient(gradient: Gradient(colors: [uvColor, uvColor, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
					)
					
					Spacer()
				}
				
				Spacer()
				
				Text(uv.description)
					.foregroundColor(.secondary)
					.font(.caption)
					.padding(.bottom, 16)
				
			}
			.padding(.leading, 16)
			

//			.clipShape(ContainerRelativeShape()
//						.inset(by: 8))
		}
	}
	
	private var uvString: String {
		"\(uv.index)"
	}
	
	private var uvColor: Color {
		uv.color
	}
}

@main
struct UVWidget: Widget {
	let kind: String = "UVIndexWidget"
	
	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: Provider()) { entry in
			WidgetEntryView(entry: entry)
		}
		.configurationDisplayName("UV Index")
		.description("widget.currentLocation.description")
		.supportedFamilies([.systemSmall])
	}
}

struct Widget_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 0, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 2, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 4, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 7, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 11, date: Date())))
		}
		.environment(\.colorScheme, .dark)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
		
		Group {
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 0, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 2, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 4, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 6, date: Date())))
			WidgetEntryView(entry: SimpleEntry(date: Date(), uv: UV(index: 11, date: Date())))
		}
		.environment(\.colorScheme, .light)
		.previewContext(WidgetPreviewContext(family: .systemSmall))
		.previewLayout(.sizeThatFits)
	}
}
