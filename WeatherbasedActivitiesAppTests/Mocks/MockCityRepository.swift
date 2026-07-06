//
//  MockCityRepository.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation
@testable import WeatherbasedActivitiesApp

/// Configurable test double. Records the last query it was called with so
/// tests can assert on call behavior, and can be told to return a fixed
/// result or throw a fixed error.
final class MockCityRepository: CityRepository {
    var citiesToReturn: [CityModel] = []
    var errorToThrow: Error?
    private(set) var lastQuery: String?
    private(set) var callCount = 0
    
    func searchCityByName(cityName: String) async throws -> [CityModel] {
        lastQuery = cityName
        callCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
        return citiesToReturn
    }
}

