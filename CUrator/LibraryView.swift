//
//  LibraryView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI
import UIKit

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentItem.savedAt, order: .reverse) private var items: [ContentItem]
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]

    @State private var searchText = ""
    @State private var selectedCategory = "전체"
    @State private var selectedPlatform = "전체"
    @State private var isShowingAddContent = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        filters

                        if filteredItems.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                    NavigationLink {
                                        ContentDetailView(item: item)
                                    } label: {
                                        ContentCard(item: item, isFeatured: index == 0)
                                            .contextMenu {
                                                Button("열기", systemImage: "safari") {
                                                    open(item)
                                                }
                                                Divider()
                                                Button("삭제", systemImage: "trash", role: .destructive) {
                                                    modelContext.delete(item)
                                                    try? modelContext.save()
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 92)
                }

                Button {
                    isShowingAddContent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 54, height: 54)
                        .background(AppTheme.accent)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.accent.opacity(0.34), radius: 16, x: 0, y: 8)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingAddContent) {
                AddContentView()
            }
            .onChange(of: categories.map(\.name)) { _, categoryNames in
                guard selectedCategory != "전체", !categoryNames.contains(selectedCategory) else { return }
                selectedCategory = "전체"
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("보관함")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("저장한 콘텐츠 \(items.count)개")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
                TextField("저장한 콘텐츠 검색", text: $searchText)
                    .font(.system(size: 13, weight: .medium))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("전체", selected: $selectedCategory)
                    ForEach(categories) { category in
                        filterChip(category.name, selected: $selectedCategory)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("전체", selected: $selectedPlatform)
                    ForEach(ContentPlatform.allCases) { platform in
                        filterChip(platform.rawValue, selected: $selectedPlatform)
                    }
                }
            }
        }
    }

    private func filterChip(_ title: String, selected: Binding<String>) -> some View {
        Button {
            selected.wrappedValue = title
        } label: {
            CapsuleChip(title: title, isSelected: selected.wrappedValue == title)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.tertiaryText)

            Text("조건에 맞는 콘텐츠가 없어요")
                .font(.headline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 54)
    }

    private var filteredItems: [ContentItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let matchesCategory = selectedCategory == "전체" || item.category == selectedCategory
            let matchesPlatform = selectedPlatform == "전체" || item.platform.rawValue == selectedPlatform
            let searchable = "\(item.title) \(item.memo) \(item.summary) \(item.url) \(item.category) \(item.tagsRawValue)".lowercased()
            let matchesSearch = query.isEmpty || searchable.contains(query)
            return matchesCategory && matchesPlatform && matchesSearch
        }
    }

    private func open(_ item: ContentItem) {
        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }
}
