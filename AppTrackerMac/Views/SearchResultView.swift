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
                            Button("Copy app name") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appInfo.appName, forType: .string)
                            }
                            .keyboardShortcut("c", modifiers: .command)
                        }
                }
                TableColumn("Package Name", value: \.packageName) { appInfo in
                    Text(appInfo.packageName)
                        .contextMenu {
                            Button("Copy package name") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appInfo.packageName, forType: .string)
                            }
                            .keyboardShortcut("c", modifiers: .command)
                        }
                }
                TableColumn("Activity Name", value: \.activityName) { appInfo in
                    Text(appInfo.activityName)
                        .contextMenu {
                            Button("Copy activity name") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appInfo.activityName, forType: .string)
                            }
                            .keyboardShortcut("c", modifiers: .command)
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
            } else {
                AppInfoDetailPlaceholderView()
            }
        }
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
