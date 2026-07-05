//
//  RankedAcitvityUseCase.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

protocol RankedAcitvityUseCase {
    func execute(cityModel: CityModel) async throws -> [ActivityRecommendation]
}

struct RankedAcitvityUseCaseImpl: RankedAcitvityUseCase {
    static let fetchforcastForNumberofDays = 7
    let dailyWeatherforcastReposittory: DailyWeatherForecastRepository
    let activityRecomendationSystem: ActivityRankingSystem
    /// Fetches the 7-day forecast for a city
    /// activity recommendations via the (pure, synchronous) ranking engine.
    func execute(cityModel: CityModel) async throws -> [ActivityRecommendation] {
        let dailyWeatherForecast = try await dailyWeatherforcastReposittory.getDailyWeatherForecastDetails(for: cityModel, days: RankedAcitvityUseCaseImpl.fetchforcastForNumberofDays)
        
        guard !dailyWeatherForecast.isEmpty else { throw AppError.noForecastData }
        
        return activityRecomendationSystem.rank(forecast: dailyWeatherForecast)
    }
}
