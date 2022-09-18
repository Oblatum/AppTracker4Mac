//
//  UploadView.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/15.
//

import SwiftUI
import ZIPFoundation

extension NSItemProvider {
    func loadObject<T>(ofClass _class: T.Type) async throws -> T where T : _ObjectiveCBridgeable, T._ObjectiveCType : NSItemProviderReading {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: _class) { nsItemProviderReading, error in
                if let nsItemProviderReading = nsItemProviderReading {
                    continuation.resume(returning: nsItemProviderReading)
                }
                if let error = error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension Sequence {
    /// Async map on sequence
    /// - Parameter transform: map every element in a async context
    /// - Returns: new array of the given type
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    
    /// Async compactMap on sequence
    /// - Parameter transform: compactMap every element in a async context
    /// - Returns: new array of the given type
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let value = try await transform(element) {
                values.append(value)
            }
        }

        return values
    }
    
    /// Async forEech on sequence
    /// - Parameter body: the action to be applied on every element
    func asyncForEach(
        _ body: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await body(element)
        }
    }
}

extension Archive {
    func extract(_ entry: Entry, bufferSize: Int = defaultReadChunkSize, skipCRC32: Bool = false,
                 progress: Progress? = nil) async throws -> (Data, CRC32) {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let sema = DispatchSemaphore(value: 0)
                var data: Data!
                let crc32 = try extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32, progress: progress) {
                    data = $0
                    sema.signal()
                }
                sema.wait()
                continuation.resume(returning: (data, crc32))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getEntry(by path: String) -> Entry? {
        self.first { entry in
            entry.path == path || entry.path.lowercased() == path.lowercased()
        }
    }
}

extension URL {
    /// Creates a new URL by adding the given query parameters.
    /// - Parameter parametersDictionary: The query parameter dictionary to add.
    /// - Returns: A new URL.
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

extension Dictionary : URLQueryParameterStringConvertible {
    /// This computed property returns a query parameters string from the given NSDictionary. For
    /// example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
    /// string will be @"day=Tuesday&month=January".
    /// - Returns: The computed parameters string.
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String { get }
}

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
                Archive(url: url, accessMode: .read)
            }
            .compactMap { archive -> (Archive, Entry)? in
                if let appfilterEntry = archive.first(where: { $0.path.hasPrefix("appfilter") && $0.path.hasSuffix(".xml") }) {
                    return (archive, appfilterEntry)
                } else { return nil }
            }
            .asyncMap { archive, entry -> (Archive, [AppInfoElement]) in
                let appfilterData = try await archive.extract(entry)
                let appfilterString = String(data: appfilterData.0, encoding: .utf8) ?? ""
                return (archive, parseAppfilter(appfilterString))
            }
            .asyncForEach { archive, appInfoList in
                try await appInfoList.asyncForEach(uploadAppInfo)
                try await appInfoList.asyncForEach {
                    guard let iconEntry = archive.getEntry(by: $0.appName + ".png") else { return }
                    let (iconData, _) = try await archive.extract(iconEntry)
                    try await uploadAppIcon(iconData, for: $0)
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

struct UploadView: View {
    
    @StateObject private var viewModel: UploadViewModel
    @Namespace var namespace
    
    init() {
        _viewModel = .init(wrappedValue: UploadViewModel())
    }
        
    var body: some View {
        ZStack {
            VStack {
                if viewModel.isUploading {
                    VStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .resizable()
                            .foregroundColor(viewModel.isDragNDropping ? .primary : .secondary)
                            .aspectRatio(contentMode: .fit)
                            .matchedGeometryEffect(id: "uploadicon", in: namespace)
                            .frame(width: 100, height: 100)
                            .padding()
                        ProgressView("Uploading", value: viewModel.currentProgress, total: viewModel.totalProgress)
                            .frame(width: 100)
                    }
                } else if !viewModel.isDragNDropping {
                    LazyVGrid(columns: [GridItem(), GridItem()], alignment: .leading) {
                        Image(systemName: "cursorarrow.and.square.on.square.dashed")
                        Text("Drag")
                        Image(systemName: "tray.and.arrow.down")
                            .matchedGeometryEffect(id: "dropicon", in: namespace)
                        Text("Drop")
                        Image(systemName: "icloud.and.arrow.up")
                            .matchedGeometryEffect(id: "uploadicon", in: namespace)
                        Text("Upload")
                    }
                        .frame(width: 170)
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "tray.and.arrow.down")
                        .resizable()
                        .foregroundColor(viewModel.isDragNDropping ? .primary : .secondary)
                        .aspectRatio(contentMode: .fit)
                        .matchedGeometryEffect(id: "dropicon", in: namespace)
                        .frame(width: 100, height: 100)
                        .padding()
                }
                Text("\(viewModel.errorList.map { $0.localizedDescription }.joined(separator: "\n"))")
            }
            
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(viewModel.isDragNDropping ? Color.primary : Color.secondary, style: StrokeStyle(lineWidth: 5, dash: [20, 8]))
                .foregroundColor(.none)
                .onTapGesture {
                    viewModel.isUploading.toggle()
                }
        }
        .padding()
        .animation(.spring(), value: viewModel.isDragNDropping)
        .animation(.easeInOut, value: viewModel.isUploading)
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragNDropping) { providers in
            Task { await viewModel.onDropAction(providers) }
            return true
        }
    }
}

//struct UploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadView()
//    }
//}
