//
//  APIClient.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import Foundation

struct AnalyzeRequest: Codable {
    let url: String
    let manualCategory: String?
    let categories: [String]
}

struct AnalyzeResponse: Codable {
    let url: String
    let platform: ContentPlatform
    let title: String
    let category: String
    let tags: [String]
    let summary: String
    let thumbnailURL: String?
    let sourceNote: String
    let requiresManualCategory: Bool
}

enum APIClientError: Error {
    case invalidURL
    case invalidResponse
}

struct APIClient {
    var baseURLString = "http://127.0.0.1:8000"

    func analyze(url: String, manualCategory: String?, categories: [String]) async throws -> AnalyzeResponse {
        guard let endpoint = URL(string: "\(baseURLString)/analyze") else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnalyzeRequest(url: url, manualCategory: manualCategory, categories: categories))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw APIClientError.invalidResponse
        }

        return try JSONDecoder().decode(AnalyzeResponse.self, from: data)
    }

    func fallbackAnalyze(url rawURL: String, manualCategory: String?, categories: [String]) -> AnalyzeResponse {
        let normalizedURL = normalizeURL(rawURL)
        let platform = detectPlatform(from: normalizedURL)
        let title = fallbackTitle(for: normalizedURL, platform: platform)
        let category = inferCategory(
            from: title + " " + normalizedURL,
            manualCategory: manualCategory,
            categories: categories
        )

        return AnalyzeResponse(
            url: normalizedURL,
            platform: platform,
            title: title,
            category: category,
            tags: makeTags(platform: platform, category: category),
            summary: platform == .instagram ? "외부 정보 접근 제한으로 카테고리 확인이 필요해요." : "백엔드 연결 전이라 AI 분류를 완료하지 못했어요.",
            thumbnailURL: nil,
            sourceNote: "Local fallback",
            requiresManualCategory: platform == .instagram
        )
    }

    private func detectPlatform(from url: String) -> ContentPlatform {
        let lowercasedURL = url.lowercased()

        if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
            return .youtube
        }

        if lowercasedURL.contains("instagram.com") {
            return .instagram
        }

        if lowercasedURL.contains("blog") || lowercasedURL.contains("naver.com") || lowercasedURL.contains("tistory.com") || lowercasedURL.contains("medium.com") {
            return .blog
        }

        return .web
    }

    private func normalizeURL(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "https://example.com" }
        guard trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") else {
            return "https://\(trimmed)"
        }
        return trimmed
    }

    private func fallbackTitle(for url: String, platform: ContentPlatform) -> String {
        guard let host = URL(string: url)?.host?.replacingOccurrences(of: "www.", with: "") else {
            return "\(platform.rawValue) 콘텐츠"
        }

        switch platform {
        case .youtube:
            return "YouTube 영상"
        case .instagram:
            return "Instagram 콘텐츠"
        case .blog, .web:
            return host
        }
    }

    private func inferCategory(from text: String, manualCategory: String?, categories: [String]) -> String {
        let lowercased = text.lowercased()

        if let directMatch = categories.first(where: { categoryMatches($0, in: lowercased) }) {
            return directMatch
        }

        return "분류 필요"
    }

    private func categoryMatches(_ category: String, in text: String) -> Bool {
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedCategory.isEmpty else { return false }

        if text.contains(normalizedCategory) {
            return true
        }

        return normalizedCategory
            .split(whereSeparator: { $0.isWhitespace || $0 == "/" || $0 == "," })
            .map(String.init)
            .filter { $0.count >= 2 }
            .contains(where: { text.contains($0) })
    }

    private func makeTags(platform: ContentPlatform, category: String) -> [String] {
        [platform.rawValue, category]
    }
}
