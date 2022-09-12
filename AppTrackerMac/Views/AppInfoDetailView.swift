//
//  AppInfoDetailView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/11.
//

import UniformTypeIdentifiers
import SwiftUI

struct AppInfoDetailView: View {
    
    var appInfo: AppInfoElement
    
    @State var imageData: Data?
    @State var imageUrl: URL? = nil
    @State var imageLoading: Bool = true
    @State var showAlert: Bool = false
    @State var viewError: Error? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(colorScheme == .light ? .white : .init(.displayP3, red: 0x1E/0xFF, green: 0x1E/0xFF, blue: 0x1E/0xFF))
                Group {
                    if let imageData = imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .contextMenu {
                                Button("Save to...", action: saveIcon)
                                    .keyboardShortcut("s", modifiers: .command)
                                Button("Copy to Clipboard", action: copyIcon)
                                    .keyboardShortcut("c", modifiers: .command)
                            }
                    } else if imageLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "xmark.square.fill")
                    }
                }
                .onDrag {
                    if let imageData = imageData {
                        return NSItemProvider(item: imageData as NSSecureCoding, typeIdentifier: UTType.png.identifier)
                    } else {
                        return NSItemProvider()
                    }
                }
                .padding()
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
        .task {
            await getImage()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(viewError?.localizedDescription ?? "Unknown Error"))
        }
    }
    
    private func getImage() async {
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
    
    private func saveIcon() {
        guard let fileUrl = showSavePanel() else { return }
        do {
            try imageData?.write(to: fileUrl)
        } catch {
            viewError = error
        }
    }
    
    private func copyIcon() {
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

struct AppInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoDetailView(appInfo: .example)
    }
}
