//
//  SharedImportStore.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import Foundation

enum SharedImportStore {
    static let appGroupID = "group.com.yoseong12.CUrator"
    private static let pendingURLsKey = "pendingSharedURLs"

    static func takePendingURLs() -> [String] {
        let defaults = sharedDefaults
        let urls = defaults.stringArray(forKey: pendingURLsKey) ?? []
        defaults.removeObject(forKey: pendingURLsKey)
        return urls
    }

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
