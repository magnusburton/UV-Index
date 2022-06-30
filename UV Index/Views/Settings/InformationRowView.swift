//
//  InformationRowView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-03-30.
//

import SwiftUI

struct InformationRowView: View {
	@State private var collapsed = true
	
	let type: InformationType
	
	init(_ type: InformationType) {
		self.type = type
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			Button(
				action: {
					withOptionalAnimation(.easeOut) {
						self.collapsed.toggle()
					}
				},
				label: {
					HStack {
						self.title
						
						Spacer()
					}
				}
			)
			.buttonStyle(PlainButtonStyle())
			
			Text(type.content)
			
			HStack {
				Spacer()
				
				Text("uv.faq.source \(type.source)")
					.font(.footnote)
					.foregroundColor(.secondary)
			}
		}
		.padding(.vertical, 8)
	}
	
	private var title: Text {
		Text(type.title)
			.font(.headline)
	}
}

struct InformationRowView_Previews: PreviewProvider {
	static var previews: some View {
		InformationRowView(.introduction)
			.previewLayout(.fixed(width: 350, height: 200))
	}
}

enum InformationType: CaseIterable {
	case introduction
	case protection
}

extension InformationType: Identifiable {
	var id: String {
		"\(self.title)"
	}
}

extension InformationType {
	var title: LocalizedStringKey {
		switch self {
		case .introduction:
			return "uv.faq.1.title"
		case .protection:
			return "uv.faq.2.title"
		}
	}
	
	var content: LocalizedStringKey {
		switch self {
		case .introduction:
			return "uv.faq.1.content"
		case .protection:
			return "uv.faq.2.content"
		}
	}
	
	var source: String {
		return String(localized: "uv.faq.source.who")
	}
}
