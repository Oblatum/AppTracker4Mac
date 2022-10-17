//
//  SearchResultView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/11.
//

import SwiftUI

struct SearchResultView: View {
    
    @Binding var appInfoResponse: AppInfoResponse
    @State private var selectedAppInfo = Set<AppInfoElement.ID>()
    @State private var sortOrder = [KeyPathComparator(\AppInfoElement.count)]
    
    var body: some View {
        HSplitView {
            Table(selection: $selectedAppInfo, sortOrder: $sortOrder) {
                TableColumn("App Name", value: \.appName) { appInfo in
                    Text(appInfo.appName)
                        .contextMenu {
                            makeButton(appInfo: appInfo, for: \.appName)
                        }
                }
                TableColumn("Package Name", value: \.packageName) { appInfo in
                    Text(appInfo.packageName)
                        .contextMenu {
                            makeButton(appInfo: appInfo, for: \.packageName)
                        }
                }
                TableColumn("Activity Name", value: \.activityName) { appInfo in
                    Text(appInfo.activityName)
                        .contextMenu {
                            makeButton(appInfo: appInfo, for: \.activityName)
                        }
                }
                TableColumn("Count", value: \.count) {
                    Text("\($0.count)")
                }
            } rows: {
                ForEach(appInfoResponse.items) { item in
                    TableRow(item)
                        .itemProvider({ NSItemProvider(object: item.appfilter() as NSString) })
                }
            }
            .onChange(of: sortOrder) {
                appInfoResponse.items.sort(using: $0)
            }
            if selectedAppInfoList.isEmpty == false {
                ScrollView {
                    ForEach(selectedAppInfoList) {
                        AppInfoDetailView(viewModel: .init(appInfo: $0))
                    }
                }
                .frame(minWidth: 300, idealWidth: 300)
            } else {
                AppInfoDetailPlaceholderView()
            }
        }
    }
        
    private func makeButton(appInfo: AppInfoElement, for keyPath: KeyPath<AppInfoElement, String>) -> some View {
        let label = AppInfoElement.propertyName(for: keyPath) ?? .empty
        return Button("Copy \(label)") {
            copyAppInfo(appInfo: appInfo, for: keyPath)
        }
        .keyboardShortcut("c", modifiers: .command)
    }
    
    private func copyAppInfo(appInfo: AppInfoElement, for keyPath: KeyPath<AppInfoElement, String>){
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(appInfo[keyPath: keyPath], forType: .string)
    }
    
    var selectedAppInfoList: [AppInfoElement] {
        return selectedAppInfo.compactMap { id in
            appInfoResponse.items.first { $0.id == id }
        }
    }
}

struct AppInfoDetailPlaceholderView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Select an app")
                .lineLimit(1)
                .foregroundColor(.secondary)
                .font(.largeTitle)
            Spacer()
        }
        .padding()
        .frame(width: 200)
    }
}

struct SearchResultView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultView(appInfoResponse: .constant(.empty))
    }
}
