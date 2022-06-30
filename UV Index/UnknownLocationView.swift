//
//  UnknownLocationView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-05-02.
//

import SwiftUI

struct UnknownLocationView: View {
    var body: some View {
		GroupBox("location.permission.denied.title") {
			HStack {
				Text("location.permission.denied.description")
					.multilineTextAlignment(.leading)
				
				Spacer()
			}
			
			Button(action: openLocationSettings, label: {
				Label("location.permission.denied.label", systemImage: "location")
			})
			.buttonStyle(.borderedProminent)
		}
    }
	
	private func openLocationSettings() {
		if let url = URL(string: UIApplication.openSettingsURLString) {
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
			}
		}
	}
}

struct UnknownLocationView_Previews: PreviewProvider {
    static var previews: some View {
		UnknownLocationView()
    }
}
