//
//  AddContentView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI

enum SaveFlowPhase {
    case input
    case classifying
    case review(AnalyzeResponse)
    case success(ContentItem)
    case failure
}

struct AddContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]

    @State private var urlText = ""
    @State private var memo = ""
    @State private var selectedCategory = ""
    @State private var newCategoryName = ""
    @State private var phase: SaveFlowPhase = .input

    private let apiClient = APIClient()

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .input:
                    inputScreen
                case .classifying:
                    classifyingScreen
                case .review(let response):
                    reviewScreen(response)
                case .success(let item):
                    successScreen(item)
                case .failure:
                    failureScreen
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if case .input = phase {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                }
            }
            .onAppear {
                selectedCategory = categories.first?.name ?? selectedCategory
            }
        }
    }

    private var inputScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("링크 저장하기")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("URL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                HStack(spacing: 10) {
                    TextField("https://example.com", text: $urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14, weight: .medium))

                    Image(systemName: "link")
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("AI가 콘텐츠 주제를 먼저 판단하고, 저장 전에 추천 카테고리를 확인할 수 있어요.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                TextField("메모를 입력하세요", text: $memo, axis: .vertical)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(4...6)
                    .padding(14)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.top, 6)
            }
            .padding(.top, 30)

            Spacer()

            PrimaryActionButton(
                title: "링크 분석하기",
                isDisabled: urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task { await save() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var classifyingScreen: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 18) {
                ProgressView()
                    .tint(AppTheme.accent)
                    .scaleEffect(1.7)

                Text("카테고리 분류 중입니다...")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("콘텐츠 정보를 확인하고 있어요")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .background(AppTheme.accentSoft.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Label("AI가 저장할 위치를 정리하고 있어요", systemImage: "sparkles")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func reviewScreen(_ response: AnalyzeResponse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("AI 추천 확인")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .padding(.top, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(response.platform.rawValue, systemImage: platformIcon(for: response.platform))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(response.platform == .youtube ? AppTheme.youtube : AppTheme.accent)

                        Text(response.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(3)

                        Text(response.summary)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("추천 카테고리")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)

                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.accentSoft)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(isUnresolvedCategory(response.category) ? "직접 분류 필요" : response.category)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppTheme.primaryText)

                                Text(recommendationDescription(for: response.category))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("다른 카테고리에 넣기")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)

                        CategoryPillGrid(categories: reviewCategoryOptions(for: response), selection: $selectedCategory)
                            .onChange(of: selectedCategory) { _, value in
                                guard !value.isEmpty else { return }
                                newCategoryName = ""
                            }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("새 카테고리 만들기")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)

                        HStack(spacing: 10) {
                            TextField("예: AI 공부", text: $newCategoryName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 14, weight: .semibold))
                                .onChange(of: newCategoryName) { _, value in
                                    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    selectedCategory = ""
                                }

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if !displayTags(for: response).isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("태그")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.primaryText)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(displayTags(for: response).prefix(5), id: \.self) { tag in
                                    CapsuleChip(title: tag, isSelected: false)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 28)
                .padding(.bottom, 24)
            }

            VStack(spacing: 12) {
                PrimaryActionButton(
                    title: primarySaveTitle(for: response),
                    isDisabled: finalCategory(for: response).isEmpty
                ) {
                    saveConfirmed(response, category: finalCategory(for: response))
                }

                Button {
                    phase = .input
                } label: {
                    Text("다시 입력")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .onAppear {
            newCategoryName = ""
            selectedCategory = isUnresolvedCategory(response.category) ? "" : response.category
        }
    }

    private func successScreen(_ item: ContentItem) -> some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 76, weight: .medium))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 10) {
                Text("저장 완료")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("이 콘텐츠를 \(item.category) 카테고리에 저장했어요.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                PrimaryActionButton(title: "보관함에서 보기") {
                    dismiss()
                }

                Button {
                    dismiss()
                } label: {
                    Text("닫기")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var failureScreen: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "xmark.circle")
                .font(.system(size: 76, weight: .medium))
                .foregroundStyle(AppTheme.danger)

            VStack(spacing: 10) {
                Text("저장하지 못했어요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("링크를 다시 확인하거나 카테고리를 직접 선택해 저장할 수 있어요.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                PrimaryActionButton(title: "다시 시도") {
                    phase = .input
                }

                Button {
                    phase = .input
                } label: {
                    Text("카테고리 직접 선택")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                }

                Button("취소") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var categoryNames: [String] {
        let names = categories.map(\.name)
        return names.isEmpty ? CategoryItem.defaults : names
    }

    private func save() async {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            phase = .failure
            return
        }

        phase = .classifying

        do {
            let response = try await apiClient.analyze(url: trimmedURL, manualCategory: nil, categories: categoryNames)
            selectedCategory = response.category
            phase = .review(response)
        } catch {
            phase = .failure
        }
    }

    private func saveConfirmed(_ response: AnalyzeResponse, category: String) {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalCategory = trimmedCategory.isEmpty ? response.category : trimmedCategory

        if !categories.contains(where: { $0.name == finalCategory }) {
            modelContext.insert(CategoryItem(name: finalCategory))
        }

        let item = ContentItem(
            title: response.title,
            url: response.url,
            platform: response.platform,
            category: finalCategory,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "저장 목적 미입력" : memo,
            summary: response.summary,
            tags: response.tags,
            thumbnailURL: response.thumbnailURL,
            sourceNote: response.sourceNote
        )

        modelContext.insert(item)
        try? modelContext.save()
        urlText = ""
        memo = ""
        newCategoryName = ""
        phase = .success(item)
    }

    private func reviewCategoryOptions(for response: AnalyzeResponse) -> [String] {
        var options = isUnresolvedCategory(response.category) ? [] : [response.category]
        for name in categoryNames where !options.contains(name) {
            options.append(name)
        }
        return options
    }

    private func finalCategory(for response: AnalyzeResponse) -> String {
        let customCategory = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customCategory.isEmpty {
            return customCategory
        }

        let selected = selectedCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selected.isEmpty {
            return selected
        }

        return isUnresolvedCategory(response.category) ? "" : response.category
    }

    private func primarySaveTitle(for response: AnalyzeResponse) -> String {
        let category = finalCategory(for: response)
        return category.isEmpty ? "카테고리 선택 후 저장" : "\(category)로 저장"
    }

    private func recommendationDescription(for category: String) -> String {
        if isUnresolvedCategory(category) {
            return "새 카테고리를 만들거나 기존 카테고리를 선택해주세요"
        }

        return categoryNames.contains(category) ? "기존 카테고리에 저장돼요" : "저장하면 새 카테고리로 추가돼요"
    }

    private func displayTags(for response: AnalyzeResponse) -> [String] {
        response.tags.filter { !isUnresolvedCategory($0) }
    }

    private func isUnresolvedCategory(_ category: String) -> Bool {
        category.trimmingCharacters(in: .whitespacesAndNewlines) == "분류 필요"
    }

    private func platformIcon(for platform: ContentPlatform) -> String {
        switch platform {
        case .youtube:
            return "play.rectangle.fill"
        case .instagram:
            return "camera.fill"
        case .blog:
            return "doc.text.fill"
        case .web:
            return "globe"
        }
    }
}
