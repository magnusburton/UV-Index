//
//  SmallUVWidget.swift
//  WidgetExtension
//
//  Created by Magnus Burton on 2023-07-11.
//

import SwiftUI

struct SmallUVWidget: View {
	var uv: UV
	
    var body: some View {
		SmallUVWidgetView(uv: uv)
			.containerBackground(for: .widget) {
				Color.secondarySystemBackground
			}
    }
}
