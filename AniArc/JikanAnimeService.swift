//
//  JikanAnimeService.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation
import Combine

// MARK: - Jikan API Response Models
struct JikanResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: JikanPagination?
}

struct JikanSingleResponse<T: Codable>: Codable {
    let data: T
}

struct JikanPagination: Codable {
    let lastVisiblePage: Int
    let hasNextPage: Bool
    let currentPage: Int
    let items: JikanPaginationItems
    
    private enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
        case currentPage = "current_page"
        case items
    }
}

struct JikanPaginationItems: Codable {
    let count: Int
    let total: Int
    let perPage: Int
    
    private enum CodingKeys: String, CodingKey {
        case count, total
        case perPage = "per_page"
    }
}

struct JikanAnimeData: Codable {
    let malID: Int
    let url: String
    let images: JikanImages
    let trailer: JikanTrailer?
    let approved: Bool
    let titles: [JikanTitle]
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let titleSynonyms: [String]
    let type: String?
    let source: String?
    let episodes: Int?
    let status: String
    let airing: Bool
    let aired: JikanAired
    let duration: String?
    let rating: String?
    let score: Double?
    let scoredBy: Int?
    let rank: Int?
    let popularity: Int?
    let members: Int?
    let favorites: Int?
    let synopsis: String?
    let background: String?
    let season: String?
    let year: Int?
    let broadcast: JikanBroadcast?
    let producers: [JikanStudio]
    let licensors: [JikanStudio]
    let studios: [JikanStudio]
    let genres: [JikanGenre]
    let explicitGenres: [JikanGenre]
    let themes: [JikanGenre]
    let demographics: [JikanGenre]
    
    private enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case url, images, trailer, approved, titles, title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case titleSynonyms = "title_synonyms"
        case type, source, episodes, status, airing, aired
        case duration, rating, score
        case scoredBy = "scored_by"
        case rank, popularity, members, favorites, synopsis, background
        case season, year, broadcast, producers, licensors, studios
        case genres
        case explicitGenres = "explicit_genres"
        case themes, demographics
    }
}

struct JikanImages: Codable {
    let jpg: JikanImageVariant
    let webp: JikanImageVariant
}

struct JikanImageVariant: Codable {
    let imageURL: String
    let smallImageURL: String
    let largeImageURL: String
    
    private enum CodingKeys: String, CodingKey {
        case imageURL = "image_url"
        case smallImageURL = "small_image_url"
        case largeImageURL = "large_image_url"
    }
}

struct JikanTitle: Codable {
    let type: String
    let title: String
}

struct JikanTrailer: Codable {
    let youtubeID: String?
    let url: String?
    let embedURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case youtubeID = "youtube_id"
        case url
        case embedURL = "embed_url"
    }
}

struct JikanAired: Codable {
    let from: String?
    let to: String?
    let prop: JikanAiredProp
    let string: String?
}

struct JikanAiredProp: Codable {
    let from: JikanDate?
    let to: JikanDate?
}

struct JikanDate: Codable {
    let day: Int?
    let month: Int?
    let year: Int?
}

struct JikanBroadcast: Codable {
    let day: String?
    let time: String?
    let timezone: String?
    let string: String?
}

// MARK: - Jikan API Service
@MainActor
class JikanAnimeService: ObservableObject {
    private let baseURL = "https://api.jikan.moe/v4"
    private let session = URLSession.shared
    private var requestQueue = DispatchQueue(label: "jikan.api.queue", qos: .background)
    private var lastRequestTime = Date()
    private let rateLimitDelay: TimeInterval = 0.5 // 500ms between requests
    
    // MARK: - Public API Methods
    
    /// Fetch top anime with pagination
    func fetchTopAnime(page: Int = 1, limit: Int = 25) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        let endpoint = "/top/anime?page=\(page)&limit=\(limit)"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    /// Search anime by query
    func searchAnime(query: String, page: Int = 1, limit: Int = 25) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              !encodedQuery.isEmpty else {
            return ([], false)
        }
        
