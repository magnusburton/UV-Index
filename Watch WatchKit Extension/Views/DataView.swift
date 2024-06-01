//
//  DataView.swift
//  Watch WatchKit Extension
//
//  Created by Magnus Burton on 2022-07-24.
//

import SwiftUI

struct DataView: View {
	@ObservedObject var store: Store
	@EnvironmentObject private var userData: UserData
	
	@StateObject private var model: LocationModel
	
	init(_ store: Store) {
		self.store = store
		
		_model = StateObject(wrappedValue: LocationModel(store.currentLocation, isUserLocation: true))
	}
	
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DataView_Previews: PreviewProvider {
    static var previews: some View {
		DataView(.shared)
			.environmentObject(UserData.shared)
    }
}
