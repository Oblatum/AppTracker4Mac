//
//  SearchView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/10.
//

import SwiftUI

struct SearchReslultView: View {
    
    @Binding var appInfoResponse: AppInfoResponse
    @State private var selectedAppInfo = Set<AppInfoElement.ID>()
    @State private var sortOrder = [KeyPathComparator(\AppInfoElement.count)]
    
    var body: some View {
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
                        Button("Copy package name") {                            NSPasteboard.general.clearContents()
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
    }
}

struct SearchView: View {
    
    @State var searchText: String = ""
    @State var appInfoResponse: AppInfoResponse
    @State var isSearching: Bool = false
    
    var body: some View {
        VStack {
            SearchReslultView(appInfoResponse: $appInfoResponse)
                .searchable(text: $searchText, prompt: "Package name...")
                .onSubmit(of: .search) {
                    print("Search!")
                    Task {
                        do { try await search()
                        } catch { print(error.localizedDescription) }
                    }
                }
        }
    }
    
    private func search() async throws {
        self.appInfoResponse = .empty
        guard let queryText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/appInfo?q=\(queryText)&per=1000&page=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        self.appInfoResponse = try JSONDecoder().decode(AppInfoResponse.self, from: data)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(appInfoResponse: .empty)
    }
}
