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
    private let pendingImportsKey = "pendingSharedImports"
    private let sharedCategoryNamesKey = "sharedCategoryNames"
    private let chooseCategoryIdentifier = "__choose_category__"
    private let fallbackCategories = ["가볼 곳", "사고 싶은 것", "스타일 참고", "따라 해볼 것", "공부/정보", "레퍼런스", "다시 볼 것"]

    private var sharedURL: String?
    private var selectedCategory: String?
    private var selectedUsesAI = false
    private var categoryScrollHeightConstraint: NSLayoutConstraint?

    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 36).isActive = true
        view.heightAnchor.constraint(equalToConstant: 4).isActive = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "링크를 가져오는 중..."
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "CU RATOR에 저장할 준비를 하고 있어요."
        return label
    }()

    private let categoryScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = false
        scrollView.isHidden = true
        return scrollView
    }()

    private let categoryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 9
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("카테고리 선택 후 저장", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 0.42, green: 0.32, blue: 0.92, alpha: 0.35)
        button.layer.cornerRadius = 18
        button.isEnabled = false
        button.isHidden = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.tintColor = .secondaryLabel
        button.isHidden = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await importSharedURL() }
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 0, height: 620)

        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        categoryScrollView.addSubview(categoryStackView)
        categoryScrollHeightConstraint = categoryScrollView.heightAnchor.constraint(equalToConstant: 0)
        categoryScrollHeightConstraint?.isActive = true
        NSLayoutConstraint.activate([
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor),
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.topAnchor),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.bottomAnchor),
            categoryStackView.widthAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.widthAnchor),
            categoryScrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 330)
        ])

        let stackView = UIStackView(arrangedSubviews: [handleView, statusLabel, detailLabel, categoryScrollView, saveButton, cancelButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.setCustomSpacing(22, after: detailLabel)
        stackView.setCustomSpacing(18, after: categoryScrollView)
        stackView.setCustomSpacing(8, after: saveButton)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @MainActor
    private func finish(title: String, detail: String, delay: TimeInterval = 0.8) {
        statusLabel.text = title
        detailLabel.text = detail
        categoryScrollView.isHidden = true
        saveButton.isHidden = true
        cancelButton.isHidden = true

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func importSharedURL() async {
        guard let url = await findSharedURL() else {
            finish(title: "링크를 찾지 못했어요", detail: "URL이 포함된 콘텐츠를 다시 공유해보세요.")
            return
        }

        showCategoryPicker(for: url.absoluteString)
    }

    @MainActor
    private func showCategoryPicker(for url: String) {
        sharedURL = url
        selectedCategory = nil
        selectedUsesAI = false
        statusLabel.text = "어디에 저장할까요?"
        detailLabel.text = "AI 추천으로 맡기거나 직접 카테고리를 고를 수 있어요."
        renderChoiceButtons(showCategories: false)

        categoryScrollView.isHidden = false
        saveButton.isHidden = false
        cancelButton.isHidden = false
    }

    @MainActor
    private func renderChoiceButtons(showCategories: Bool) {
        categoryStackView.arrangedSubviews.forEach { view in
            categoryStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        addCategoryRow(buttons: [
            makeCategoryButton(title: "AI 추천", category: nil, isSelected: selectedUsesAI),
            makeCategoryButton(title: "카테고리 선택", category: chooseCategoryIdentifier, isSelected: showCategories && !selectedUsesAI && selectedCategory == nil)
        ])

        if showCategories {
            var rowButtons: [UIButton] = []
            for category in sharedCategories.prefix(10) {
                rowButtons.append(makeCategoryButton(title: category, category: category, isSelected: selectedCategory == category))
                if rowButtons.count == 2 {
                    addCategoryRow(buttons: rowButtons)
                    rowButtons = []
                }
            }

            if !rowButtons.isEmpty {
                addCategoryRow(buttons: rowButtons)
            }
        }

        updateCategoryScrollHeight()
        updateSaveButtonState()
    }

    @MainActor
    private func makeCategoryButton(title: String, category: String?, isSelected: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.contentHorizontalAlignment = .center
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        button.configuration = configuration
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.accessibilityIdentifier = category ?? "__ai__"
        button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        styleCategoryButton(button, isSelected: isSelected)
        return button
    }

    @MainActor
    private func addCategoryRow(buttons: [UIButton]) {
        let row = UIStackView(arrangedSubviews: buttons)
        row.axis = .horizontal
        row.spacing = 9
        row.distribution = .fillEqually
        categoryStackView.addArrangedSubview(row)
    }

    @MainActor
    private func updateCategoryScrollHeight() {
        let rowCount = CGFloat(categoryStackView.arrangedSubviews.count)
        guard rowCount > 0 else {
            categoryScrollHeightConstraint?.constant = 0
            return
        }

        let rowHeight: CGFloat = 42
        let spacing = categoryStackView.spacing * max(0, rowCount - 1)
        categoryScrollHeightConstraint?.constant = min((rowCount * rowHeight) + spacing, 330)
    }

    @MainActor
    private func styleCategoryButton(_ button: UIButton, isSelected: Bool) {
        var configuration = button.configuration ?? .plain()
        configuration.baseForegroundColor = isSelected ? .white : UIColor(red: 0.42, green: 0.32, blue: 0.92, alpha: 1)
        configuration.background.backgroundColor = isSelected ? UIColor(red: 0.42, green: 0.32, blue: 0.92, alpha: 1) : UIColor(red: 0.93, green: 0.90, blue: 1, alpha: 1)
        button.configuration = configuration
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        if sender.accessibilityIdentifier == "__ai__" {
            selectedUsesAI = true
            selectedCategory = nil
            renderChoiceButtons(showCategories: false)
            return
        }

        if sender.accessibilityIdentifier == chooseCategoryIdentifier {
            selectedUsesAI = false
            selectedCategory = nil
            renderChoiceButtons(showCategories: true)
            return
        }

        selectedUsesAI = false
        selectedCategory = sender.accessibilityIdentifier

        for case let row as UIStackView in categoryStackView.arrangedSubviews {
            for case let button as UIButton in row.arrangedSubviews {
                let selectedIdentifier = selectedUsesAI ? "__ai__" : selectedCategory
                let isSelected = button.accessibilityIdentifier == selectedIdentifier
                styleCategoryButton(button, isSelected: isSelected)
            }
        }

        updateSaveButtonState()
    }

    @objc private func saveTapped() {
        guard let sharedURL else {
            finish(title: "링크를 찾지 못했어요", detail: "URL이 포함된 콘텐츠를 다시 공유해보세요.")
            return
        }
        guard selectedUsesAI || selectedCategory != nil else { return }

        savePendingImport(url: sharedURL, manualCategory: selectedCategory)
        let detail = selectedCategory.map { "\($0) 카테고리로 저장할게요." } ?? "CU RATOR를 열면 AI가 분류해서 저장해요."
        finish(title: "저장 준비 완료", detail: detail)
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "CUratorShareExtension", code: 0))
    }

    @MainActor
    private func updateSaveButtonState() {
        let canSave = selectedUsesAI || selectedCategory != nil
        saveButton.isEnabled = canSave
        saveButton.backgroundColor = UIColor(red: 0.42, green: 0.32, blue: 0.92, alpha: canSave ? 1 : 0.35)

        if selectedUsesAI {
            saveButton.setTitle("AI 추천으로 저장", for: .normal)
        } else if let selectedCategory {
            saveButton.setTitle("\(selectedCategory)로 저장", for: .normal)
        } else {
            saveButton.setTitle("카테고리 선택 후 저장", for: .normal)
        }
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

    private var sharedCategories: [String] {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        let categories = defaults.stringArray(forKey: sharedCategoryNamesKey) ?? []
        let cleaned = categories
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return cleaned.isEmpty ? fallbackCategories : cleaned
    }

    private func savePendingImport(url: String, manualCategory: String?) {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        var imports = decodePendingImports(from: defaults.data(forKey: pendingImportsKey))
        let newImport = PendingShareImport(url: url, manualCategory: manualCategory)

        if let existingIndex = imports.firstIndex(where: { $0.url == url }) {
            imports[existingIndex] = newImport
        } else {
            imports.append(newImport)
        }

        if let data = try? JSONEncoder().encode(imports) {
            defaults.set(data, forKey: pendingImportsKey)
        }
    }

    private func decodePendingImports(from data: Data?) -> [PendingShareImport] {
        guard let data,
              let imports = try? JSONDecoder().decode([PendingShareImport].self, from: data) else {
            return []
        }

        return imports
    }

    private static func firstURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector?.firstMatch(in: text, options: [], range: range)?.url
    }
}

private struct PendingShareImport: Codable {
    let url: String
    let manualCategory: String?
}
