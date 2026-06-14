//
//  EditContentView.swift
//  CUrator
//
//  Created by Codex on 6/14/26.
//

import SwiftData
import SwiftUI

struct EditContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.createdAt) private var categories: [CategoryItem]

    @Bindable var item: ContentItem

    var body: some View {
        NavigationStack {
            Form {
                Section("콘텐츠") {
                    TextField("제목", text: $item.title)
                    TextField("URL", text: $item.url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Picker("카테고리", selection: $item.category) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category.name)
                        }
                    }
                }

                Section("정리") {
                    TextField("메모", text: $item.memo, axis: .vertical)
                    TextField("짧은 설명", text: $item.summary, axis: .vertical)
                    TextField("태그", text: $item.tagsRawValue)
                }
            }
            .navigationTitle("콘텐츠 수정")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
