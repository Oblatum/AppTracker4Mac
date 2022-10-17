//
//  UpdaterView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 13/9/2022.
//

import SwiftUI
import Sparkle

final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

//struct CheckForUpdatesView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        CheckForUpdatesView(updater: SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil))
//    }
//}
