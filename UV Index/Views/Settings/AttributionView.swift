//
//  AttributionView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-09-09.
//

import SwiftUI
@preconcurrency import WeatherKit

struct AttributionView: View {
	@Environment(\.colorScheme) private var colorScheme
	
	@State private var attribution: WeatherAttribution?
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("settings.attribution.title")
				.font(.callout)
				.foregroundColor(.secondary)
			
			if let attribution, let markURL {
				AsyncImage(url: markURL) { phase in
					if let image = phase.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
					}
				}
				.frame(height: 20)
				
				
				Link("Other data sources",
					 destination: attribution.legalPageURL)
				.font(.caption)
				.foregroundColor(.secondary)
			}
		}
		.task {
			self.attribution = try? await WeatherService.shared.attribution
		}
	}
	
	private var markURL: URL? {
		colorScheme == .dark ? attribution?.combinedMarkDarkURL : attribution?.combinedMarkLightURL
	}
}

struct AttributionView_Previews: PreviewProvider {
	static var previews: some View {
		AttributionView()
			.frame(width: 150)
	}
}
