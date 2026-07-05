//
//  DailyWeatherDetailsRepositoryImp.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

struct DailyWeatherDetailsRepositoryImp: DailyWeatherForecastRepository {
    let apiClient: APIClient
    func getDailyWeatherForecastDetails(for city: CityModel, days: Int) async throws -> [DailyWeatherForecastModel] {
        var response: DailyWeatherForecastResponseModelDTO = try await apiClient.get(
            .forecast(latitude: city.latitude,
                      longitude: city.longitude,
                      timezone: city.timezone,
                      forecastDays: days))
        return try response.toDomain()
    }
}
