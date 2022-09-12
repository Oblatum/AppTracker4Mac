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
                        }
                }
                TableColumn("Package Name", value: \.packageName) { appInfo in
                    Text(appInfo.packageName)
                        .contextMenu {
                            Button("Copy package name") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appInfo.packageName, forType: .string)
                            }
                        }
                }
                TableColumn("Activity Name", value: \.activityName) { appInfo in
                    Text(appInfo.activityName)
                        .contextMenu {
                            Button("Copy activity name") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(appInfo.activityName, forType: .string)
                            }
                        }
                }
                TableColumn("Count", value: \.count) {
                    Text("\($0.count)")
                }
            } rows: {
                ForEach(appInfoResponse.items) { item in
                    TableRow(item)
                        .itemProvider({ NSItemProvider(object: item.xml as NSString) })
                }
            }
            .onChange(of: sortOrder) {
                appInfoResponse.items.sort(using: $0)
            }
            if let firstSelectedAppInfo = firstSelectedAppInfo {
                AppInfoDetailView(appInfo: firstSelectedAppInfo)
            }
        }
    }
    
    var firstSelectedAppInfo: AppInfoElement? {
        appInfoResponse.items.first { appInfo in
            appInfo.id == selectedAppInfo.first
        }
    }
}


struct SearchResultView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultView(appInfoResponse: .constant(.empty))
    }
}
