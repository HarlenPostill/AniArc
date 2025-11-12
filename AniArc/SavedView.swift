//
//  SavedView.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import SwiftUI

struct SavedView: View {
    @Environment(UserDataManager.self) var userDataManager
    @StateObject private var dataService = AnimeDataService()
    @State private var searchText: String = ""
    @State private var selectedCategory: SavedCategory = .all
    @State private var userAnimeItems: [AnimeItem] = []
    
    enum SavedCategory: String, CaseIterable {
        case all = "All"
        case watching = "Watching"
        case completed = "Completed"
        case planToWatch = "Plan to Watch"
        case onHold = "On Hold"
        case favorites = "Favorites"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .watching: return "play.circle.fill"
            case .completed: return "checkmark.circle"
            case .planToWatch: return "clock"
            case .onHold: return "pause.circle"
            case .favorites: return "heart.fill"
            }
        }
        
        var watchStatus: WatchStatus? {
            switch self {
            case .watching: return .watching
            case .completed: return .completed
            case .planToWatch: return .planToWatch
            case .onHold: return .onHold
            default: return nil
            }
        }
    }
    
    private var filteredItems: [AnimeItem] {
        // First, get items based on category
        let categoryFilteredItems = getItemsByCategory()
        
        // Then apply search filter if needed
        if searchText.isEmpty {
            return categoryFilteredItems
        } else {
            return applySearchFilter(to: categoryFilteredItems)
        }
    }
    
    private func getItemsByCategory() -> [AnimeItem] {
        switch selectedCategory {
        case .all:
            return userAnimeItems
        case .favorites:
            return userAnimeItems.filter { userDataManager.isFavorite($0.id) }
        default:
            guard let status = selectedCategory.watchStatus else { return [] }
            let userEntries = userDataManager.getWatchlistAnime(by: status)
            return userAnimeItems.filter { anime in
                userEntries.contains { entry in entry.id == anime.id }
            }
        }
    }
    
    private func applySearchFilter(to items: [AnimeItem]) -> [AnimeItem] {
        return items.filter { anime in
            let titleMatches = anime.title.localizedCaseInsensitiveContains(searchText)
            let genreMatches = anime.genres.contains { genre in
                genre.localizedCaseInsensitiveContains(searchText)
            }
            return titleMatches || genreMatches
        }
    }
    
    private var stats: (total: Int, watching: Int, completed: Int, planToWatch: Int) {
        let completion = userDataManager.getCompletionStats()
        return (completion.total, completion.watching, completion.completed, completion.planToWatch)
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("My Anime")
                .searchable(text: $searchText, prompt: "Search your collection...")
                .toolbar {
                    toolbarContent
                }
        }
        .task {
            await loadUserAnimeData()
        }
        .onChange(of: userDataManager.watchlistEntries) { _, _ in
            Task {
                await loadUserAnimeData()
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            statsSection
            categoryPicker
            Divider()
            contentSection
        }
    }
    
    @ViewBuilder
    private var statsSection: some View {
        if !userDataManager.watchlistEntries.isEmpty {
            StatsOverview(stats: stats)
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SavedCategory.allCases, id: \.self) { category in
                    SavedCategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: getCategoryCount(category),
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if filteredItems.isEmpty {
            EmptyStateView(category: selectedCategory)
        } else {
            animeList
        }
    }
    
    @ViewBuilder
    private var animeList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredItems, id: \.id) { anime in
                    WatchlistAnimeCard(
                        anime: anime,
                        userEntry: userDataManager.getWatchlistEntry(for: anime.id)
                    )
                }
            }
            .padding()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Export Data") {
                    exportUserData()
                }
                Button("Clear All Data", role: .destructive) {
                    userDataManager.clearAllData()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private func getCategoryCount(_ category: SavedCategory) -> Int {
        switch category {
        case .all:
            return userDataManager.watchlistEntries.count
        case .favorites:
            return userDataManager.favorites.count
        default:
            if let status = category.watchStatus {
                return userDataManager.getWatchlistAnime(by: status).count
            }
            return 0
        }
    }
    
    private func loadUserAnimeData() async {
        // Load anime details for all watchlisted items
        let animeIds = userDataManager.watchlistEntries.map { $0.id }
        var loadedAnime: [AnimeItem] = []
        
        for animeId in animeIds {
            do {
                if let anime = try await JikanAnimeService().fetchAnimeDetails(id: animeId) {
                    loadedAnime.append(anime)
                }
            } catch {
                print("Failed to load anime \(animeId): \(error)")
            }
        }
        
        await MainActor.run {
            userAnimeItems = loadedAnime
        }
    }
    
    private func exportUserData() {
        let data = userDataManager.exportUserData()
        // In a real app, you'd present a share sheet or save to Files
        print("Exported user data: \(data)")
    }
}

