//
//  DailyWeatherDetailsRepository.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

protocol DailyWeatherForecastRepository {
    func getDailyWeatherForecastDetails(for city: CityModel, days: Int) async throws -> [DailyWeatherForecastModel]
}

