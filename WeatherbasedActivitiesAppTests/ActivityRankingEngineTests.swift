//
//  ActivityRankingEngineTests.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import XCTest
@testable import WeatherbasedActivitiesApp

final class ActivityRankingEngineTests: XCTestCase {
    private var engine: ActivityRankingSystemImpl!

    override func setUp() {
        super.setUp()
        engine = ActivityRankingSystemImpl()
    }

    func test_rank_returnsAllFourActivities() {
        let forecast = [Fixtures.day()]
        let result = engine.rank(forecast: forecast)
        XCTAssertEqual(Set(result.map { $0.activity }), Set(Activity.allCases))
    }

    func test_rank_withEmptyForecast_returnsZeroScoresForAllActivities() {
        let result = engine.rank(forecast: [])
        XCTAssertEqual(result.count, Activity.allCases.count)
        XCTAssertTrue(result.allSatisfy { $0.overallScore == 0 })
        XCTAssertTrue(result.allSatisfy { $0.bestDay == nil })
    }

    func test_rank_sortsByOverallScoreDescending() {
        let forecast = [
            Fixtures.day(weatherCode: .snowHeavy, tempMax: -5, tempMin: -10, snowfallSum: 12, windSpeedMax: 10)
        ]
        let result = engine.rank(forecast: forecast)
        for i in 0..<(result.count - 1) {
            XCTAssertGreaterThanOrEqual(result[i].overallScore, result[i + 1].overallScore)
        }
    }

    // MARK: Skiing

    func test_skiing_scoresHigh_forColdSnowyLowWindDay() {
        let snowyDay = Fixtures.day(weatherCode: .snowHeavy, tempMax: -4, tempMin: -10, snowfallSum: 10, windSpeedMax: 15)
        let result = engine.rank(forecast: [snowyDay])
        let skiing = result.first { $0.activity == .skiing }!
        XCTAssertGreaterThan(skiing.overallScore, 80)
    }

    func test_skiing_scoresLow_forHotDryDay() {
        let hotDay = Fixtures.day(weatherCode: .clearSky, tempMax: 30, tempMin: 20, snowfallSum: 0, windSpeedMax: 5)
        let result = engine.rank(forecast: [hotDay])
        let skiing = result.first { $0.activity == .skiing }!
        XCTAssertLessThan(skiing.overallScore, 20)
    }

    func test_skiing_isPenalized_byDangerouslyHighWind() {
        let calmSnowyDay = Fixtures.day(weatherCode: .snowHeavy, tempMax: -4, tempMin: -10, snowfallSum: 10, windSpeedMax: 20)
        let windySnowyDay = Fixtures.day(weatherCode: .snowHeavy, tempMax: -4, tempMin: -10, snowfallSum: 10, windSpeedMax: 80)

        let calmScore = engine.rank(forecast: [calmSnowyDay]).first { $0.activity == .skiing }!.overallScore
        let windyScore = engine.rank(forecast: [windySnowyDay]).first { $0.activity == .skiing }!.overallScore

        XCTAssertLessThan(windyScore, calmScore)
    }

    // MARK: Surfing

    func test_surfing_scoresHigh_forModerateWindNoStorm() {
        let goodSurfDay = Fixtures.day(weatherCode: .partlyCloudy, windSpeedMax: 25)
        let result = engine.rank(forecast: [goodSurfDay])
        let surfing = result.first { $0.activity == .surfing }!
        XCTAssertGreaterThan(surfing.overallScore, 70)
    }

    func test_surfing_scoresLow_forFlatCalmDay() {
        let flatDay = Fixtures.day(weatherCode: .clearSky, windSpeedMax: 2)
        let result = engine.rank(forecast: [flatDay])
        let surfing = result.first { $0.activity == .surfing }!
        XCTAssertLessThan(surfing.overallScore, 15)
    }

