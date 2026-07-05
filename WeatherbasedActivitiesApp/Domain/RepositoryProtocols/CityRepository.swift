//
//  CityRepository.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

protocol CityRepository {
    func searchCityByName(cityName: String) async throws -> [CityModel]
}
