//
//  VersionView.swift
//  UV Index
//
//  Created by Magnus Burton on 2022-11-05.
//

import SwiftUI

struct VersionView: View {
    var body: some View {
		HStack {
			Spacer()
			
			if let version = Bundle.main.releaseVersionNumber {
				if let build = Bundle.main.buildVersionNumber {
					Text("\(version) (\(build))")
				} else {
					Text(version)
				}
			}
			
			Spacer()
		}
    }
}

struct VersionView_Previews: PreviewProvider {
    static var previews: some View {
        VersionView()
    }
}
