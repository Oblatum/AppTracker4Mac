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
    
    private func nomalizedSnakeCaseName(_ userDefinedAppName: String? = nil) -> String {
        
        var nomalizedName = userDefinedAppName ?? appName
        
        if nomalizedName.first?.isNumber == true {
            nomalizedName = "a_" + nomalizedName
        }
        
        nomalizedName = nomalizedName.latin ?? nomalizedName
        
        nomalizedName = nomalizedName.filter { $0.isASCII && ($0.isNumber || $0.isLetter || $0.isWhitespace || $0 == "_" )}
        
        return nomalizedName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: String.whitespace, with: String.underscore)
            .lowercased()
    }
    
    func appfilter(_ userDefinedAppName: String? = nil) -> String {
        """
        <!-- \((userDefinedAppName ?? appName).trimmingCharacters(in: .whitespacesAndNewlines)) -->
        <item component="ComponentInfo{\(packageName)/\(activityName)}" drawable="\(nomalizedSnakeCaseName(userDefinedAppName))" />
        
        """
    }
    
    func drawable(_ userDefinedAppName: String? = nil) -> String {
        """
        <item drawable="\(nomalizedSnakeCaseName(userDefinedAppName))" />
        
        """
    }
    
    static let example: AppInfoElement = .init(count: 1, signature: "", packageName: "com.example.app", appName: "Example App", activityName: "mainActivity", id: UUID().uuidString)
}

extension AppInfoElement {
    static func propertyName(for keyPath: KeyPath<AppInfoElement, String>) -> String? {
        switch keyPath {
        case \.packageName:
            return "package name"
        case \.activityName:
            return "activity name"
        case \.appName:
            return "app name"
        default:
            return nil
        }
    }
    
    var playStoreUrl: URL {
        URL(string: "https://play.google.com/store/apps/details?id=\(packageName)")!
    }
}
