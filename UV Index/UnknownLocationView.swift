//
//  UnknownLocationView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-02.
//

import SwiftUI
import CoreLocationUI

struct UnknownLocationView: View {
	@ObservedObject var store: Store
	
    var body: some View {
		VStack(alignment: .leading) {
			Label("location.permission.denied.title", systemImage: "location.slash.fill")
				.font(.headline)
				.labelStyle(.titleAndIcon)
			
			Text("location.permission.denied.description")
				.multilineTextAlignment(.leading)
				.fixedSize(horizontal: false, vertical: true)
				.font(.subheadline)
			
			Text("location.permission.denied.description2")
				.multilineTextAlignment(.leading)
				.fixedSize(horizontal: false, vertical: true)
				.font(.footnote)
				.foregroundColor(.secondary)
			
			HStack {
				Spacer()
				
				VStack(alignment: .trailing) {
					LocationButton(.shareMyCurrentLocation) {
						store.enableLocationFeatures()
					}
					.tint(.accentColor.opacity(0.6))
					.font(.subheadline)
					.cornerRadius(5)
					.fontWeight(.regular)
					.environment(\.layoutDirection, .rightToLeft)
					.foregroundColor(.white)
					
					Button {
						openLocationSettings()
					} label: {
						Label("location.permission.denied.label", systemImage: "chevron.right")
					}
					.buttonStyle(.borderedProminent)
					.fontWeight(.medium)
					.font(.callout)
					.environment(\.layoutDirection, .rightToLeft)
				}
			}
		}
    }
	
	private func openLocationSettings() {
		guard let url = URL(string: UIApplication.openSettingsURLString) else {
			return
		}
		guard UIApplication.shared.canOpenURL(url) else {
			return
		}
		
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
}

struct UnknownLocationView_Previews: PreviewProvider {
    static var previews: some View {
		UnknownLocationView(store: .shared)
    }
}
