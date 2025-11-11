//
//  ExploreView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

enum Medium: String, CaseIterable, Identifiable {
    case anime, manga, lightnovel
    var id: Self { self }
}

struct ExploreView: View {
    @StateObject private var dataService = AnimeDataService()
    @State private var searchText: String = ""
    @State private var selectedGenres: Set<String> = []
    @State private var showFilters: Bool = false

    private let availableGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance",
        "Sci-Fi", "Slice of Life",
    ]

    private var filteredItems: [AnimeItem] {
        dataService.getFilteredItems(
            searchText: searchText,
            selectedGenres: selectedGenres
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                AnimeGrid(
                    animeItems: filteredItems,
                    isLoading: dataService.isLoading,
                    onLoadMore: {
                        Task {
                            await dataService.loadMoreItems()
                        }
                    }
                )
            }
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Search Shows")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(
                                selectedGenres.isEmpty ? .none : .fill
                            )
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedGenres: $selectedGenres,
                    availableGenres: availableGenres
                )
            }
        }
        .task {
            if dataService.animeItems.isEmpty {
                await dataService.loadInitialItems()
            }
        }
    }
}

#Preview {
    ExploreView()
}
