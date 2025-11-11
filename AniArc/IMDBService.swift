//
//  IMDBService.swift
//  AniArc
//
//  Created by Harlen Postill on 11/11/2025.
//

import Foundation
import Combine

// MARK: - IMDB API Models
struct IMDBSearchResponse: Codable {
    let titles: [IMDBTitle]
}

struct IMDBTitle: Codable {
    let id: String
    let type: String
    let primaryTitle: String
    let originalTitle: String
    let primaryImage: IMDBImage?
    let startYear: Int?
    let endYear: Int?
    let rating: IMDBRating?
}

struct IMDBImage: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct IMDBRating: Codable {
    let aggregateRating: Double
    let voteCount: Int
}

// MARK: - IMDB Service
class IMDBService: ObservableObject {
    private let baseURL = "https://api.imdbapi.dev"
    private let session = URLSession.shared
    
    @MainActor
    func searchTitles(query: String, limit: Int = 5) async throws -> IMDBSearchResponse? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/titles?query=\(encodedQuery)&limit=\(limit)") else {
            throw IMDBError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw IMDBError.invalidResponse
            }
            
            let searchResponse = try JSONDecoder().decode(IMDBSearchResponse.self, from: data)
            return searchResponse
        } catch {
            if error is DecodingError {
                throw IMDBError.decodingError
            } else {
                throw IMDBError.networkError(error)
            }
        }
    }
    
    @MainActor
    func buildStremioURL(from imdbTitle: IMDBTitle) -> URL? {
        let typeMapping: String
        switch imdbTitle.type.lowercased() {
        case "movie":
            typeMapping = "movie"
        case "tvseries", "tvminiseries", "tvepisode", "tvspecial":
            typeMapping = "series"
        default:
            typeMapping = "series" // Default to series for other types
        }
        
        let stremioURLString = "stremio:///detail/\(typeMapping)/\(imdbTitle.id)"
        return URL(string: stremioURLString)
    }
}

// MARK: - Error Handling
enum IMDBError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case noResultsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for IMDB API request"
        case .invalidResponse:
            return "Invalid response from IMDB API"
        case .decodingError:
            return "Failed to decode IMDB API response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noResultsFound:
            return "No matching titles found on IMDB"
        }
    }
}