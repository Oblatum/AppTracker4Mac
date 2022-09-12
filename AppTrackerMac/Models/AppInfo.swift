//
//  AppInfo.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/10.
//

import Foundation

struct AppInfoResponse: Codable {
    let metadata: Metadata
    var items: [AppInfoElement]
    
    struct Metadata: Codable {
        let page, per, total: Int
    }
    
    static let empty = AppInfoResponse(metadata: .init(page: 1, per: 10, total: 0), items: [])
}

struct AppInfoElement: Codable, Identifiable, Equatable {
    let count: Int
    let signature, packageName, appName, activityName: String
    let id: String
    
    var xml: String {
        """
        <!-- \(appName) -->
        <item component="ComponentInfo{\(packageName)/\(activityName)}" drawable="\(appName)" />
        
        """
    }
    
    static let example: AppInfoElement = .init(count: 1, signature: "", packageName: "com.example.app", appName: "Example App", activityName: "mainActivity", id: UUID().uuidString)
}
