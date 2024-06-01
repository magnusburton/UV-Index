//
//  UpcomingUVListView.swift
//  WidgetExtension
//
//  Created by Magnus Burton on 2023-07-11.
//

import SwiftUI
import Algorithms

struct UpcomingUVListView: View {
	
	var uv: [UV]
	
    var body: some View {
		VStack(alignment: .leading) {
			if filteredUV.count > 0 {
				Text("Currently")
					.font(.subheadline.bold())
					.unredacted()
				
				ForEach(filteredUV, id: \.self) { item in
					SectionedUVListView(uv: item)
				}
			} else {
				Text("No upcoming UV.")
					.font(.subheadline.bold())
					.unredacted()
			}
		}
    }
	
	private var filteredUV: [UV] {
		guard let firstDate = uv.first?.date else {
			// No data
			return []
		}
		let calendar = Calendar.current
		
		let prefix = uv
			.lazy
			.filter({ $0.index > 0 && calendar.isDate($0.date, inSameDayAs: firstDate) })
			.prefix(5)
		
		return Array(prefix)
	}
}

private struct SectionedUVListView: View {
	var uv: UV
	
	var body: some View {
		HStack {
			Text((uv.date..<uv.endDate).formatted(.interval.hour()))
				.font(.caption2)
				.foregroundColor(.secondary)
			
			Spacer()
			
			GradientText(
				text: Text("\(uv.index)")
					.font(.system(.headline, design: .rounded, weight: .heavy)),
				gradient: LinearGradient(gradient: Gradient(colors: [uv.color, uv.color, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
			)
			
			Spacer()
		}
	}
}
