//
//  AppInfoDetailViewModel.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/12.
//

import SwiftUI

@MainActor
class AppInfoDetailViewModel: ObservableObject {
    @Published var imageData: Data? = nil
    @Published var imageLoading: Bool = true
    @Published var showAlert: Bool = false
    @Published var viewError: Error? = nil
    @Published var userDefinedAppName: String
    
    var appInfo: AppInfoElement
    
    init(appInfo: AppInfoElement) {
        self.appInfo = appInfo
        _userDefinedAppName = .init(initialValue: appInfo.appName)
    }
    
    func getImage() async {
        let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/icon?appId=\(appInfo.packageName)")!
        do {
            var (data, _) = try await URLSession.shared.data(from: url)
            let imageUrlResponse = try JSONDecoder().decode(GetImageUrlResponse.self, from: data)
            (data, _) = try await URLSession.shared.data(from: URL(string: imageUrlResponse.image)!)
            imageData = data
        } catch {
            viewError = error
        }
        imageLoading = false
    }
    
    func saveIcon() {
        guard let fileUrl = showSavePanel() else { return }
        do {
            try imageData?.write(to: fileUrl)
        } catch {
            viewError = error
        }
    }
    
    func copyIcon() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(imageData, forType: .png)
    }
    
    private func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save app icon"
        savePanel.message = "Choose a folder and a name to save the icon."
        savePanel.nameFieldLabel = "Image file name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
}
