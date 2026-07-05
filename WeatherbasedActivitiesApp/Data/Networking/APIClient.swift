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
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw Self.map(urlError)
        } catch {
            throw AppError.unknown(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw AppError.unknown("Invalid response") }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppError.server(statusCode: httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
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
}
