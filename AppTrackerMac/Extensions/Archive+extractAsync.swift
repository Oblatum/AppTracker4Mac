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
