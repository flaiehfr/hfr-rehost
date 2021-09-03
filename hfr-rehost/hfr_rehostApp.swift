//
//  hfr_rehostApp.swift
//  hfr-rehost
//
//  Created by Flaie on 13/01/2021.
//

import SwiftUI

@main
struct hfr_rehostApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
