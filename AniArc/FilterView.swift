//
//  FilterView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedGenres: Set<String>
    let availableGenres: [String]
    let onApplyFilters: (() async -> Void)?
    @Environment(\.dismiss) var dismiss
    
    init(selectedGenres: Binding<Set<String>>, availableGenres: [String], onApplyFilters: (() async -> Void)? = nil) {
        self._selectedGenres = selectedGenres
        self.availableGenres = availableGenres
        self.onApplyFilters = onApplyFilters
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Genres") {
                    ForEach(availableGenres, id: \.self) { genre in
                        Button(action: {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }) {
                            HStack {
                                Text(genre)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGenres.contains(genre) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                if !selectedGenres.isEmpty {
                    Section("Selected Genres") {
                        HStack {
                            ForEach(Array(selectedGenres).sorted(), id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedGenres.removeAll()
                    }
                    .disabled(selectedGenres.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        Task {
                            await onApplyFilters?()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
