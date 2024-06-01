//
//  MediumUVWidgetView.swift
//  WidgetExtension
//
//  Created by Magnus Burton on 2023-07-11.
//

import SwiftUI

struct MediumUVWidgetView: View {
	
	var uv: [UV]
	
	var body: some View {
		GeometryReader { reader in
			ZStack {
				Color.secondarySystemBackground
				
				HStack {
					Group {
						if let first = uv.first {
							SmallUVWidgetView(uv: first)
						} else {
							SmallUVWidgetWithError(error: LocationError.noData)
						}
					}
					.frame(width: reader.size.width/2)
					
					Group {
						UpcomingUVListView(uv: upcoming)
					}
					.frame(width: reader.size.width/2)
				}
				.padding(16)
			}
		}
	}
	
	private var upcoming: [UV] {
		Array(uv.dropFirst())
	}
}
