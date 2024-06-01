//
//  SmallUVWidgetWithError.swift
//  WidgetExtension
//
//  Created by Magnus Burton on 2023-03-18.
//

import SwiftUI
import WidgetKit

struct SmallUVWidgetWithError: View {
	let error: Error
	
	// TODO: Add color scheme preference to widgets
	
	var body: some View {
		VStack(alignment: .leading, spacing: -12) {
			Text("Oops!")
				.font(.subheadline.bold())
				.unredacted()
			
			HStack {
				GradientText(
					text: Text("?")
						.font(.system(size: 80, weight: .heavy, design: .rounded)),
					gradient: LinearGradient(gradient: Gradient(colors: [color, color, .secondarySystemBackground]), startPoint: .topTrailing, endPoint: .bottomLeading)
				)
				
				Spacer()
			}
			
			Spacer()
			
			Text(error.localizedDescription)
				.foregroundColor(.secondary)
				.font(.caption)
		}
		.containerBackground(for: .widget) {
			Color.secondarySystemBackground
		}
	}
	
	private var color: Color {
		UV.color(from: 8)
	}
}


struct SmallUVWidgetWithError_Previews: PreviewProvider {
    static var previews: some View {
		SmallUVWidgetWithError(error: LocationError.noPermission)
			.previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
