//
//  SmallUVWidgetView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-06-29.
//

import SwiftUI

struct SmallUVWidgetView: View {
	let uv: UV
	
	// TODO: Add color scheme preference to widgets
	
	var body: some View {
		VStack(alignment: .leading, spacing: -12) {
			Text("Currently")
				.font(.subheadline.bold())
				.unredacted()
			
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
			
		}
	}
	
	private var uvString: String {
		"\(uv.index)"
	}
	
	private var uvColor: Color {
		uv.color
	}
}
