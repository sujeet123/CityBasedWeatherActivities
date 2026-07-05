//
//  SearchCityUseCase.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

protocol SearchCityUseCase {
    func execute(cityName: String) async throws -> [CityModel]
}

struct SearchCityUseCaseImpl: SearchCityUseCase {
    let cityRepository: CityRepository
    func execute(cityName: String) async throws -> [CityModel] {
        let trimmed = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        return try await cityRepository.searchCityByName(cityName: cityName)
    }
}


