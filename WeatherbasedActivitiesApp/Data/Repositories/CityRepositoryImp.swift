//
//  CityRepositoryImp.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

struct CityRepositoryImp: CityRepository {
    let apiClient: APIClient
    func searchCityByName(cityName: String) async throws -> [CityModel] {
        let response: CityResponseModelDTO  =  try await apiClient.get(.citySearch(name: cityName))
        return (response.results ?? []).map {$0.toDomain() }
    }
}
