//
//  AppTrackerMacApp.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/10.
//

import SwiftUI

@main
struct AppTrackerMacApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            SearchView(appInfoResponse: .empty)
//            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(replacing: .textEditing) {
                Button("Copy App Name") {
                    print("before item")
                }
                .disabled(true)
            }
        }
    }
}
