//
//  APIError.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

//ViewModel will only need to know exact error which will show to the user . No need to know for URL object format repsonse. Generic error for all differnet type of error
enum AppError: Error, Equatable, LocalizedError {
    case noConnection
    case timedOut
    case server(statusCode: Int)
    case decodingFailed
    case noResults
    case noForecastData
    case inValidURL
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection. Check your network and try again."
        case .timedOut:
            return "The request timed out. Please try again."
        case .server(let statusCode):
            return "The weather service returned an error (code \(statusCode)). Please try again later."
        case .decodingFailed:
            return "We couldn't understand the response from the weather service."
        case .noResults:
            return "No cities matched your search."
        case .noForecastData:
            return "No weather forcast details available"
        case .inValidURL:
            return "Error code 500 - Please connect with customer care representative"
        case .unknown(let message):
            return message
        }
    }
}

