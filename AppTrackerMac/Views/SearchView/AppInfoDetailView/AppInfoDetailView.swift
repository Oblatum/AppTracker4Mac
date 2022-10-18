//
//  AppInfoDetailView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/11.
//

import UniformTypeIdentifiers
import SwiftUI

struct AppInfoDetailView: View {
    
    @StateObject var viewModel: AppInfoDetailViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(colorScheme == .light ? .white : .init(.displayP3, red: 0x1E/0xFF, green: 0x1E/0xFF, blue: 0x1E/0xFF))
                    .opacity(0.5)
                Group {
                    if let imageData = viewModel.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .contextMenu {
                                Button("Save to...") { viewModel.saveIcon() }
                                    .keyboardShortcut("s", modifiers: .command)
                                Button("Copy to Clipboard") { viewModel.copyIcon() }
                                    .keyboardShortcut("c", modifiers: .command)
                                Button("Refresh Icon") { Task { await viewModel.forceRefreshIcon() }}
                                    .keyboardShortcut("r", modifiers: .command)
                            }
                    } else if viewModel.imageLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "xmark.square.fill")
                    }
                }
                .onDrag {
                    if let imageData = viewModel.imageData {
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
                        
            Text(viewModel.appInfo.appName)
                .textSelection(.enabled)
                .font(.headline)
            
            Form {
                Section {
                    TextField("App Name", text: $viewModel.userDefinedAppName)
                }
                                
                Section {
                    TextField("Package Name", text: .constant(viewModel.appInfo.packageName))
                    TextField("Activity Name", text: .constant(viewModel.appInfo.activityName))
                    TextField("Appfilter.xml", text: .constant(viewModel.appInfo.appfilter(viewModel.userDefinedAppName)))
                    TextField("Drawable.xml", text: .constant(viewModel.appInfo.drawable(viewModel.userDefinedAppName)))
                }
                .font(Font.body.monospaced())
                
                Section() {
                    HStack {
                        Link(destination: viewModel.appInfo.playStoreUrl) {
                            Label("Play Store", image: "play.store")
                        }
                    }
                }
            }
            .padding()
            Spacer()
        }
        .task {
            await viewModel.getImage()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(viewModel.viewError?.localizedDescription ?? "Unknown Error"))
        }
    }
}

struct AppInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppInfoDetailView(viewModel: .init(appInfo: .example))
    }
}
