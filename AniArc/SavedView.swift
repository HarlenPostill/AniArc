//
//  SavedView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct SavedView: View {
    @StateObject private var dataService = AnimeDataService()
    @State private var searchText: String = ""
    @State private var selectedCategory: SavedCategory = .all
    
    enum SavedCategory: String, CaseIterable {
        case all = "All"
        case library = "Library"
        case watchlist = "Watchlist"
        case completed = "Completed"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .library: return "bookmark.fill"
            case .watchlist: return "clock"
            case .completed: return "checkmark.circle"
            }
        }
    }
    
    private var filteredItems: [AnimeItem] {
        var items = dataService.animeItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Filter by category (for demo purposes, we'll just show different subsets)
        switch selectedCategory {
        case .all:
            break // Show all
        case .library:
            items = Array(items.prefix(5))
        case .watchlist:
            items = Array(items.dropFirst(5).prefix(3))
        case .completed:
            items = items.filter { $0.status == "Completed" }
        }
        
        return items
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SavedCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // Content
                if filteredItems.isEmpty {
                    EmptyStateView(category: selectedCategory)
                } else {
                    ScrollView {
                        AnimeGrid(
                            animeItems: filteredItems,
                            isLoading: dataService.isLoading
                        )
                    }
                }
            }
            .navigationTitle("My Collection")
            .searchable(text: $searchText, prompt: "Search your collection...")
        }
        .task {
            if dataService.animeItems.isEmpty {
                await dataService.loadInitialItems()
            }
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: SavedView.SavedCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            )
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let category: SavedView.SavedCategory
    
    private var emptyStateConfig: (image: String, title: String, subtitle: String) {
        switch category {
        case .all:
            return ("bookmark", "No Saved Content", "Save anime to your collection to see them here")
        case .library:
            return ("bookmark.fill", "Library is Empty", "Add anime to your library to keep track of your favorites")
        case .watchlist:
            return ("clock", "Watchlist is Empty", "Add anime to your watchlist to watch them later")
        case .completed:
            return ("checkmark.circle", "No Completed Anime", "Mark anime as completed to see your progress")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: emptyStateConfig.image)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(emptyStateConfig.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(emptyStateConfig.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            NavigationLink(destination: ExploreView()) {
                Text("Explore Anime")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
}
