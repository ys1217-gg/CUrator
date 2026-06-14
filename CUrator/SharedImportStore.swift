//
//  SharedImportStore.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import Foundation

struct PendingSharedImport {
    let url: String
    let manualCategory: String?
}

enum SharedImportStore {
    static let appGroupID = "group.com.yoseong12.CUrator"
    private static let pendingURLsKey = "pendingSharedURLs"
    private static let pendingImportsKey = "pendingSharedImports"
    private static let sharedCategoryNamesKey = "sharedCategoryNames"

    static func takePendingURLs() -> [String] {
        takePendingImports().map(\.url)
    }

    static func takePendingImports() -> [PendingSharedImport] {
        let defaults = sharedDefaults
        var imports = decodePendingImports(from: defaults.data(forKey: pendingImportsKey))

        let legacyURLs = defaults.stringArray(forKey: pendingURLsKey) ?? []
        imports.append(contentsOf: legacyURLs.map { PendingSharedImport(url: $0, manualCategory: nil) })

        defaults.removeObject(forKey: pendingImportsKey)
        defaults.removeObject(forKey: pendingURLsKey)
        return imports
    }

    static func syncCategories(_ categories: [String]) {
        let cleaned = categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        sharedDefaults.set(cleaned, forKey: sharedCategoryNamesKey)
    }

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static func decodePendingImports(from data: Data?) -> [PendingSharedImport] {
        guard let data,
              let rawImports = try? JSONDecoder().decode([RawPendingSharedImport].self, from: data) else {
            return []
        }

        return rawImports.map { PendingSharedImport(url: $0.url, manualCategory: $0.manualCategory) }
    }
}

private struct RawPendingSharedImport: Codable {
    let url: String
    let manualCategory: String?
}
