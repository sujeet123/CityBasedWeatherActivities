//
//  CityResponseModelDTO.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation


struct CityResponseModelDTO: Codable {
    let results: [CityResultModelDTO]?
}

struct CityResultModelDTO: Codable {
    let id: Int64
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?
    let admin1: String?
    let timezone: String?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, country
        case countryCode = "country_code"
        case admin1
        case timezone
    }
}

extension CityResultModelDTO {
    func toDomain() -> CityModel {
        CityModel(
            id: id,
            name: name,
            country: country ?? "",
            countryCode: countryCode,
            admin1: admin1,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
    }
}