        let endpoint = "/anime?q=\(encodedQuery)&page=\(page)&limit=\(limit)&order_by=popularity&sort=asc"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    /// Fetch anime by season and year
    func fetchSeasonalAnime(year: Int, season: String, page: Int = 1) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        let endpoint = "/seasons/\(year)/\(season.lowercased())?page=\(page)"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    /// Fetch anime by genre
    func fetchAnimeByGenres(genreIDs: [Int], page: Int = 1) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        let genresString = genreIDs.map { String($0) }.joined(separator: ",")
        let endpoint = "/anime?genres=\(genresString)&page=\(page)&order_by=popularity&sort=asc"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    /// Fetch single anime by ID
    func fetchAnimeDetails(id: Int) async throws -> AnimeItem? {
        let endpoint = "/anime/\(id)"
        let response: JikanSingleResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        return convertToAnimeItem(response.data)
    }
    
    /// Fetch current season anime
    func fetchCurrentSeasonAnime(page: Int = 1) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        let endpoint = "/seasons/now?page=\(page)"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    /// Fetch upcoming anime
    func fetchUpcomingAnime(page: Int = 1) async throws -> (animeList: [AnimeItem], hasMore: Bool) {
        let endpoint = "/seasons/upcoming?page=\(page)"
        let response: JikanResponse<JikanAnimeData> = try await performRequest(endpoint: endpoint)
        
        let animeItems = response.data.compactMap { convertToAnimeItem($0) }
        let hasMore = response.pagination?.hasNextPage ?? false
        
        return (animeItems, hasMore)
    }
    
    // MARK: - Private Helper Methods
    
    private func performRequest<T: Codable>(endpoint: String) async throws -> T {
        await enforceRateLimit()
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw JikanError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("AniArc/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JikanError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            case 429:
                throw JikanError.rateLimited
            case 404:
                throw JikanError.notFound
            default:
                throw JikanError.serverError(httpResponse.statusCode)
            }
        } catch {
            if error is DecodingError {
                print("Decoding error for endpoint \(endpoint): \(error)")
                throw JikanError.decodingError
            } else {
                throw JikanError.networkError(error)
            }
        }
    }
    
    private func enforceRateLimit() async {
        let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < rateLimitDelay {
            let sleepTime = rateLimitDelay - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
    
    private func convertToAnimeItem(_ jikanData: JikanAnimeData) -> AnimeItem? {
        return AnimeItem(
            id: jikanData.malID,
            title: jikanData.title,
            imageURL: jikanData.images.jpg.largeImageURL,
            synopsis: jikanData.synopsis ?? "No synopsis available.",
            rating: jikanData.score ?? 0.0,
            genres: jikanData.genres.map { $0.name },
            episodeCount: jikanData.episodes ?? 0,
            status: jikanData.status,
            year: jikanData.year,
            season: jikanData.season,
            type: jikanData.type,
            source: jikanData.source,
            studios: jikanData.studios.map { $0.name },
            malID: jikanData.malID,
            score: jikanData.score,
            scoredBy: jikanData.scoredBy,
            rank: jikanData.rank,
            popularity: jikanData.popularity
        )
    }
}

// MARK: - Error Handling
enum JikanError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case rateLimited
    case notFound
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for Jikan API request"
        case .invalidResponse:
            return "Invalid response from Jikan API"
        case .decodingError:
            return "Failed to decode Jikan API response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        case .notFound:
            return "Anime not found"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}

// MARK: - Genre Constants
extension JikanAnimeService {
    static let genreMap: [String: Int] = [
        "Action": 1,
        "Adventure": 2,
        "Comedy": 4,
        "Drama": 8,
        "Fantasy": 10,
        "Romance": 22,
        "Sci-Fi": 24,
        "Slice of Life": 36,
        "Supernatural": 37,
        "Military": 38,
        "Horror": 14,
        "Mystery": 7,
        "Psychological": 40,
        "Thriller": 41,
        "Sports": 30,
        "School": 23
    ]
}