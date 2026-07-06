//
//  UseCaseTests.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import XCTest
@testable import WeatherbasedActivitiesApp

@MainActor
final class UseCaseTests: XCTestCase {

    // MARK: SearchCityUseCase

    func test_searchCityUseCase_trimsWhitespaceBeforeSearching() async throws {
        let service = MockCityRepository()
        service.citiesToReturn = [Fixtures.city()]
        let useCase = SearchCityUseCaseImpl(cityRepository: service)

        _ = try await useCase.execute(cityName: "  Innsbruck  ")

        XCTAssertEqual(service.lastQuery, "Innsbruck")
    }

    func test_searchCityUseCase_shortQuery_returnsEmptyWithoutCallingService() async throws {
        let service = MockCityRepository()
        let useCase = SearchCityUseCaseImpl(cityRepository: service)

        let result = try await useCase.execute(cityName: "a")

        XCTAssertEqual(result, [])
        XCTAssertEqual(service.callCount, 0)
    }

    func test_searchCityUseCase_propagatesServiceError() async {
        let service = MockCityRepository()
        service.errorToThrow = AppError.server(statusCode: 500)
        let useCase = SearchCityUseCaseImpl(cityRepository: service)

        do {
            _ = try await useCase.execute(cityName: "Innsbruck")
            XCTFail("Expected an error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, .server(statusCode: 500))
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }

    // MARK: RankActivitiesUseCase

    func test_rankActivitiesUseCase_returnsRankedRecommendations() async throws {
        let weatherService = MockWeatherService()
        weatherService.forecastToReturn = [Fixtures.day(weatherCode: .snowHeavy, tempMax: -5, snowfallSum: 12)]
        let useCase = RankActivitiesUseCaseImpl(dailyWeatherforcastReposittory: weatherService, activityRecomendationSystem: ActivityRankingSystemImpl())

        let result = try await useCase.execute(cityModel: Fixtures.city())

        XCTAssertEqual(result.count, Activity.allCases.count)
        XCTAssertEqual(weatherService.lastRequestedDays, RankActivitiesUseCaseImpl.fetchforcastForNumberofDays)
    }

    func test_rankActivitiesUseCase_withEmptyForecast_throwsNoForecastData() async {
        let weatherService = MockWeatherService()
        weatherService.forecastToReturn = []
        let useCase = RankActivitiesUseCaseImpl(dailyWeatherforcastReposittory: weatherService, activityRecomendationSystem: ActivityRankingSystemImpl())

        do {
            _ = try await useCase.execute(cityModel: Fixtures.city())
            XCTFail("Expected an error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, .noForecastData)
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }

    func test_rankActivitiesUseCase_propagatesWeatherServiceError() async {
        let weatherService = MockWeatherService()
        weatherService.errorToThrow = AppError.noConnection
        let useCase = RankActivitiesUseCaseImpl(dailyWeatherforcastReposittory: weatherService, activityRecomendationSystem: ActivityRankingSystemImpl())

        do {
            _ = try await useCase.execute(cityModel: Fixtures.city())
            XCTFail("Expected an error to be thrown")
        } catch let error as AppError {
            XCTAssertEqual(error, .noConnection)
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }
}

