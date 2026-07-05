//
//  APIEndpoint.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

enum APIEndpoint {
    case citySearch(name: String, count: Int = 10)
    case forecast(latitude: Double, longitude: Double, timezone: String?, forecastDays: Int)
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        
        switch self {
        case .citySearch(let name, let count):
            
            components.host = "geocoding-api.open-meteo.com"
            components.path = "/v1/search"
            components.queryItems = [
                URLQueryItem(name: "name", value: name),
                URLQueryItem(name: "count", value: String(count)),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "format", value: "json")
            ]
            
        case .forecast(let latitude, let longitude, let timezone, let forecastDays):
            components.host = "api.open-meteo.com"
            components.path = "/v1/forecast"
            let dailyParams = [
                "weathercode",
                "temperature_2m_max",
                "temperature_2m_min",
                "precipitation_sum",
                "precipitation_probability_max",
                "snowfall_sum",
                "windspeed_10m_max",
                "windgusts_10m_max",
                "cloudcover_mean"
            ].joined(separator: ",")

            components.queryItems = [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "daily", value: dailyParams),
                URLQueryItem(name: "forecast_days", value: String(forecastDays)),
                URLQueryItem(name: "timezone", value: timezone ?? "auto")
            ]
        }
        return components.url
    }
}
