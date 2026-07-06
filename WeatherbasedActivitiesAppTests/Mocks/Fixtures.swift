//
//  Fixtures.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation
@testable import WeatherbasedActivitiesApp

enum Fixtures {

    static func day(
        offsetDays: Int = 0,
        weatherCode: WeatherCode = .clearSky,
        tempMax: Double = 20,
        tempMin: Double = 10,
        precipSum: Double = 0,
        precipProbability: Double = 0,
        snowfallSum: Double = 0,
        windSpeedMax: Double = 10,
        windGustsMax: Double = 15,
        cloudCoverMean: Double? = 10
    ) -> DailyWeatherForecastModel {
        let date = Calendar.current.date(byAdding: .day, value: offsetDays, to: Date())!
        return DailyWeatherForecastModel(
            date: date,
            weatherCode: weatherCode,
            temperatureMaxC: tempMax,
            temperatureMinC: tempMin,
            precipitationSumMM: precipSum,
            precipitationProbabilityMaxPercent: precipProbability,
            snowfallSumCM: snowfallSum,
            windSpeedMaxKMH: windSpeedMax,
            windGustsMaxKMH: windGustsMax,
            cloudCoverMeanPercent: cloudCoverMean
        )
    }

    static func city(
        id: Int64 = 1,
        name: String = "Innsbruck",
        country: String = "Austria",
        admin1: String? = "Tyrol"
    ) -> CityModel {
        CityModel(
            id: id,
            name: name,
            country: country,
            countryCode: "AT",
            admin1: admin1,
            latitude: 47.26,
            longitude: 11.39,
            timezone: "Europe/Vienna"
        )
    }
}

