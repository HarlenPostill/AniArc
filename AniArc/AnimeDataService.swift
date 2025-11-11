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
    
    private let availableGenres = ["Action", "Adventure", "Comedy", "Drama", "Fantasy", "Romance", "Sci-Fi", "Slice of Life"]
    
    func loadInitialItems() async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        animeItems = generateStubAnime(count: 20)
        isLoading = false
    }
    
    func loadMoreItems() async {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        animeItems.append(contentsOf: generateStubAnime(count: 10))
        isLoading = false
    }
    
    private func generateStubAnime(count: Int) -> [AnimeItem] {
        let titles = ["Demon Slayer", "Attack on Titan", "My Hero Academia", "Jujutsu Kaisen",
                     "One Piece", "Naruto", "Death Note", "Steins;Gate", "Cowboy Bebop",
                     "Fullmetal Alchemist", "Hunter x Hunter", "Mob Psycho 100", "Spy x Family",
                     "Chainsaw Man", "Bleach", "Tokyo Ghoul", "Sword Art Online", "Re:Zero"]
        
        return (0..<count).map { index in
            AnimeItem(
                title: titles.randomElement() ?? "Anime \(index)",
                imageURL: "anime_\(Int.random(in: 1...10))",
                synopsis: "An epic tale of adventure, friendship, and determination in a world filled with extraordinary powers and challenges.",
                rating: Double.random(in: 6.5...9.9),
                genres: Array(availableGenres.shuffled().prefix(Int.random(in: 2...4))),
                episodeCount: Int.random(in: 12...500),
                status: ["Ongoing", "Completed"].randomElement()!
            )
        }
    }
    
    func getFilteredItems(searchText: String, selectedGenres: Set<String>) -> [AnimeItem] {
        var items = animeItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by genres
        if !selectedGenres.isEmpty {
            items = items.filter { anime in
                !Set(anime.genres).isDisjoint(with: selectedGenres)
            }
        }
        
        return items
    }
}
