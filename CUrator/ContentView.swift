//
//  ContentView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]
    @Query private var contentItems: [ContentItem]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isImportingSharedURLs = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("홈", systemImage: "house.fill")
                        }

                    LibraryView()
                        .tabItem {
                            Label("보관함", systemImage: "folder.fill")
                        }

                    SettingsView()
                        .tabItem {
                            Label("설정", systemImage: "gearshape")
                        }
                }
            } else {
                OnboardingView { selectedCategories in
                    let initialCategories = createInitialCategories(selectedCategories)
                    SharedImportStore.syncCategories(initialCategories)
                    hasCompletedOnboarding = true
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.light)
        .task {
            if hasCompletedOnboarding {
                seedCategoriesIfNeeded()
                syncSharedCategories()
            }
            await importPendingSharedURLs()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                if hasCompletedOnboarding {
                    seedCategoriesIfNeeded()
                    syncSharedCategories()
                }
                await importPendingSharedURLs()
            }
        }
        .onChange(of: categories.map(\.name)) { _, _ in
            syncSharedCategories()
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            guard completed else { return }
            seedCategoriesIfNeeded()
            syncSharedCategories()
        }
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        CategoryItem.defaults.forEach { modelContext.insert(CategoryItem(name: $0)) }
        try? modelContext.save()
    }

    @discardableResult
    private func createInitialCategories(_ names: [String]) -> [String] {
        let trimmedNames = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var uniqueNames: [String] = []
        for name in trimmedNames where !uniqueNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            uniqueNames.append(name)
        }

        let initialNames = uniqueNames.isEmpty ? CategoryItem.defaults : uniqueNames

        for name in initialNames where !categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            modelContext.insert(CategoryItem(name: name))
        }

        try? modelContext.save()
        return initialNames
    }

    private func syncSharedCategories() {
        let names = categories.map(\.name).isEmpty ? CategoryItem.defaults : categories.map(\.name)
        SharedImportStore.syncCategories(names)
    }

    @MainActor
    private func importPendingSharedURLs() async {
        guard !isImportingSharedURLs else { return }

        let imports = SharedImportStore.takePendingImports()
        guard !imports.isEmpty else { return }

        isImportingSharedURLs = true
        defer { isImportingSharedURLs = false }

        let categoryNames = categories.map(\.name).isEmpty ? CategoryItem.defaults : categories.map(\.name)
        var knownURLs = Set(contentItems.map(\.url))
        var knownCategoryNames = Set(categories.map(\.name))

        for sharedImport in imports where !knownURLs.contains(sharedImport.url) {
            let manualCategory = validManualCategory(sharedImport.manualCategory, in: categoryNames)
            let response = (try? await APIClient().analyze(url: sharedImport.url, manualCategory: manualCategory, categories: categoryNames))
                ?? APIClient().fallbackAnalyze(url: sharedImport.url, manualCategory: manualCategory, categories: categoryNames)
            let finalCategory = manualCategory ?? response.category
            let finalTags = normalizedTags(response.tags, platform: response.platform, category: finalCategory)

            if !knownCategoryNames.contains(finalCategory) {
                modelContext.insert(CategoryItem(name: finalCategory))
                knownCategoryNames.insert(finalCategory)
            }

            let item = ContentItem(
                title: response.title,
                url: response.url,
                platform: response.platform,
                category: finalCategory,
                memo: "",
                summary: response.summary,
                tags: finalTags,
                thumbnailURL: response.thumbnailURL,
                sourceNote: response.sourceNote
            )

            modelContext.insert(item)
            knownURLs.insert(response.url)
        }

        try? modelContext.save()
    }

    private func validManualCategory(_ category: String?, in categoryNames: [String]) -> String? {
        guard let category else { return nil }
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCategory.isEmpty else { return nil }

        if let existingCategory = categoryNames.first(where: { $0.caseInsensitiveCompare(trimmedCategory) == .orderedSame }) {
            return existingCategory
        }

        return trimmedCategory
    }

    private func normalizedTags(_ tags: [String], platform: ContentPlatform, category: String) -> [String] {
        var normalized = [platform.rawValue, category]
        for tag in tags where tag != "분류 필요" && !normalized.contains(tag) {
            normalized.append(tag)
        }
        return Array(normalized.prefix(5))
    }
}
