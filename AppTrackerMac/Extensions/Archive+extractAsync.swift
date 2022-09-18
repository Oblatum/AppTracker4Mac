//
//  Archive+extractAsync.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/18.
//

import Foundation
import ZIPFoundation

extension Archive {
    func extract(_ entry: Entry, bufferSize: Int = defaultReadChunkSize, skipCRC32: Bool = false,
                 progress: Progress? = nil) async throws -> Data {
        debugPrint(entry.path)
        return try await withCheckedThrowingContinuation { continuation in
            let _ = try! extract(entry, bufferSize: bufferSize, skipCRC32: skipCRC32, progress: progress) { data in
                continuation.resume(returning: data)
            }
        }
    }
    
    func getEntry(by path: String) -> Entry? {
        self.first { entry in
            entry.path == path || entry.path.lowercased() == path.lowercased() || "a_" + entry.path.lowercased() == path.lowercased()
        }
    }
}
