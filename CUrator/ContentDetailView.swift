//
//  ContentDetailView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftUI
import UIKit

struct ContentDetailView: View {
    @Bindable var item: ContentItem
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(height: 152)
                    .overlay(
                        Image(systemName: item.platform == .youtube ? "play.rectangle" : "link")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(Color.white)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)

                    HStack(spacing: 8) {
                        Text(item.platform.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)

                        CapsuleChip(title: item.category, isSelected: false)
                    }
                }

                infoBlock(title: "설명", text: item.summary.isEmpty ? item.memo : item.summary)
                infoBlock(title: "태그", text: item.tags.map { "#\($0)" }.joined(separator: "   "))
                infoBlock(title: "저장일", text: item.savedDateText)

                Spacer(minLength: 24)

                PrimaryActionButton(title: "원본 앱에서 열기", icon: "arrow.up.right.square") {
                    openOriginal()
                }
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("콘텐츠 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditContentView(item: item)
        }
    }

    private func infoBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(text.isEmpty ? "-" : text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func openOriginal() {
        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }
}
