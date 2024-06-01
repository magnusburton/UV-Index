//
//  NotificationSliderView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-04-04.
//

import SwiftUI
import SwiftUIExtensions

struct NotificationSliderView: View {
	@Binding var value: Double
	var minimum: Int = 2
	
    var body: some View {
		HSlider(value: $value, in: Double(minimum)...maxUVIndexValue, step: 1, track:
					LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .leading, endPoint: .trailing)
			.frame(height: 5)
			.cornerRadius(5)
		)
		.onChange(of: value) {
			let feedback = UISelectionFeedbackGenerator()
			feedback.selectionChanged()
		}
    }
	
	private let maxUVIndexValue: Double = 11
	
	// TODO: Make colors to left of slider greyish
	private var gradientColors: [Color] {
		(minimum...Int(maxUVIndexValue)).map {
			UV(index: $0, date: .now).color
		}
	}
}

struct NotificationSliderView_Previews: PreviewProvider {
	static var previews: some View {
		NotificationSliderView(value: .constant(4))
			.previewLayout(.fixed(width: 250, height: 100))
    }
}
