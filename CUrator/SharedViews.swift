//
//  SharedViews.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct ContentCard: View {
    let item: ContentItem
    var isFeatured = false
    var showOpenButton = false
    var onOpen: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isFeatured {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(height: 150)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Image(systemName: iconName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(platformColor)

                Text(item.platform.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(platformColor)

                Text("·")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)

                Text(item.savedDateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.tertiaryText)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Text(item.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(2)

            Text(item.summary.isEmpty ? item.memo : item.summary)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)

            HStack(spacing: 7) {
                ForEach(item.tags.prefix(3), id: \.self) { tag in
                    CapsuleChip(title: tag, isSelected: false)
                }
            }

            if showOpenButton {
                Button {
                    onOpen?()
                } label: {
                    Label("열어보기", systemImage: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private var iconName: String {
        switch item.platform {
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

    private var platformColor: Color {
        item.platform == .youtube ? AppTheme.youtube : AppTheme.accent
    }
}

struct CapsuleChip: View {
    let title: String
    var isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : AppTheme.accent)
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(isSelected ? AppTheme.accent : AppTheme.accentSoft)
            .clipShape(Capsule())
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 26, height: 26)
                .background(AppTheme.accentSoft)
                .clipShape(Circle())

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

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }
}

struct PrimaryActionButton: View {
    let title: String
    var icon: String?
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 15, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(isDisabled ? AppTheme.accent.opacity(0.45) : AppTheme.accent)
        .foregroundStyle(Color.white)
        .disabled(isDisabled)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct CategoryPillGrid: View {
    let categories: [String]
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 10)], spacing: 10) {
            ForEach(categories, id: \.self) { category in
                Button {
                    selection = category
                } label: {
                    Text(category)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selection == category ? Color.white : AppTheme.secondaryText)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(selection == category ? AppTheme.accent : AppTheme.elevatedSurface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
