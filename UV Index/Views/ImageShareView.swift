//
//  ImageShareView.swift
//  UV Index
//
//  Created by Magnus Burton on 2023-03-20.
//

import SwiftUI

struct ImageShareView: View {
	@EnvironmentObject private var userData: UserData
	
	let uv: UV
	let location: Location?
	
	var body: some View {
		ZStack {
			Color.secondarySystemBackground
			
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
				
				Group {
					if let location, userData.shareLocation == true {
						Label(location.description, systemImage: "location.fill")
					} else {
						Text(uv.description)
					}
				}
				.padding(.top, 15)
				.foregroundColor(.secondary)
				.font(.caption)
			}
			.padding(16)
		}
	}
	
	private var uvString: String {
		uv.index.formatted()
	}
	
	private var uvColor: Color {
		uv.color
	}
}

#if DEBUG
struct ImageShareView_Previews: PreviewProvider {
    static var previews: some View {
		ImageShareView(uv: UV(index: 0, date: Date(timeIntervalSinceNow: -1571)), location: .init(title: "Stockholm", subtitle: "Sverige", coordinates: .sampleCity, timeZone: .current))
			.environmentObject(UserData.shared)
    }
}
#endif