    func test_surfing_isPenalized_byThunderstorms() {
        let stormySurfDay = Fixtures.day(weatherCode: .thunderstorm, windSpeedMax: 25)
        let calmSurfDay = Fixtures.day(weatherCode: .partlyCloudy, windSpeedMax: 25)

        let stormyScore = engine.rank(forecast: [stormySurfDay]).first { $0.activity == .surfing }!.overallScore
        let calmScore = engine.rank(forecast: [calmSurfDay]).first { $0.activity == .surfing }!.overallScore

        XCTAssertLessThan(stormyScore, calmScore)
    }

    // MARK: Outdoor sightseeing

    func test_outdoorSightseeing_scoresHigh_forMildClearDay() {
        let niceDay = Fixtures.day(weatherCode: .clearSky, tempMax: 20, precipProbability: 0, windSpeedMax: 8)
        let result = engine.rank(forecast: [niceDay])
        let outdoor = result.first { $0.activity == .outdoorSightseeing }!
        XCTAssertGreaterThan(outdoor.overallScore, 80)
    }

    func test_outdoorSightseeing_scoresLow_forRainyDay() {
        let rainyDay = Fixtures.day(weatherCode: .rainHeavy, tempMax: 15, precipProbability: 95, windSpeedMax: 30)
        let result = engine.rank(forecast: [rainyDay])
        let outdoor = result.first { $0.activity == .outdoorSightseeing }!
        XCTAssertLessThan(outdoor.overallScore, 30)
    }

    // MARK: Indoor sightseeing

    func test_indoorSightseeing_isBoosted_onRainyDay_comparedToClearDay() {
        let rainyDay = Fixtures.day(weatherCode: .rainHeavy, tempMax: 15, precipProbability: 95)
        let clearDay = Fixtures.day(weatherCode: .clearSky, tempMax: 20, precipProbability: 0)

        let rainyIndoorScore = engine.rank(forecast: [rainyDay]).first { $0.activity == .indoorSightseeing }!.overallScore
        let clearIndoorScore = engine.rank(forecast: [clearDay]).first { $0.activity == .indoorSightseeing }!.overallScore

        XCTAssertGreaterThan(rainyIndoorScore, clearIndoorScore)
    }

    func test_indoorSightseeing_neverScoresNearZero_regardlessOfWeather() {
        let extremeDay = Fixtures.day(weatherCode: .clearSky, tempMax: 20, precipProbability: 0, windSpeedMax: 5)
        let result = engine.rank(forecast: [extremeDay])
        let indoor = result.first { $0.activity == .indoorSightseeing }!
        XCTAssertGreaterThanOrEqual(indoor.overallScore, 50)
    }

    // MARK: Aggregation

    func test_overallScore_isAverageOfDailyScores() {
        let coldSnowyDay = Fixtures.day(offsetDays: 0, weatherCode: .snowHeavy, tempMax: -5, snowfallSum: 10, windSpeedMax: 10)
        let hotDryDay = Fixtures.day(offsetDays: 1, weatherCode: .clearSky, tempMax: 30, snowfallSum: 0, windSpeedMax: 5)

        let result = engine.rank(forecast: [coldSnowyDay, hotDryDay])
        let skiing = result.first { $0.activity == .skiing }!

        let expectedAverage = skiing.dailyScores.map { $0.score }.reduce(0, +) / Double(skiing.dailyScores.count)
        XCTAssertEqual(skiing.overallScore, expectedAverage, accuracy: 0.0001)
    }

    func test_bestDay_isTheHighestScoringDay() {
        let mediocreDay = Fixtures.day(offsetDays: 0, weatherCode: .snowSlight, tempMax: -2, snowfallSum: 2, windSpeedMax: 10)
        let greatDay = Fixtures.day(offsetDays: 1, weatherCode: .snowHeavy, tempMax: -8, snowfallSum: 15, windSpeedMax: 10)

        let result = engine.rank(forecast: [mediocreDay, greatDay])
        let skiing = result.first { $0.activity == .skiing }!

        XCTAssertEqual(skiing.bestDay?.date, greatDay.date)
    }
}
