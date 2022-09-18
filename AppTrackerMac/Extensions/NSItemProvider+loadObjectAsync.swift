//
//  NSItemProvider+async.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/18.
//

import Foundation

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
