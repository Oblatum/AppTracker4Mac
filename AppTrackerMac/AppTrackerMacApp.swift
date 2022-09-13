//
//  AppTrackerMacApp.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/10.
//

import SwiftUI
import Sparkle

@main
struct AppTrackerMacApp: App {
//    let persistenceController = PersistenceController.shared
    
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            SearchView(appInfoResponse: .empty)
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
