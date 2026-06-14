//
//  SettingsView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]
    @Query private var items: [ContentItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("설정")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)

                    storageCard

                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        MenuRow(icon: "folder", title: "카테고리 관리", subtitle: "보관함 필터와 저장 분류에 사용돼요")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        MenuRow(icon: "bell", title: "알림 설정")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AIClassificationSettingsView()
                    } label: {
                        MenuRow(icon: "sparkles", title: "AI 자동 분류 설정")
                    }
                    .buttonStyle(.plain)

                    MenuRow(icon: "info.circle", title: "앱 정보", subtitle: "FastAPI · SwiftData · OpenAI")
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("저장 현황")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("저장한 콘텐츠 \(items.count)개")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            Text("가장 많이 저장한 카테고리 · \(topCategory)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    private var topCategory: String {
        guard !items.isEmpty else { return categories.first?.name ?? "없음" }
        let counts = Dictionary(grouping: items, by: \.category).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "없음"
    }
}

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]
    @Query private var items: [ContentItem]
    @State private var isAddingCategory = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("보관함에서 사용할 카테고리를 관리할 수 있어요.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.vertical, 8)

                    ForEach(categories) { category in
                        HStack(spacing: 12) {
                            categoryIcon(category.name)

                            TextField("카테고리", text: Binding(
                                get: { category.name },
                                set: { category.name = $0 }
                            ))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)

                            Button {
                                deleteCategory(category)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(AppTheme.danger)
                            }
                            .disabled(categories.count <= 1)
                        }
                        .padding(14)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }

            PrimaryActionButton(title: "카테고리 추가", icon: "plus") {
                isAddingCategory = true
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("카테고리 관리")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingCategory) {
            AddCategoryView()
        }
        .onDisappear {
            try? modelContext.save()
        }
    }

    private func deleteCategory(_ category: CategoryItem) {
        guard categories.count > 1 else { return }
        let fallback = categories.first(where: { $0 !== category })?.name ?? "기타"
        items
            .filter { $0.category == category.name }
            .forEach { $0.category = fallback }
        modelContext.delete(category)
        try? modelContext.save()
    }
}

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]
    @State private var name = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("카테고리 이름")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                TextField("예: 맛집", text: $name)
                    .font(.system(size: 14, weight: .medium))
                    .padding(14)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer()

                PrimaryActionButton(title: "저장하기", icon: "square.and.arrow.down", isDisabled: trimmedName.isEmpty) {
                    addCategory()
                }
            }
            .padding(20)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("카테고리 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppTheme.primaryText)
                    }
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addCategory() {
        guard !trimmedName.isEmpty, !categories.contains(where: { $0.name == trimmedName }) else { return }
        modelContext.insert(CategoryItem(name: trimmedName))
        try? modelContext.save()
        dismiss()
    }
}

struct NotificationSettingsView: View {
    @State private var revisitNotification = true
    @State private var weeklyReminder = false
    @State private var selectedDay = "7일"

    var body: some View {
        VStack(spacing: 14) {
            settingToggle("다시보기 알림", isOn: $revisitNotification)

            VStack(alignment: .leading, spacing: 12) {
                Text("저장 후 며칠 뒤 알림")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                HStack(spacing: 8) {
                    ForEach(["3일", "7일", "14일", "30일"], id: \.self) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            CapsuleChip(title: day, isSelected: selectedDay == day)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            settingToggle("주간 리마인드", isOn: $weeklyReminder)

            Spacer()
        }
        .padding(20)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("알림 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AIClassificationSettingsView: View {
    @State private var autoCategory = true
    @State private var notifyAfterSave = true
    @State private var instagramManual = true
    @State private var confirmLowConfidence = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YouTube와 웹 링크는 자동 분류하고, Instagram은 직접 선택하도록 설정할 수 있어요.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
                .padding(.bottom, 8)

            settingToggle("자동 카테고리 분류", isOn: $autoCategory)
            settingToggle("저장 완료 후 자동 알림", isOn: $notifyAfterSave)
            settingToggle("Instagram 직접 선택", isOn: $instagramManual, subtitle: "Instagram은 카테고리를 직접 선택")
            settingToggle("신뢰도 낮을 때 확인", isOn: $confirmLowConfidence, subtitle: "분류 신뢰도가 낮으면 직접 선택")

            Spacer()
        }
        .padding(20)
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("AI 자동 분류 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func categoryIcon(_ name: String) -> some View {
    let icon: String
    let color: Color

    switch name {
    case "갈 곳":
        icon = "mappin.circle"
        color = AppTheme.accentSoft
    case "살 것":
        icon = "bag"
        color = AppTheme.greenSoft
    case "스타일 참고", "패션":
        icon = "sparkles"
        color = AppTheme.pinkSoft
    case "따라 해볼 것":
        icon = "play"
        color = AppTheme.yellowSoft
    case "공부", "공부/정보":
        icon = "book"
        color = AppTheme.accentSoft
    default:
        icon = "tag"
        color = AppTheme.elevatedSurface
    }

    return Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(AppTheme.accent)
        .frame(width: 32, height: 32)
        .background(color)
        .clipShape(Circle())
}

private func settingToggle(_ title: String, isOn: Binding<Bool>, subtitle: String? = nil) -> some View {
    HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.primaryText)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }

        Spacer()

        Toggle("", isOn: isOn)
            .labelsHidden()
            .tint(AppTheme.accent)
    }
    .padding(14)
    .background(AppTheme.elevatedSurface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
}
