//
//  InfoSheetView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-08.
//

import SwiftUI

struct InfoSheetView: View {
	@Environment(\.dismiss) private var dismiss
	
//	@EnvironmentObject private var model: DataModel
	@StateObject private var locationService = LocationSearchService()
	
	@ObservedObject var model: DataModel
	
	var body: some View {
		NavigationView {
			List {
				GroupBox(content: {
					Text("The Global Solar UV Index (UVI) described in this document is a simple measure of the UV radiation level at the Earth’s surface and an indicator of the potential for skin damage. It serves as an important vehicle to raise public awareness and to alert people about the need to adopt protective measures when exposed to UV radiation.")
				}, label: {
					Label("What is an UV Index?", systemImage: "sun.max")
				})
				
				GroupBox(content: {
					
				}, label: {
					Label("What is an UV Index?", systemImage: "sun.max")
				})
				
				GroupBox(content: {
					
				}, label: {
					Label("What is an UV Index?", systemImage: "sun.max")
				})
			}
			.navigationTitle("About")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarItems(
				trailing:
					Button("Done") {
						dismiss()
					}
			)
		}
	}
}

struct InfoSheetView_Previews: PreviewProvider {
	static var previews: some View {
		InfoSheetView(model: DataModel.shared)
	}
}
