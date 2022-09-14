//
//  DebugView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 14/9/2022.
//

import SwiftUI

struct DebugView: View {
    
    @State private var potentialError: Error?
    @State private var showAlert = false
    
    @State private var displayText = ""
    
    var body: some View {
        VStack {
            Text(displayText)
                .font(.system(.body, design: .monospaced))
            Button("Print Download Folder") {
                do {
                    let fileManager = FileManager.default
                    let dir = fileManager.temporaryDirectory
                    print("Home Directory: \(dir.path)")
                    let homeDirContents = try fileManager.contentsOfDirectory(atPath: dir.path)
                    displayText = homeDirContents.joined(separator: "\n")
                } catch {
                    potentialError = error
                    showAlert.toggle()
                }
            }
        }
        .padding()
        .alert("Error!", isPresented: $showAlert) {
            if let potentialError = potentialError {
                Text(potentialError.localizedDescription)
            }
        }

    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
