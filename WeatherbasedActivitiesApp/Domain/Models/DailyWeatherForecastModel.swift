//
//  DailyWeatherForecastModel.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation


/// A single day's weather forecast, normalized into domain units
struct DailyWeatherForecastModel: Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    let weatherCode: WeatherCode
    let temperatureMaxC: Double
    let temperatureMinC: Double
    let precipitationSumMM: Double
    /// 0...100. Some providers omit this; default to 0 when absent.
    let precipitationProbabilityMaxPercent: Double
    let snowfallSumCM: Double
    let windSpeedMaxKMH: Double
    let windGustsMaxKMH: Double
    /// 0...100 mean cloud cover, optional because not all providers expose it.
    let cloudCoverMeanPercent: Double?
}

/// WMO weather interpretation codes as used by Open-Meteo.
/// https://open-meteo.com/en/docs (see "WMO Weather interpretation codes")
enum WeatherCode: Int, Equatable {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case rimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowSlight = 71
    case snowModerate = 73
    case snowHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstorm = 95
    case thunderstormHailSlight = 96
    case thunderstormHailHeavy = 99
    case unknown = -1

    init(rawFromAPI: Int) {
        self = WeatherCode(rawValue: rawFromAPI) ?? .unknown
    }

    var isPrecipitating: Bool {
        switch self {
        case .drizzleLight, .drizzleModerate, .drizzleDense,
             .freezingDrizzleLight, .freezingDrizzleDense,
             .rainSlight, .rainModerate, .rainHeavy,
             .freezingRainLight, .freezingRainHeavy,
             .snowSlight, .snowModerate, .snowHeavy, .snowGrains,
             .rainShowersSlight, .rainShowersModerate, .rainShowersViolent,
             .snowShowersSlight, .snowShowersHeavy,
             .thunderstorm, .thunderstormHailSlight, .thunderstormHailHeavy:
            return true
        default:
            return false
        }
    }

    var isThunderstorm: Bool {
        switch self {
        case .thunderstorm, .thunderstormHailSlight, .thunderstormHailHeavy:
            return true
        default:
            return false
        }
    }

    var isSnowing: Bool {
        switch self {
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains,
             .snowShowersSlight, .snowShowersHeavy:
            return true
        default:
            return false
        }
    }

    var isClearOrMostlyClear: Bool {
        switch self {
        case .clearSky, .mainlyClear, .partlyCloudy:
            return true
        default:
            return false
        }
    }
}
