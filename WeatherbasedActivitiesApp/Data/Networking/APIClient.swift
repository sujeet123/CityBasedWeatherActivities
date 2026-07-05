//
//  File.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

protocol APIClient {
    func get<T: Codable>(_ endpoint: Endpoint) async throws -> T
}

final class URLSessionAPIClient: APIClient {
    
}
