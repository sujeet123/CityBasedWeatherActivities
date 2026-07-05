//
//  Activity.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation


/// The fixed set of activities the app ranks for a given city.
enum Activity: String, CaseIterable, Identifiable, Equatable {
    case skiing
    case surfing
    case outdoorSightseeing
    case indoorSightseeing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .skiing: return "Skiing"
        case .surfing: return "Surfing"
        case .outdoorSightseeing: return "Outdoor Sightseeing"
        case .indoorSightseeing: return "Indoor Sightseeing"
        }
    }

    var iconSystemName: String {
        switch self {
        case .skiing: return "figure.skiing.downhill"
        case .surfing: return "figure.surfing"
        case .outdoorSightseeing: return "binoculars.fill"
        case .indoorSightseeing: return "building.columns.fill"
        }
    }
}
