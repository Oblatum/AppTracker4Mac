//
//  String+latin.swift
//  AppTrackerMac
//
//  Created by Butanediol on 2022/10/17.
//

import Foundation

extension String {
    var latin: String? {
        (self as NSString)
            .applyingTransform(.toLatin, reverse: false)?
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}
