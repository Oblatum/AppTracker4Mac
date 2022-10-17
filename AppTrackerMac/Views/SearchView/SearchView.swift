//
//  SearchView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/10.
//

import SwiftUI

struct SearchView: View {
    
    @State var searchText: String = ""
    @State var appInfoResponse: AppInfoResponse
    @State var isSearching: Bool = false
    
    var body: some View {
        ZStack {
            SearchResultView(appInfoResponse: $appInfoResponse)
                .searchable(text: $searchText, prompt: "Search...")
                .onSubmit(of: .search) {
                    Task {
                        do { try await search()
                        } catch { print(error.localizedDescription) }
                    }
                }
            if (isSearching) {
                ProgressView()
            }
        }
    }
    
    private func search() async throws {
        isSearching.toggle()
        guard let queryText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/appInfo?q=\(queryText)&per=1000&page=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        self.appInfoResponse = .empty
        self.appInfoResponse = try JSONDecoder().decode(AppInfoResponse.self, from: data)
        isSearching.toggle()
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(appInfoResponse: .empty, isSearching: true)
    }
}
