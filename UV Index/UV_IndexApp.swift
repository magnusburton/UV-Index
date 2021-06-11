//
//  UV_IndexApp.swift
//  UV Index
//
//  Created by Magnus Burton on 2021-06-11.
//

import SwiftUI

@main
struct UV_IndexApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
