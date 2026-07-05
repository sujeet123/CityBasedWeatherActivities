//
//  File.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation

struct DailyWeatherForecastResponseModelDTO: Codable {
    let daily: DailyWeatherDetailsDTO
    let timezone: String?
}

struct DailyWeatherDetailsDTO: Codable {
    let time: [String]
    let weathercode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationSum: [Double]
    let precipitationProbabilityMax: [Double]?
    let snowfallSum: [Double]
    let windspeed10mMax: [Double]
    let windgusts10mMax: [Double]
    let cloudcoverMean: [Double]?
    
    enum CodingKeys: String, CodingKey {
        case time
        case weathercode
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case snowfallSum = "snowfall_sum"
        case windspeed10mMax = "windspeed_10m_max"
        case windgusts10mMax = "windgusts_10m_max"
        case cloudcoverMean = "cloudcover_mean"
    }
}

enum ForecastMappingError: Error {
    case malformedDate(String)
}

extension DailyWeatherForecastResponseModelDTO {
    func toDomain() throws -> [DailyWeatherForecastModel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        formatter.timeZone = TimeZone(identifier: getTimezone())
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let count = daily.time.count
        guard daily.weathercode.count == count,
              daily.temperature2mMax.count == count,
              daily.temperature2mMin.count == count,
              daily.precipitationSum.count == count,
              daily.snowfallSum.count == count,
              daily.windspeed10mMax.count == count,
              daily.windgusts10mMax.count == count else {
            throw AppError.decodingFailed
        }
        
        var results: [DailyWeatherForecastModel] = []
        results.reserveCapacity(count)
        
        for index in 0..<count {
            guard let date = formatter.date(from: daily.time[index]) else {
                throw ForecastMappingError.malformedDate(daily.time[index])
            }
            let precipitationProbability = daily.precipitationProbabilityMax.flatMap {
                $0.indices.contains(index) ? $0[index] : nil
            } ?? 0
            let cloudCover = daily.cloudcoverMean.flatMap {
                $0.indices.contains(index) ? $0[index] : nil
            }
            
            results.append(
                DailyWeatherForecastModel(
                    date: date,
                    weatherCode: WeatherCode(rawFromAPI: daily.weathercode[index]),
                    temperatureMaxC: daily.temperature2mMax[index],
                    temperatureMinC: daily.temperature2mMin[index],
                    precipitationSumMM: daily.precipitationSum[index],
                    precipitationProbabilityMaxPercent: precipitationProbability,
                    snowfallSumCM: daily.snowfallSum[index],
                    windSpeedMaxKMH: daily.windspeed10mMax[index],
                    windGustsMaxKMH: daily.windgusts10mMax[index],
                    cloudCoverMeanPercent: cloudCover
                )
            )
        }
        
        return results
    }
    
    private func getTimezone() -> String {
        timezone ?? "IST"
    }
}


