//
//  File.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import XCTest
@testable import WeatherbasedActivitiesApp

@MainActor
final class MapperTests: XCTestCase {

    func test_geocodingResultDTO_mapsToCity() {
        let dto = CityResultModelDTO(
            id: 42,
            name: "Innsbruck",
            latitude: 47.26,
            longitude: 11.39,
            country: "Austria",
            countryCode: "AT",
            admin1: "Tyrol",
            timezone: "Europe/Vienna"
        )

        let city = dto.toDomain()

        XCTAssertEqual(city.id, 42)
        XCTAssertEqual(city.name, "Innsbruck")
        XCTAssertNotEqual(city.displayName, "Innsbruck, Tyrol, Austria")
    }

    func test_geocodingResponseDecoding_parsesRealisticJSON() throws {
        let json = """
        {
          "results": [
            {
              "id": 2761369,
              "name": "Innsbruck",
              "latitude": 47.26266,
              "longitude": 11.39454,
              "country": "Austria",
              "country_code": "AT",
              "admin1": "Tyrol",
              "timezone": "Europe/Vienna"
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CityResponseModelDTO.self, from: json)
        XCTAssertEqual(response.results?.count, 1)
        XCTAssertEqual(response.results?.first?.name, "Innsbruck")
    }

    func test_geocodingResponseDecoding_toleratesMissingResults() throws {
        let json = "{}".data(using: .utf8)!
        let response = try JSONDecoder().decode(CityResponseModelDTO.self, from: json)
        XCTAssertNil(response.results)
    }

    func test_forecastResponseDTO_mapsToDailyForecastArray() throws {
        let json = """
        {
          "timezone": "Europe/Vienna",
          "daily": {
            "time": ["2026-07-03", "2026-07-04"],
            "weathercode": [0, 61],
            "temperature_2m_max": [22.5, 18.0],
            "temperature_2m_min": [12.0, 11.0],
            "precipitation_sum": [0.0, 4.2],
            "precipitation_probability_max": [5, 80],
            "snowfall_sum": [0.0, 0.0],
            "windspeed_10m_max": [12.0, 20.5],
            "windgusts_10m_max": [20.0, 35.0],
            "cloudcover_mean": [10.0, 70.0]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DailyWeatherForecastResponseModelDTO.self, from: json)
        let days = try response.toDomain()

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].weatherCode, .clearSky)
        XCTAssertEqual(days[1].weatherCode, .rainSlight)
        XCTAssertEqual(days[1].precipitationProbabilityMaxPercent, 80)
        XCTAssertEqual(days[0].temperatureMaxC, 22.5)
    }

    func test_forecastResponseDTO_toleratesMissingOptionalArrays() throws {
        let json = """
        {
          "daily": {
            "time": ["2026-07-03"],
            "weathercode": [0],
            "temperature_2m_max": [22.5],
            "temperature_2m_min": [12.0],
            "precipitation_sum": [0.0],
            "snowfall_sum": [0.0],
            "windspeed_10m_max": [12.0],
            "windgusts_10m_max": [20.0]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DailyWeatherForecastResponseModelDTO.self, from: json)
        let days = try response.toDomain()

        XCTAssertEqual(days.count, 1)
        XCTAssertEqual(days[0].precipitationProbabilityMaxPercent, 0)
        XCTAssertNil(days[0].cloudCoverMeanPercent)
    }

    func test_forecastResponseDTO_throwsOnRaggedRequiredArrays() throws {
        let json = """
        {
          "daily": {
            "time": ["2026-07-03", "2026-07-04"],
            "weathercode": [0],
            "temperature_2m_max": [22.5, 18.0],
            "temperature_2m_min": [12.0, 11.0],
            "precipitation_sum": [0.0, 4.2],
            "snowfall_sum": [0.0, 0.0],
            "windspeed_10m_max": [12.0, 20.5],
            "windgusts_10m_max": [20.0, 35.0]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(DailyWeatherForecastResponseModelDTO.self, from: json)
        XCTAssertThrowsError(try response.toDomain())
    }

    func test_unknownWeatherCode_mapsToUnknownCase() {
        let code = WeatherCode(rawFromAPI: 123)
        XCTAssertEqual(code, .unknown)
    }
}
