//
//  File.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

protocol APIClient {
    func get<T: Codable>(_ endpoint: APIEndpoint) async throws -> T
}

final class URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func get<T: Codable>(_ apiEndPoint: APIEndpoint) async throws -> T {
        guard let url = apiEndPoint.url else { throw AppError.inValidURL }
        // 1. Log the Outgoing Request
        print("🛫 [API Request] GET -> \(url.absoluteString)")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            print("❌ [API Error] Network Error: \(urlError.localizedDescription)")
            throw Self.map(urlError)
        } catch {
            print("❌ [API Error] Network Error: \(error.localizedDescription)")
            throw AppError.unknown(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw AppError.unknown("Invalid response") }
        
        // 2. Log the Incoming Response Metadata & Body
        logResponse(httpResponse, data: data)
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ [API Error] Invalid Response Type")
            throw AppError.server(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ [API Error] Decoding Failed for \(T.self): \(error)")
            throw AppError.decodingFailed
        }
    }
    
    private static func map(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noConnection
        case .timedOut:
            return .timedOut
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Logging Helper
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        let statusCode = response.statusCode
        let emoji = (200...299).contains(statusCode) ? "🛬" : "⚠️"
        
        print("\(emoji) [API Response] Status Code: \(statusCode) | URL: \(response.url?.absoluteString ?? "")")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 [API Body]: \(jsonString)\n")
        } else {
            print("📦 [API Body]: Unable to convert data to UTF-8 String\n")
        }
    }
}
