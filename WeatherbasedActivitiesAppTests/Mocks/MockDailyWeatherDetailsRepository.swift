//
//  MockDailyWeatherDetailsRepository.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation
@testable import WeatherbasedActivitiesApp

final class MockWeatherService: DailyWeatherForecastRepository {
    var forecastToReturn: [DailyWeatherForecastModel] = []
    var errorToThrow: Error?
    private(set) var lastRequestedCity: CityModel?
    private(set) var lastRequestedDays: Int?

    func getDailyWeatherForecastDetails(for city: CityModel, days: Int) async throws -> [DailyWeatherForecastModel] {
        lastRequestedCity = city
        lastRequestedDays = days
        if let errorToThrow {
            throw errorToThrow
        }
        return forecastToReturn
    }
}

