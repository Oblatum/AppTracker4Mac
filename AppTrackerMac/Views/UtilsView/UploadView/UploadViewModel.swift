//
//  UploadViewModel.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/18.
//

import SwiftUI
import ZIPFoundation

@MainActor
class UploadViewModel: ObservableObject {
    @Published var isDragNDropping = false
    @Published var isUploading = false
    @Published var totalProgress: Float = 0
    @Published var currentProgress: Float = 0
    @Published var errorList: [Error] = []
    
    /// Trigger upload
    func onDropAction(_ providers: [NSItemProvider]) async {
        currentProgress = 0
        totalProgress = Float(providers.count)
        isUploading = true

        do {
            try await providers.asyncMap { provider in
                try await provider.loadObject(ofClass: URL.self)
            }
            .compactMap { url in
                return url.pathExtension == "zip" ? url : nil
            }
            .compactMap { url in
                return Archive(url: url, accessMode: .read)
            }
            .compactMap { archive -> (Archive, Entry)? in
                if let appfilterEntry = archive.first(where: { $0.path.hasPrefix("appfilter") && $0.path.hasSuffix(".xml") }) {
                    return (archive, appfilterEntry)
                } else {
                    debugPrint("Appfilter.xml Not Found!")
                    return nil
                }
            }
            .asyncMap { archive, entry -> (Archive, [AppInfoElement]) in
                let appfilterData = try await archive.extract(entry, bufferSize: 1000000)
                let appfilterString = String(data: appfilterData, encoding: .utf8) ?? ""
                return (archive, parseAppfilter(appfilterString))
            }
            .asyncForEach { archive, appInfoList in
                try await appInfoList.asyncForEach(uploadAppInfo)
                try await appInfoList.asyncForEach { appInfo in
                    guard let iconEntry = archive.getEntry(by: appInfo.appName + ".png") else { return }
                    let iconData = try await archive.extract(iconEntry, bufferSize: 1000000)
                    try await uploadAppIcon(iconData, for: appInfo)
                }
                currentProgress += 1
            }
            
        } catch {
            errorList.append(error)
        }
        
        currentProgress = totalProgress
        isUploading = false
    }
    
    private func uploadAppInfo(_ appInfo: AppInfoElement) async throws {
        guard let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/appInfo") else { return }
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let payload = try JSONEncoder().encode(appInfo)
        _ = try await URLSession.shared.upload(for: request, from: payload)
        try await Task.sleep(nanoseconds: 100000000)
    }
    
    private func uploadAppIcon(_ icon: Data, for app: AppInfoElement) async throws {
        let url = URL(string: "https://apptracker-api.cn2.tiers.top/api/appIcon")!
            .appendingQueryParameters(["packageName": app.packageName])
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("image/png", forHTTPHeaderField: "Content-Type")
        
        _ = try await URLSession.shared.upload(for: request, from: icon)
        try await Task.sleep(nanoseconds: 100000000)
    }
    
    private func parseAppfilter(_ appfilterString: String) -> [AppInfoElement] {
        let pattern = #"<!--\s+(\S+)\s+-->\s+<item\s+component=\"ComponentInfo\{(\S+)\/(\S+)\}\"\s+drawable=\"(\S+)\"\s*\/>"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let stringRange = NSRange(location: 0, length: appfilterString.utf16.count)
        let matches = regex.matches(in: appfilterString, range: stringRange)
        var result: [[String]] = []
        for match in matches {
            var groups: [String] = []
            for rangeIndex in 1 ..< match.numberOfRanges {
                let nsRange = match.range(at: rangeIndex)
                guard !NSEqualRanges(nsRange, NSMakeRange(NSNotFound, 0)) else { continue }
                let string = (appfilterString as NSString).substring(with: nsRange)
                groups.append(string)
            }
            if !groups.isEmpty {
                result.append(groups)
            }
        }
        return result.map { appInfoArray in
            AppInfoElement(count: 1, signature: "", packageName: appInfoArray[1], appName: appInfoArray[0], activityName: appInfoArray[2], id: UUID().uuidString)
        }
    }

}
