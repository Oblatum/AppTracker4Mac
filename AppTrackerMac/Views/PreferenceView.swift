//
//  PreferenceView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 14/9/2022.
//

import SwiftUI

struct PreferenceView: View {
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .padding()
        .frame(width: 450, height: 250)
    }
}

struct GeneralSettingsView: View {
    
    @State private var cacheSize: String = "Calculating..."
    
    @State private var showAlert: Bool = false
    @State private var viewError: Error? = nil

    
    var body: some View {
        Form {
            Section("Cache") {
                HStack {
                    Text("Cache size: \(cacheSize)")
                    Spacer()
                    Button("Clear cache") { clearCache() }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(viewError?.localizedDescription ?? "Unknown Error"))
        }
        .task {
            calculateCacheSize()
        }
    }
    
    private func calculateCacheSize() {
        cacheSize = "\(Double(FileManager.default.temporaryDirectory.folderSize()) / 1E6) MB"
    }
    
    private func clearCache() {
        let cacheFolder = FileManager.default.temporaryDirectory
        do {
            try FileManager.default.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil)
                .forEach { url in
                    try FileManager.default.removeItem(at: url)
            }
            calculateCacheSize()
        } catch {
            viewError = error
            showAlert.toggle()
        }
    }
}

struct PreferenceView_Previews: PreviewProvider {
    static var previews: some View {
        PreferenceView()
    }
}
