//
//  UserDataManager.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class UserDataManager {
    var watchlistEntries: [UserAnimeEntry] = []
    var favorites: Set<Int> = []
    var userRatings: [Int: Int] = [:] // AnimeID: Rating (1-10)
    var watchProgress: [Int: Int] = [:] // AnimeID: Episodes watched
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let watchlistKey = "user_watchlist"
    private let favoritesKey = "user_favorites"
    private let ratingsKey = "user_ratings"
    private let progressKey = "user_progress"
    
    init() {
        loadUserData()
    }
    
    // MARK: - Watchlist Management
    
    func addToWatchlist(_ anime: AnimeItem, status: WatchStatus = .planToWatch) {
        let entry = UserAnimeEntry(
            id: anime.id,
            isInWatchlist: true,
            dateAdded: Date(),
            watchStatus: status
        )
        
        if let existingIndex = watchlistEntries.firstIndex(where: { $0.id == anime.id }) {
            watchlistEntries[existingIndex] = entry
        } else {
            watchlistEntries.append(entry)
        }
        
        saveUserData()
    }
    
    func removeFromWatchlist(_ animeID: Int) {
        watchlistEntries.removeAll { $0.id == animeID }
        saveUserData()
    }
    
    func updateWatchStatus(animeID: Int, status: WatchStatus) {
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].watchStatus = status
            saveUserData()
        }
    }
    
    func updateWatchProgress(animeID: Int, progress: Int) {
        watchProgress[animeID] = progress
        
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].watchProgress = progress
        }
        
        saveUserData()
    }
    
    func isInWatchlist(_ animeID: Int) -> Bool {
        return watchlistEntries.contains { $0.id == animeID }
    }
    
    func getWatchlistEntry(for animeID: Int) -> UserAnimeEntry? {
        return watchlistEntries.first { $0.id == animeID }
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(_ animeID: Int) {
        if favorites.contains(animeID) {
            favorites.remove(animeID)
        } else {
            favorites.insert(animeID)
        }
        
        // Also update in watchlist if exists
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].isFavorite = favorites.contains(animeID)
        }
        
        saveUserData()
    }
    
    func isFavorite(_ animeID: Int) -> Bool {
        return favorites.contains(animeID)
    }
    
    // MARK: - Rating Management
    
    func setUserRating(animeID: Int, rating: Int) {
        guard rating >= 1 && rating <= 10 else { return }
        userRatings[animeID] = rating
        
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].userRating = rating
        }
        
        saveUserData()
    }
    
    func removeUserRating(animeID: Int) {
        userRatings.removeValue(forKey: animeID)
        
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].userRating = nil
        }
        
        saveUserData()
    }
    
    func getUserRating(for animeID: Int) -> Int? {
        return userRatings[animeID]
    }
    
    // MARK: - Notes Management
    
    func updateNotes(animeID: Int, notes: String) {
        if let index = watchlistEntries.firstIndex(where: { $0.id == animeID }) {
            watchlistEntries[index].notes = notes
        } else {
            // Create entry if doesn't exist
            let entry = UserAnimeEntry(id: animeID, notes: notes)
            watchlistEntries.append(entry)
        }
        saveUserData()
    }
    
    func getNotes(for animeID: Int) -> String {
        return watchlistEntries.first { $0.id == animeID }?.notes ?? ""
    }
    
    // MARK: - Filtering and Sorting
    
    func getWatchlistAnime(by status: WatchStatus) -> [UserAnimeEntry] {
        return watchlistEntries.filter { $0.watchStatus == status }
    }
    
    func getFavoriteAnimeIDs() -> [Int] {
        return Array(favorites)
    }
    
    func getRecentlyAdded(limit: Int = 10) -> [UserAnimeEntry] {
        return watchlistEntries
            .compactMap { entry -> (UserAnimeEntry, Date)? in
                guard let date = entry.dateAdded else { return nil }
                return (entry, date)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
    
    func getCompletionStats() -> (completed: Int, watching: Int, planToWatch: Int, total: Int) {
        let completed = watchlistEntries.filter { $0.watchStatus == .completed }.count
        let watching = watchlistEntries.filter { $0.watchStatus == .watching }.count
        let planToWatch = watchlistEntries.filter { $0.watchStatus == .planToWatch }.count
        let total = watchlistEntries.count
        
        return (completed, watching, planToWatch, total)
    }
    
    // MARK: - Data Persistence
    
    private func saveUserData() {
        // Save watchlist
        if let watchlistData = try? JSONEncoder().encode(watchlistEntries) {
            userDefaults.set(watchlistData, forKey: watchlistKey)
        }
        
        // Save favorites
        let favoritesArray = Array(favorites)
        userDefaults.set(favoritesArray, forKey: favoritesKey)
        
        // Save ratings
        userDefaults.set(userRatings, forKey: ratingsKey)
        
        // Save progress
        userDefaults.set(watchProgress, forKey: progressKey)
    }
    
    private func loadUserData() {
        // Load watchlist
        if let watchlistData = userDefaults.data(forKey: watchlistKey),
           let entries = try? JSONDecoder().decode([UserAnimeEntry].self, from: watchlistData) {
            watchlistEntries = entries
        }
        
        // Load favorites
        if let favoritesArray = userDefaults.array(forKey: favoritesKey) as? [Int] {
            favorites = Set(favoritesArray)
        }
        
        // Load ratings
        if let ratingsDict = userDefaults.dictionary(forKey: ratingsKey) as? [String: Int] {
            userRatings = Dictionary(uniqueKeysWithValues: ratingsDict.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }
        
        // Load progress
        if let progressDict = userDefaults.dictionary(forKey: progressKey) as? [String: Int] {
            watchProgress = Dictionary(uniqueKeysWithValues: progressDict.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }
    }
    
    // MARK: - Utility Methods
    
    func clearAllData() {
        watchlistEntries.removeAll()
        favorites.removeAll()
        userRatings.removeAll()
        watchProgress.removeAll()
        
        userDefaults.removeObject(forKey: watchlistKey)
        userDefaults.removeObject(forKey: favoritesKey)
        userDefaults.removeObject(forKey: ratingsKey)
        userDefaults.removeObject(forKey: progressKey)
    }
    
    func exportUserData() -> [String: Any] {
        return [
            "watchlist": watchlistEntries.compactMap { entry in
                try? JSONEncoder().encode(entry)
            }.compactMap { data in
                try? JSONSerialization.jsonObject(with: data)
            },
            "favorites": Array(favorites),
            "ratings": userRatings,
            "progress": watchProgress,
            "exportDate": Date().iso8601String
        ]
    }
    
    func importUserData(_ data: [String: Any]) {
        // Implementation for importing user data
        // This could be useful for syncing across devices or backup/restore
        if let favoritesArray = data["favorites"] as? [Int] {
            favorites = Set(favoritesArray)
        }
        
        if let ratingsDict = data["ratings"] as? [String: Int] {
            userRatings = Dictionary(uniqueKeysWithValues: ratingsDict.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }
        
        if let progressDict = data["progress"] as? [String: Int] {
            watchProgress = Dictionary(uniqueKeysWithValues: progressDict.compactMap { key, value in
                guard let intKey = Int(key) else { return nil }
                return (intKey, value)
            })
        }
        
        saveUserData()
    }
}

// MARK: - Extensions
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}