// MARK: - Stats Overview
struct StatsOverview: View {
    let stats: (total: Int, watching: Int, completed: Int, planToWatch: Int)
    
    var body: some View {
        let totalStat = StatItem(title: "Total", value: stats.total, color: .blue)
        let watchingStat = StatItem(title: "Watching", value: stats.watching, color: .green)
        let completedStat = StatItem(title: "Completed", value: stats.completed, color: .purple)
        let planToWatchStat = StatItem(title: "Plan to Watch", value: stats.planToWatch, color: .orange)
        
        HStack(spacing: 20) {
            totalStat
            watchingStat
            completedStat
            planToWatchStat
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Button
struct SavedCategoryButton: View {
    let category: SavedView.SavedCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.caption)
                VStack(spacing: 2) {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .opacity(0.8)
                    }
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            )
        }
    }
}

// MARK: - Watchlist Anime Card
struct WatchlistAnimeCard: View {
    let anime: AnimeItem
    let userEntry: UserAnimeEntry?
    @Environment(UserDataManager.self) var userDataManager
    @State private var showingProgressUpdate = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Anime Image
            AsyncImage(url: URL(string: anime.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Anime Info
            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let entry = userEntry {
                    HStack {
                        Text(entry.watchStatus.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(entry.watchStatus).opacity(0.2))
                            .foregroundColor(statusColor(entry.watchStatus))
                            .clipShape(Capsule())
                        
                        if let userRating = entry.userRating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("\(userRating)/10")
                                    .font(.caption)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Progress
                    if anime.episodeCount > 0 {
                        HStack {
                            Text("\(entry.watchProgress)/\(anime.episodeCount) episodes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Update") {
                                showingProgressUpdate = true
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        ProgressView(value: Double(entry.watchProgress), total: Double(anime.episodeCount))
                            .tint(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingProgressUpdate) {
            if let entry = userEntry {
                UpdateProgressView(anime: anime, userEntry: entry)
            }
        }
    }
    
    private func statusColor(_ status: WatchStatus) -> Color {
        switch status {
        case .watching: return .green
        case .completed: return .blue
        case .planToWatch: return .orange
        case .onHold: return .yellow
        case .dropped: return .red
        }
    }
}

// MARK: - Update Progress View
struct UpdateProgressView: View {
    let anime: AnimeItem
    let userEntry: UserAnimeEntry
    @Environment(UserDataManager.self) var userDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var progress: Int
    @State private var status: WatchStatus
    @State private var rating: Int
    
    init(anime: AnimeItem, userEntry: UserAnimeEntry) {
        self.anime = anime
        self.userEntry = userEntry
        _progress = State(initialValue: userEntry.watchProgress)
        _status = State(initialValue: userEntry.watchStatus)
        _rating = State(initialValue: userEntry.userRating ?? 0)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Progress") {
                    Stepper("Episodes Watched: \(progress)", value: $progress, in: 0...max(anime.episodeCount, 1))
                    
                    // Auto-update status when completed
                    if progress == anime.episodeCount && anime.episodeCount > 0 {
                        Text("Completed! 🎉")
                            .foregroundColor(.green)
                            .onAppear {
                                status = .completed
                            }
                    }
                }
                
                Section("Status") {
                    Picker("Watch Status", selection: $status) {
                        ForEach(WatchStatus.allCases, id: \.self) { watchStatus in
                            Text(watchStatus.rawValue).tag(watchStatus)
                        }
                    }
                }
                
                Section("Your Rating") {
                    HStack {
                        ForEach(1...10, id: \.self) { star in
                            Button(action: {
                                rating = rating == star ? 0 : star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(anime.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        userDataManager.updateWatchProgress(animeID: anime.id, progress: progress)
                        userDataManager.updateWatchStatus(animeID: anime.id, status: status)
                        if rating > 0 {
                            userDataManager.setUserRating(animeID: anime.id, rating: rating)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let category: SavedView.SavedCategory
    
    private var emptyStateConfig: (image: String, title: String, subtitle: String) {
        switch category {
        case .all:
            return ("bookmark", "No Anime in List", "Add anime to your watchlist to see them here")
        case .watching:
            return ("play.circle", "Not Watching Anything", "Mark anime as 'Watching' to track your current shows")
        case .completed:
            return ("checkmark.circle", "No Completed Anime", "Mark anime as 'Completed' to see your finished shows")
        case .planToWatch:
            return ("clock", "Nothing Planned", "Add anime to 'Plan to Watch' for your future viewing")
        case .onHold:
            return ("pause.circle", "Nothing on Hold", "Put anime 'On Hold' when you take a break")
        case .favorites:
            return ("heart", "No Favorites", "Mark anime as favorites to see them here")
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

#Preview {
    SavedView()
        .environment(UserDataManager())
}
