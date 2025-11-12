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

enum AnimeCategory: String, CaseIterable, Identifiable {
    case seasonal = "Current Season"
    case top = "Top Rated"
    case upcoming = "Upcoming"
    case popular = "Popular"
    
    var id: Self { self }
    
    var systemImage: String {
        switch self {
        case .seasonal:
            return "calendar"
        case .top:
            return "star.fill"
        case .upcoming:
            return "clock"
        case .popular:
            return "heart.fill"
        }
    }
}

struct ExploreView: View {
    @StateObject private var dataService = AnimeDataService()
    @State private var searchText: String = ""
    @State private var selectedGenres: Set<String>
    @State private var showFilters: Bool = false
    @State private var selectedCategory: AnimeCategory = .seasonal
    @State private var isSearching: Bool = false
    @Environment(UserDataManager.self) var userDataManager

    private let availableGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance",
        "Sci-Fi", "Slice of Life", "Supernatural", "Military", "Horror", "Mystery",
        "Psychological", "Thriller", "Sports", "School"
    ]
    
    // Initialize with optional pre-selected genres
    init(initialGenres: Set<String> = []) {
        self._selectedGenres = State(initialValue: initialGenres)
    }

    private var filteredItems: [AnimeItem] {
        dataService.getFilteredItems(
            searchText: searchText,
            selectedGenres: selectedGenres
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category selector
                if !isSearching {
                    CategorySelector(selectedCategory: $selectedCategory)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Error message if exists
                        if let errorMessage = dataService.errorMessage {
                            ErrorView(message: errorMessage) {
                                await loadDataForCategory()
                            }
                            .padding()
                        }
                        
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
                }
                .refreshable {
                    await loadDataForCategory()
                }
            }
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Search anime...")
            .onSubmit(of: .search) {
                Task {
                    isSearching = !searchText.isEmpty
                    if isSearching {
                        await dataService.searchAnime(query: searchText)
                    } else {
                        await loadDataForCategory()
                    }
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty && isSearching {
                    isSearching = false
                    Task {
                        await loadDataForCategory()
                    }
                }
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                if !isSearching {
                    Task {
                        await loadDataForCategory()
                    }
                }
            }
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
                    availableGenres: availableGenres,
                    onApplyFilters: {
                        Task {
                            if !selectedGenres.isEmpty {
                                await dataService.loadAnimeByGenres(Array(selectedGenres))
                            } else {
                                await loadDataForCategory()
                            }
                        }
                    }
                )
            }
        }
        .task {
            if dataService.animeItems.isEmpty {
                if !selectedGenres.isEmpty {
                    await dataService.loadAnimeByGenres(Array(selectedGenres))
                } else {
                    await loadDataForCategory()
                }
            }
        }
    }
    
    private func loadDataForCategory() async {
        switch selectedCategory {
        case .seasonal:
            await dataService.loadSeasonalAnime()
        case .top:
            await dataService.loadTopAnime()
        case .upcoming:
            await dataService.loadUpcomingAnime()
        case .popular:
            await dataService.loadInitialItems()
        }
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: AnimeCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnimeCategory.allCases) { category in
                    ExploreCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ExploreCategoryButton: View {
    let category: AnimeCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () async -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
