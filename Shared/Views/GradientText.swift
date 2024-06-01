//
//  GradientText.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-12.
//

import SwiftUI

struct GradientText: View {
	var text: Text
	var gradient: LinearGradient = LinearGradient(gradient: Gradient(colors: [.purple, .blue,.green,]), startPoint: .topTrailing, endPoint: .bottomLeading)
	
	var body: some View{
		text
			.overlay(gradient.mask(text))
	}
	
	
}

struct GradientText_Previews: PreviewProvider {
    static var previews: some View {
		GradientText(
			text: Text("Gradient Text Effect 123"),
			gradient: LinearGradient(gradient: Gradient(colors: [.green, .blue,.purple,]), startPoint: .topTrailing, endPoint: .bottomLeading)
		)
    }
}
