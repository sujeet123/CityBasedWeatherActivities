//
//  CityModel.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

struct CityModel : Identifiable, Equatable, Hashable {
    let id: Int64
    let name: String
    let country: String
    let countryCode: String?
    let admin1: String?
    let latitude: Double
    let longitude: Double
    let timezone: String?
    
    /// Human Readable label, e.g. "Berlin, Germany".
    var displayName: String {
        var parts = [name]
        parts.append(country)
        return parts.joined(separator: ", ")
    }
}
