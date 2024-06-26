//
//  ContentView.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI

struct ContentView: View {
	@Environment(\.scenePhase) private var scenePhase
	
	@EnvironmentObject private var userData: UserData
	@ObservedObject var store: Store
	
	@State private var renderedImage: Image?
	
	var body: some View {
		VStack {
			HStack(spacing: 6) {
				VStack(alignment: .leading) {
					Button(action: {
						store.showSheet(.location)
						
						withOptionalAnimation {
							userData.hasOpenedLocationSheet = true
						}
					}) {
						locationLabel
					}
					.foregroundColor(.accentColor)
					.accessibilityAddTraits([.isModal])
					.lineLimit(1)
					
					if !userData.hasOpenedLocationSheet {
						Text("Press here to change location!")
							.foregroundColor(.secondary)
							.font(.footnote)
					}
				}
				
				Spacer()
				
				if let renderedImage = store.renderedCurrentLocationImage, store.tabSelection == 0 {
					ShareLink(
						item: renderedImage,
						preview: SharePreview(
							Text("Currently"),
							image: Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
						)
					)
					.labelStyle(.iconOnly)
					.font(.body.bold())
				}
				
				Button(action: {
					store.showSheet(.settings)
				}, label: {
					Image(systemName: "ellipsis.circle")
						.font(.body.bold())
						.imageScale(.large)
				})
				.accessibilityAddTraits([.isModal])
				.accessibilityLabel("Settings")
			}
			.padding([.horizontal, .top])
			.padding(.bottom, 0)
			
			TabView(selection: $store.tabSelection) {
				CurrentLocationTabView(store)
				.tabItem {
					Image(systemName: locationTabImage)
				}
				.tag(0)
				
				ForEach(Array(zip(store.savedLocations.indices, store.savedLocations)), id: \.1) { index, location in
					LocationTabView(location: location)
						.tabItem {
							Text(location.description)
						}
						.tag(index+1)
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .always))
			.indexViewStyle(.page(backgroundDisplayMode: .always))
		}
		.sheet(isPresented: $store.presentSheet, content: {
			switch store.sheet {
			case .location: LocationSheetView(store: store)
					.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
			case .settings: SettingsSheetView(store: store)
					.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
			}
		})
		.onAppear {
			userData.firstLaunch = false
		}
		.preferredColorScheme(colorSchemeFromInt(userData.colorScheme))
		.background(Color.secondarySystemBackground.ignoresSafeArea())
	}
	
	private var locationLabel: some View {
		// User on current location tab
		if store.tabSelection == 0 {
			
			// Location permissions granted?
			guard store.authorized else {
				return Label("Location permission not granted", systemImage: "location.slash.fill")
			}
			
			guard let currentLocation = store.currentLocation else {
				return Label("Unknown location", systemImage: "location.slash.fill")
			}
			
			return Label(currentLocation.description, systemImage: "location.fill")
		}
		
		guard let location = store.savedLocations.getElement(at: store.tabSelection-1) else {
			return Label("Unknown location", systemImage: "location.slash.fill")
		}
		
		return Label(location.description, systemImage: "location.fill")
	}
	
	private var locationTabImage: String {
		if store.authorized == false || store.currentLocation == nil {
			return "location.slash.fill"
		} else {
			return "location.fill"
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(store: Store.shared)
			.environmentObject(UserData.shared)
	}
}
