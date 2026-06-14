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
                    createInitialCategories(selectedCategories)
                    hasCompletedOnboarding = true
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.light)
        .task {
            if hasCompletedOnboarding {
                seedCategoriesIfNeeded()
            }
            await importPendingSharedURLs()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task {
                if hasCompletedOnboarding {
                    seedCategoriesIfNeeded()
                }
                await importPendingSharedURLs()
            }
        }
    }

    private func seedCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        CategoryItem.defaults.forEach { modelContext.insert(CategoryItem(name: $0)) }
        try? modelContext.save()
    }

    private func createInitialCategories(_ names: [String]) {
        let trimmedNames = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let uniqueNames = Array(NSOrderedSet(array: trimmedNames)) as? [String] ?? trimmedNames
        let initialNames = uniqueNames.isEmpty ? CategoryItem.defaults : uniqueNames

        for name in initialNames where !categories.contains(where: { $0.name == name }) {
            modelContext.insert(CategoryItem(name: name))
        }

        try? modelContext.save()
    }

    @MainActor
    private func importPendingSharedURLs() async {
        guard !isImportingSharedURLs else { return }

        let urls = SharedImportStore.takePendingURLs()
        guard !urls.isEmpty else { return }

        isImportingSharedURLs = true
        defer { isImportingSharedURLs = false }

        let categoryNames = categories.map(\.name).isEmpty ? CategoryItem.defaults : categories.map(\.name)
        var knownURLs = Set(contentItems.map(\.url))
        var knownCategoryNames = Set(categories.map(\.name))

        for url in urls where !knownURLs.contains(url) {
            let response: AnalyzeResponse

            do {
                response = try await APIClient().analyze(url: url, manualCategory: categoryNames.first, categories: categoryNames)
            } catch {
                response = APIClient().fallbackAnalyze(url: url, manualCategory: categoryNames.first, categories: categoryNames)
            }

            if !knownCategoryNames.contains(response.category) {
                modelContext.insert(CategoryItem(name: response.category))
                knownCategoryNames.insert(response.category)
            }

            let item = ContentItem(
                title: response.title,
                url: response.url,
                platform: response.platform,
                category: response.category,
                memo: "",
                summary: response.summary,
                tags: response.tags,
                thumbnailURL: response.thumbnailURL,
                sourceNote: response.sourceNote
            )

            modelContext.insert(item)
            knownURLs.insert(response.url)
        }

        try? modelContext.save()
    }
}
