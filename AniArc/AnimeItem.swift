//
//  AnimeItem.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation

// MARK: - Models
struct AnimeItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let imageURL: String
    let synopsis: String
    let rating: Double // Legacy property, use score instead
    let genres: [String]
    let episodeCount: Int
    let status: String
    let year: Int?
    let season: String?
    let type: String? // TV, Movie, OVA, etc.
    let source: String? // Manga, Light novel, etc.
    let studios: [String]
    let malID: Int
    let score: Double?
    let scoredBy: Int?
    let rank: Int?
    let popularity: Int?
    
    // User-specific properties (not from API)
    var isInWatchlist: Bool = false
    var userRating: Int? = nil
    var watchProgress: Int = 0
    var dateAdded: Date? = nil
    
    // Custom coding keys for API mapping
    private enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title
        case imageURL = "image_url"
        case synopsis
        case genres
        case episodeCount = "episodes"
        case status
        case year
        case season
        case type
        case source
        case studios
        case score
        case scoredBy = "scored_by"
        case rank
        case popularity
    }
    
    // Initialize from API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        malID = id
        
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Unknown Title"
        
        // Handle image URL - Jikan API has nested image structure
        if let images = try? container.decode([String: [String: String]].self, forKey: .imageURL),
           let jpg = images["jpg"],
           let imageUrl = jpg["image_url"] {
            imageURL = imageUrl
        } else {
            imageURL = ""
        }
        
        synopsis = try container.decodeIfPresent(String.self, forKey: .synopsis) ?? "No synopsis available."
        
        // Handle genres array
        if let genresArray = try? container.decode([JikanGenre].self, forKey: .genres) {
            genres = genresArray.map { $0.name }
        } else {
            genres = []
        }
        
        episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "Unknown"
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        season = try container.decodeIfPresent(String.self, forKey: .season)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        
        // Handle studios array
        if let studiosArray = try? container.decode([JikanStudio].self, forKey: .studios) {
            studios = studiosArray.map { $0.name }
        } else {
            studios = []
        }
        
        score = try container.decodeIfPresent(Double.self, forKey: .score)
        rating = score ?? 0.0 // Set rating as alias for score for backward compatibility
        scoredBy = try container.decodeIfPresent(Int.self, forKey: .scoredBy)
        rank = try container.decodeIfPresent(Int.self, forKey: .rank)
        popularity = try container.decodeIfPresent(Int.self, forKey: .popularity)
    }
    
    // Manual initializer for creating instances programmatically
    init(id: Int, title: String, imageURL: String, synopsis: String, rating: Double, 
         genres: [String], episodeCount: Int, status: String, year: Int? = nil, 
         season: String? = nil, type: String? = nil, source: String? = nil, 
         studios: [String] = [], malID: Int? = nil, score: Double? = nil, 
         scoredBy: Int? = nil, rank: Int? = nil, popularity: Int? = nil) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.synopsis = synopsis
        self.rating = rating
        self.genres = genres
        self.episodeCount = episodeCount
        self.status = status
        self.year = year
        self.season = season
        self.type = type
        self.source = source
        self.studios = studios
        self.malID = malID ?? id
        self.score = score ?? rating
        self.scoredBy = scoredBy
        self.rank = rank
        self.popularity = popularity
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(synopsis, forKey: .synopsis)
        try container.encode(score, forKey: .score)
        try container.encode(genres, forKey: .genres)
        try container.encode(episodeCount, forKey: .episodeCount)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(year, forKey: .year)
        try container.encodeIfPresent(season, forKey: .season)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encode(studios, forKey: .studios)
        try container.encodeIfPresent(score, forKey: .score)
        try container.encodeIfPresent(scoredBy, forKey: .scoredBy)
        try container.encodeIfPresent(rank, forKey: .rank)
        try container.encodeIfPresent(popularity, forKey: .popularity)
    }
}

// MARK: - Supporting Jikan API Models
struct JikanGenre: Codable {
    let malID: Int
    let type: String
    let name: String
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case type, name, url
    }
}

struct JikanStudio: Codable {
    let malID: Int
    let type: String
    let name: String
    let url: String
    
    private enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case type, name, url
    }
}

// MARK: - User Data Models
struct UserAnimeEntry: Identifiable, Codable, Equatable {
    let id: Int // Same as AnimeItem id
    var isInWatchlist: Bool = false
    var userRating: Int? = nil
    var watchProgress: Int = 0
    var dateAdded: Date? = nil
    var notes: String = ""
    var isFavorite: Bool = false
    var watchStatus: WatchStatus = .planToWatch
}

enum WatchStatus: String, CaseIterable, Codable {
    case watching = "Watching"
    case completed = "Completed"
    case onHold = "On Hold"
    case dropped = "Dropped"
    case planToWatch = "Plan to Watch"
}