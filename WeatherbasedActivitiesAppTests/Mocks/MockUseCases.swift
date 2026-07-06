//
//  MockUseCases.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//


import Foundation
@testable import WeatherbasedActivitiesApp

final class MockSearchCityUseCase: SearchCityUseCase {
    var citiesToReturn: [CityModel] = []
    var errorToThrow: Error?
    private(set) var receivedQueries: [String] = []

    func execute(cityName: String) async throws -> [CityModel] {
        receivedQueries.append(cityName)
        if let errorToThrow {
            throw errorToThrow
        }
        return citiesToReturn
    }
}

final class MockRankActivitiesUseCase: RankActivitiesUseCase {
    var recommendationsToReturn: [ActivityRecommendation] = []
    var errorToThrow: Error?
    private(set) var receivedCities: [CityModel] = []

    func execute(cityModel: CityModel) async throws -> [ActivityRecommendation] {
        receivedCities.append(cityModel)
        if let errorToThrow {
            throw errorToThrow
        }
        return recommendationsToReturn
    }
}
