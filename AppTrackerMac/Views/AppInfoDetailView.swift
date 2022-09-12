//
//  AppInfoDetailView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/11.
//

import SwiftUI

struct AppInfoDetailView: View {
    
    var appInfo: AppInfoElement
    
    @State var imageUrl: URL? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(colorScheme == .light ? .white : .init(.displayP3, red: 0x1E/0xFF, green: 0x1E/0xFF, blue: 0x1E/0xFF))
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding()
                        .contextMenu {
                            Button("Save to...", action: saveIconTo)
                                .keyboardShortcut("s", modifiers: .command)
                            Button("Copy To Clipboard...", action: copyIcon)
                                .keyboardShortcut("c", modifiers: .command)
                        }
                } placeholder: {
                    ProgressView()
                }
                .frame(idealWidth: 200, maxWidth: 200, idealHeight:200, maxHeight: 200)
            }
            .frame(maxHeight: 216)
            .padding()
            
            Text(appInfo.appName)
                .textSelection(.enabled)
                .font(.headline)
            Form {
                Section {
                    TextField("Package Name", text: .constant(appInfo.packageName))
                    TextField("Activity Name", text: .constant(appInfo.activityName))
                    TextField("Appfilter.xml", text: .constant(appInfo.xml))
                }
            }
            .padding()
            Spacer()
        }
        .onAppear {
            getImageUrl()
        }
        .onChange(of: appInfo, perform: { newValue in
            getImageUrl(packageName: newValue.packageName)
        })
    }
    
    private func copyIcon() {
        guard let imageUrl = imageUrl else { return }
        Task {
            do {
                let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setData(imageData, forType: .png)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    private func saveIconTo() {
        guard let imageUrl = imageUrl, let url = showSavePanel() else { return }
        Task {
            do {
                let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                try imageData.write(to: url)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
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
    
    private func getImageUrl(packageName: String? = nil) {
        Task {
            imageUrl = nil
            let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/icon?appId=\(packageName ?? appInfo.packageName)")!
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let imageUrlResponse = try JSONDecoder().decode(GetImageUrlResponse.self, from: data)
                imageUrl = URL(string: imageUrlResponse.image)
            } catch { debugPrint(error.localizedDescription) }
        }
    }
}

struct AppInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoDetailView(appInfo: .example)
    }
}
