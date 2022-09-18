//
//  URL+appendingQueryParameters.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/9/18.
//

import Foundation

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
