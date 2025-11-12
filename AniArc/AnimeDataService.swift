//
//  AnimeDataService.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation
import Combine

@MainActor
class AnimeDataService: ObservableObject {
    @Published var animeItems: [AnimeItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true
    
    private let jikanService = JikanAnimeService()
    private var currentLoadingTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    
    private let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance", "Sci-Fi", "Slice of Life", "Supernatural", "Military", "Horror", "Mystery", "Psychological", "Thriller", "Sports", "School"]
    
    // MARK: - Public API Methods
    
    func loadInitialItems() async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performInitialLoad()
        }
        await currentLoadingTask?.value
    }
    
    func loadMoreItems() async {
        guard !isLoading && hasMorePages else { return }
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performLoadMore()
        }
        await currentLoadingTask?.value
    }
    
    func searchAnime(query: String) async {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(query: query)
        }
        await searchTask?.value
    }
    
    func loadTopAnime() async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performTopAnimeLoad()
        }
        await currentLoadingTask?.value
    }
    
    func loadSeasonalAnime() async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performSeasonalLoad()
        }
        await currentLoadingTask?.value
    }
    
    func loadUpcomingAnime() async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performUpcomingLoad()
        }
        await currentLoadingTask?.value
    }
    
    func loadAnimeByGenres(_ genreNames: [String]) async {
        currentLoadingTask?.cancel()
        currentLoadingTask = Task {
            await performGenreLoad(genreNames: genreNames)
        }
        await currentLoadingTask?.value
    }
    
    // MARK: - Filtering Methods
    
    func getFilteredItems(searchText: String, selectedGenres: Set<String>) -> [AnimeItem] {
        var items = animeItems
        
        // Filter by search text (local filtering for already loaded items)
        if !searchText.isEmpty {
            items = items.filter { anime in
                anime.title.localizedCaseInsensitiveContains(searchText) ||
                anime.synopsis.localizedCaseInsensitiveContains(searchText) ||
                anime.genres.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by genres
        if !selectedGenres.isEmpty {
            items = items.filter { anime in
                !Set(anime.genres).isDisjoint(with: selectedGenres)
            }
        }
        
        return items
    }
    
    // MARK: - Private Implementation Methods
    
    private func performInitialLoad() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let (newAnime, hasMore) = try await jikanService.fetchCurrentSeasonAnime(page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = newAnime
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load anime: \(error.localizedDescription)"
                print("Error loading initial items: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performLoadMore() async {
        isLoading = true
        
        do {
            let (newAnime, hasMore) = try await jikanService.fetchCurrentSeasonAnime(page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems.append(contentsOf: newAnime)
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load more anime: \(error.localizedDescription)"
                print("Error loading more items: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performSearch(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await loadInitialItems()
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let (searchResults, hasMore) = try await jikanService.searchAnime(query: query, page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = searchResults
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Search failed: \(error.localizedDescription)"
                print("Error searching anime: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performTopAnimeLoad() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let (topAnime, hasMore) = try await jikanService.fetchTopAnime(page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = topAnime
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load top anime: \(error.localizedDescription)"
                print("Error loading top anime: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performSeasonalLoad() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let (seasonalAnime, hasMore) = try await jikanService.fetchCurrentSeasonAnime(page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = seasonalAnime
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load seasonal anime: \(error.localizedDescription)"
                print("Error loading seasonal anime: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performUpcomingLoad() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        do {
            let (upcomingAnime, hasMore) = try await jikanService.fetchUpcomingAnime(page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = upcomingAnime
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load upcoming anime: \(error.localizedDescription)"
                print("Error loading upcoming anime: \(error)")
            }
        }
        
        isLoading = false
    }
    
    private func performGenreLoad(genreNames: [String]) async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        
        // Convert genre names to IDs
        let genreIDs = genreNames.compactMap { JikanAnimeService.genreMap[$0] }
        
        guard !genreIDs.isEmpty else {
            isLoading = false
            return
        }
        
        do {
            let (genreAnime, hasMore) = try await jikanService.fetchAnimeByGenres(genreIDs: genreIDs, page: currentPage)
            
            if Task.isCancelled { return }
            
            animeItems = genreAnime
            hasMorePages = hasMore
            currentPage = hasMore ? currentPage + 1 : currentPage
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load anime by genre: \(error.localizedDescription)"
                print("Error loading anime by genre: \(error)")
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Cleanup
    
    deinit {
        currentLoadingTask?.cancel()
        searchTask?.cancel()
    }
}
