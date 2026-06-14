//
//  OnboardingView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct OnboardingView: View {
    let onStart: ([String]) -> Void

    @State private var step: OnboardingStep = .intro
    @State private var selectedCategories = Set(CategoryItem.defaults)
    @State private var customCategories: [String] = []
    @State private var newCategoryName = ""

    private var allCategories: [String] {
        CategoryItem.defaults + customCategories
    }

    var body: some View {
        Group {
            switch step {
            case .intro:
                introView
            case .categories:
                categorySetupView
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var introView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: 142, height: 142)
                    .shadow(color: AppTheme.accent.opacity(0.26), radius: 18, x: 0, y: 12)

                Image(systemName: "bookmark")
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(Color.white)

                floatingIcon("play.rectangle.fill", color: AppTheme.youtube, x: -72, y: -54)
                floatingIcon("camera.fill", color: AppTheme.danger, x: 72, y: -54)
                floatingIcon("globe", color: AppTheme.accent, x: 0, y: 72)
            }

            Spacer().frame(height: 86)

            VStack(spacing: 14) {
                Text("흩어진 콘텐츠를\n한곳에")
                    .font(.system(size: 27, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.primaryText)

                Text("유튜브, 인스타, 블로그에 저장해둔 콘텐츠를\n다시봄에서 카테고리별로 정리하세요.")
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            PrimaryActionButton(title: "시작하기") {
                withAnimation(.snappy) {
                    step = .categories
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }

    private var categorySetupView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    withAnimation(.snappy) {
                        step = .intro
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 52, height: 52)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("어떤 기준으로\n정리할까요?")
                            .font(.system(size: 28, weight: .bold))
                            .lineSpacing(3)
                            .foregroundStyle(AppTheme.primaryText)

                        Text("원하는 카테고리를 여러 개 선택하거나 직접 추가할 수 있어요.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(allCategories, id: \.self) { category in
                            categoryRow(category)
                        }
                    }

                    addCategoryField
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }

            VStack(spacing: 10) {
                Text("\(categoriesForStart.count)개 카테고리 선택됨")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                PrimaryActionButton(
                    title: "다시봄 시작하기",
                    isDisabled: categoriesForStart.isEmpty
                ) {
                    onStart(categoriesForStart)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white, Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var addCategoryField: some View {
        HStack(spacing: 10) {
            TextField("원하는 항목 추가", text: $newCategoryName)
                .font(.system(size: 14, weight: .medium))
                .textInputAutocapitalization(.never)
                .autorrectionDisabledIfAvailable()
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                addCustomCategory()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 52, height: 52)
                    .background(canAddCategory ? AppTheme.accent : AppTheme.accent.opacity(0.4))
                    .clipShape(Circle())
            }
            .disabled(!canAddCategory)
        }
    }

    private func categoryRow(_ category: String) -> some View {
        Button {
            toggle(category)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: iconName(for: category))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(iconColor(for: category))
                    .frame(width: 54, height: 54)
                    .background(iconColor(for: category).opacity(0.18))
                    .clipShape(Circle())

                Text(category)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Image(systemName: selectedCategories.contains(category) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(selectedCategories.contains(category) ? AppTheme.accent : AppTheme.tertiaryText.opacity(0.45))
            }
            .padding(.horizontal, 16)
            .frame(height: 76)
            .background(selectedCategories.contains(category) ? AppTheme.accentSoft : AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var orderedSelectedCategories: [String] {
        allCategories.filter { selectedCategories.contains($0) }
    }

    private var categoriesForStart: [String] {
        var categories = orderedSelectedCategories
        if !trimmedCategoryName.isEmpty,
           !categories.contains(where: { $0.caseInsensitiveCompare(trimmedCategoryName) == .orderedSame }) {
            categories.append(trimmedCategoryName)
        }
        return categories
    }

    private var trimmedCategoryName: String {
        newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddCategory: Bool {
        !trimmedCategoryName.isEmpty && !allCategories.contains(trimmedCategoryName)
    }

    private func addCustomCategory() {
        guard canAddCategory else { return }
        customCategories.append(trimmedCategoryName)
        selectedCategories.insert(trimmedCategoryName)
        newCategoryName = ""
    }

    private func toggle(_ category: String) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    private func floatingIcon(_ icon: String, color: Color, x: CGFloat, y: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: 23, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 58, height: 58)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
            .offset(x: x, y: y)
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "가볼 곳", "갈 곳":
            return "mappin.circle"
        case "사고 싶은 것", "살 것":
            return "bag"
        case "스타일 참고", "패션":
            return "sparkles"
        case "따라 해볼 것":
            return "play"
        case "공부/정보", "공부":
            return "book"
        case "레퍼런스", "아이디어":
            return "photo"
        default:
            return "tag"
        }
    }

    private func iconColor(for category: String) -> Color {
        switch category {
        case "가볼 곳", "갈 곳":
            return Color.blue
        case "사고 싶은 것", "살 것":
            return Color.green
        case "스타일 참고", "패션":
            return Color.pink
        case "따라 해볼 것":
            return Color.orange
        case "공부/정보", "공부":
            return AppTheme.accent
        default:
            return AppTheme.accent
        }
    }
}

private enum OnboardingStep {
    case intro
    case categories
}

private extension View {
    @ViewBuilder
    func autorrectionDisabledIfAvailable() -> some View {
        if #available(iOS 15.0, *) {
            self.autocorrectionDisabled()
        } else {
            self
        }
    }
}
