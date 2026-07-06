//
//  RepositoryTests.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

import XCTest
@testable import WeatherbasedActivitiesApp

private final class MockAPIClient: APIClient {
    var resultToReturn: Any?
    var errorToThrow: Error?
    private(set) var lastEndpoint: APIEndpoint?

    func get<T>(_ endpoint: APIEndpoint) async throws -> T where T: Decodable {
        lastEndpoint = endpoint
        if let errorToThrow {
            throw errorToThrow
        }
        guard let result = resultToReturn as? T else {
            fatalError("MockAPIClient not configured with a result of type \(T.self)")
        }
        return result
    }
}

@MainActor
final class RepositoryTests: XCTestCase {

    // MARK: OpenMeteoGeocodingService

    func test_geocodingService_mapsResultsToCities() async throws {
        let client = MockAPIClient()
        client.resultToReturn = CityResponseModelDTO(results: [
            CityResultModelDTO(id: 1, name: "Innsbruck", latitude: 47.26, longitude: 11.39, country: "Austria", countryCode: "AT", admin1: "Tyrol", timezone: "Europe/Vienna")
        ])
        let service = CityRepositoryImp(apiClient: client)

        let cities = try await service.searchCityByName(cityName: "Innsbruck")

        XCTAssertEqual(cities.count, 1)
        XCTAssertEqual(cities.first?.name, "Innsbruck")
    }

    func test_geocodingService_withNilResults_returnsEmptyArray() async throws {
        let client = MockAPIClient()
        client.resultToReturn = CityResponseModelDTO(results: nil)
        let service = CityRepositoryImp(apiClient: client)

        let cities = try await service.searchCityByName(cityName: "Nowhereville")

        XCTAssertEqual(cities, [])
    }

    func test_geocodingService_propagatesClientError() async {
        let client = MockAPIClient()
        client.errorToThrow = AppError.noConnection
        let service = CityRepositoryImp(apiClient: client)

        do {
            _ = try await service.searchCityByName(cityName: "Innsbruck")
            XCTFail("Expected an error")
        } catch let error as AppError {
            XCTAssertEqual(error, .noConnection)
        } catch {
            XCTFail("Expected AppError, got \(error)")
        }
    }

    // MARK: OpenMeteoWeatherService

    func test_weatherService_mapsForecastResponseToDailyForecasts() async throws {
        let client = MockAPIClient()
        client.resultToReturn = DailyWeatherForecastResponseModelDTO(
            daily: DailyWeatherDetailsDTO(
                time: ["2026-07-03"],
                weathercode: [0],
                temperature2mMax: [22.0],
                temperature2mMin: [12.0],
                precipitationSum: [0],
                precipitationProbabilityMax: [10],
                snowfallSum: [0],
                windspeed10mMax: [10],
                windgusts10mMax: [15],
                cloudcoverMean: [5]
            ),
            timezone: "Europe/Vienna"
        )
        let service = DailyWeatherDetailsRepositoryImp(apiClient: client)

        let days = try await service.getDailyWeatherForecastDetails(for: Fixtures.city(), days: 7)

        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days.first?.temperatureMaxC, 22.0)
    }

    // MARK: Endpoint URL construction

    func test_geocodingEndpoint_buildsExpectedURL() {
        let url = APIEndpoint.citySearch(name: "Innsbruck", count: 5).url
        XCTAssertEqual(url?.host, "geocoding-api.open-meteo.com")
        XCTAssertEqual(url?.path, "/v1/search")
        XCTAssertTrue(url?.query?.contains("name=Innsbruck") ?? false)
        XCTAssertTrue(url?.query?.contains("count=5") ?? false)
    }

    func test_forecastEndpoint_buildsExpectedURL() {
        let url = APIEndpoint.forecast(latitude: 47.26, longitude: 11.39, timezone: "Europe/Vienna", forecastDays: 7).url
        XCTAssertEqual(url?.host, "api.open-meteo.com")
        XCTAssertEqual(url?.path, "/v1/forecast")
        XCTAssertTrue(url?.query?.contains("forecast_days=7") ?? false)
        XCTAssertTrue(url?.query?.contains("daily=weathercode") ?? false)
    }

    func test_forecastEndpoint_defaultsTimezoneToAuto() {
        let url = APIEndpoint.forecast(latitude: 47.26, longitude: 11.39, timezone: nil, forecastDays: 7).url
        XCTAssertTrue(url?.query?.contains("timezone=auto") ?? false)
    }
}
