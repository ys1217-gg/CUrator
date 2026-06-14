//
//  ContentModels.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import Foundation
import SwiftData

enum ContentPlatform: String, Codable, CaseIterable, Identifiable {
    case youtube = "YouTube"
    case instagram = "Instagram"
    case blog = "Blog"
    case web = "Web"

    var id: String { rawValue }
}

@Model
final class ContentItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var url: String
    var platformRawValue: String
    var category: String
    var memo: String
    var summary: String
    var tagsRawValue: String
    var thumbnailURL: String?
    var sourceNote: String
    var savedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        platform: ContentPlatform,
        category: String,
        memo: String,
        summary: String,
        tags: [String],
        thumbnailURL: String? = nil,
        sourceNote: String,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.platformRawValue = platform.rawValue
        self.category = category
        self.memo = memo
        self.summary = summary
        self.tagsRawValue = tags.joined(separator: ",")
        self.thumbnailURL = thumbnailURL
        self.sourceNote = sourceNote
        self.savedAt = savedAt
    }

    var platform: ContentPlatform {
        ContentPlatform(rawValue: platformRawValue) ?? .web
    }

    var tags: [String] {
        tagsRawValue
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var savedDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: savedAt)
    }
}

@Model
final class CategoryItem {
    @Attribute(.unique) var name: String
    var createdAt: Date

    init(name: String, createdAt: Date = Date()) {
        self.name = name
        self.createdAt = createdAt
    }
}

extension CategoryItem {
    static let defaults = ["가볼 곳", "사고 싶은 것", "스타일 참고", "따라 해볼 것", "공부/정보", "레퍼런스", "다시 볼 것"]
}
