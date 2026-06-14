//
//  HomeView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Query(sort: \ContentItem.savedAt, order: .reverse) private var items: [ContentItem]
    @State private var editingItem: ContentItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let first = items.first {
                        ContentCard(item: first, showOpenButton: true) {
                            open(first)
                        }
                    } else {
                        emptyTodayCard
                    }

                    Text("최근 저장한 콘텐츠")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.top, 4)

                    LazyVStack(spacing: 12) {
                        ForEach(Array(items.dropFirst().prefix(4))) { item in
                            ContentCard(item: item)
                                .onTapGesture {
                                    editingItem = item
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editingItem) { item in
                EditContentView(item: item)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘 다시 볼 콘텐츠")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("저장한 콘텐츠 중 다시 보면 좋을 항목을 골라봤어요")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyTodayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsuleChip(title: "저장 대기", isSelected: false)
            Text("아직 저장한 콘텐츠가 없어요")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
            Text("보관함의 + 버튼으로 URL을 저장해보세요.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
    }

    private func open(_ item: ContentItem) {
        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }
}
