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
    
    var imageCacheUrl: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(appInfo.packageName).png")
    }
    
    init(appInfo: AppInfoElement) {
        self.appInfo = appInfo
        _userDefinedAppName = .init(initialValue: appInfo.appName)
    }
    
    private func getImageFromCache() throws -> Data? {
        return try? Data(contentsOf: imageCacheUrl)
    }
    
    private func getImageFromServer() async throws -> Data {
        // Download Icon
        let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/icon?appId=\(appInfo.packageName)")!
        var (data, _) = try await URLSession.shared.data(from: url)
        let imageUrlResponse = try JSONDecoder().decode(GetImageUrlResponse.self, from: data)
        (data, _) = try await URLSession.shared.data(from: URL(string: imageUrlResponse.image)!)
        
        // Save Icon to Cache
        try saveImageToCache(cacheImageData: data)
        return data
    }
    
    private func saveImageToCache(cacheImageData: Data) throws {
        try cacheImageData.write(to: imageCacheUrl)
    }
    
    func forceRefreshIcon() async {
        do {
            imageData = try await getImageFromServer()
        } catch {
            viewError = error
        }
    }
    
    func getImage() async {
        do {
            if let cacheData = try getImageFromCache() {
                imageData = cacheData
            } else {
                imageData = try await getImageFromServer()
            }
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
