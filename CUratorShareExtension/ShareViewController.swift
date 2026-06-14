//
//  ShareViewController.swift
//  CUratorShareExtension
//
//  Created by Codex on 6/14/26.
//

import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroupID = "group.com.yoseong12.CUrator"
    private let pendingURLsKey = "pendingSharedURLs"

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "링크를 가져오는 중..."
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "CU RATOR에 저장할 준비를 하고 있어요."
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await importSharedURL() }
    }

    private func configureView() {
        view.backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: [statusLabel, detailLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @MainActor
    private func finish(title: String, detail: String) {
        statusLabel.text = title
        detailLabel.text = detail

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func importSharedURL() async {
        guard let url = await findSharedURL() else {
            await finish(title: "링크를 찾지 못했어요", detail: "URL이 포함된 콘텐츠를 다시 공유해보세요.")
            return
        }

        savePendingURL(url.absoluteString)
        await finish(title: "저장 준비 완료", detail: "CU RATOR를 열면 보관함에 자동 저장돼요.")
    }

    private func findSharedURL() async -> URL? {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

        for item in extensionItems {
            guard let providers = item.attachments else { continue }

            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let url = await loadURL(from: provider) {
                    return url
                }

                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let url = await loadURLFromText(from: provider) {
                    return url
                }
            }
        }

        return nil
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let text = item as? String {
                    continuation.resume(returning: Self.firstURL(in: text))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadURLFromText(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                continuation.resume(returning: Self.firstURL(in: item as? String ?? ""))
            }
        }
    }

    private func savePendingURL(_ url: String) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        var urls = defaults.stringArray(forKey: pendingURLsKey) ?? []

        if !urls.contains(url) {
            urls.append(url)
        }

        defaults.set(urls, forKey: pendingURLsKey)
    }

    private static func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?.firstMatch(in: text, options: [], range: range)?.url
    }
}
