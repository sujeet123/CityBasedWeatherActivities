//
//  ActivityRankingSystem.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation



/// Pure, side-effect-free scoring logic. Kept separate from networking and
/// presentation so it can be exhaustively unit tested with hand-built
/// `DailyForecast` fixtures.
protocol ActivityRankingSystem {
    func rank(forecast: [DailyWeatherForecastModel]) -> [ActivityRecommendation]
}

struct ActivityRankingSystemImpl: ActivityRankingSystem {

    func rank(forecast: [DailyWeatherForecastModel]) -> [ActivityRecommendation] {
        let recommendations = Activity.allCases.map { activity -> ActivityRecommendation in
            let dailyScores = forecast.map { day in
                score(for: activity, on: day)
            }
            let overall = average(dailyScores.map { $0.score })
            let best = dailyScores.max(by: { $0.score < $1.score })
            return ActivityRecommendation(
                activity: activity,
                overallScore: overall,
                bestDay: best,
                dailyScores: dailyScores
            )
        }

        // Highest overall suitability first. Ties broken alphabetically for
        // deterministic, testable ordering.
        return recommendations.sorted { lhs, rhs in
            if lhs.overallScore != rhs.overallScore {
                return lhs.overallScore > rhs.overallScore
            }
            return lhs.activity.displayName < rhs.activity.displayName
        }
    }

    // MARK: - Per-activity scoring

    private func score(for activity: Activity, on day: DailyWeatherForecastModel) -> DailyActivityScore {
        switch activity {
        case .skiing: return skiingScore(day)
        case .surfing: return surfingScore(day)
        case .outdoorSightseeing: return outdoorSightseeingScore(day)
        case .indoorSightseeing: return indoorSightseeingScore(day)
        }
    }

    /// Skiing wants fresh snowfall and cold-enough temperatures for it to
    /// stick, and is hurt by dangerously high winds (lift closures, exposure).
    private func skiingScore(_ day: DailyWeatherForecastModel) -> DailyActivityScore {
        var reasons: [String] = []

        // Snowfall: 0cm -> 0 pts, >=8cm -> full 60 pts.
        let snowComponent = clamp(day.snowfallSumCM / 8.0) * 60
        if day.snowfallSumCM > 0 {
            reasons.append(String(format: "%.1fcm fresh snow", day.snowfallSumCM))
        } else {
            reasons.append("no fresh snowfall")
        }

        // Cold temperature: <=0C -> full 30 pts, linearly fades to 0 by 8C.
        let coldComponent = clamp((8.0 - day.temperatureMaxC) / 8.0) * 30
        reasons.append(String(format: "high of %.0f°C", day.temperatureMaxC))

        // Wind penalty: dangerous above 50 km/h (lift/exposure risk).
        let windPenalty = clamp((day.windSpeedMaxKMH - 50) / 30) * 20
        if day.windSpeedMaxKMH > 50 {
            reasons.append(String(format: "strong wind %.0f km/h", day.windSpeedMaxKMH))
        }

        let raw = snowComponent + coldComponent + 10 /* base for cold-but-groomed days */ - windPenalty
        let score = clamp(raw / 100.0) * 100
        return DailyActivityScore(date: day.date, score: score, rationale: reasons.joined(separator: ", "))
    }

    /// Surfing uses wind speed as a (imperfect but Forecast-API-only) proxy
    /// for swell/wave energy: some wind is good, too little is flat, too
    /// much is dangerous. Thunderstorms are a hard safety penalty.
    private func surfingScore(_ day: DailyWeatherForecastModel) -> DailyActivityScore {
        var reasons: [String] = []

        // Ideal sustained wind band ~15-35 km/h for rideable waves.
        let wind = day.windSpeedMaxKMH
        let windComponent: Double
        switch wind {
        case ..<10:
            windComponent = (wind / 10) * 40 // flat / weak conditions
            reasons.append("light wind, likely flat")
        case 10..<15:
            windComponent = 40 + ((wind - 10) / 5) * 30
            reasons.append("building swell")
        case 15...35:
            windComponent = 70 + (1 - abs(wind - 25) / 10) * 30
            reasons.append(String(format: "favorable wind %.0f km/h", wind))
        case 35...50:
            windComponent = 70 - ((wind - 35) / 15) * 40
            reasons.append("choppy, strong wind")
        default:
            windComponent = 10
            reasons.append("dangerous wind/surf")
        }

        // Thunderstorms are a hard safety penalty regardless of wind.
        let stormPenalty: Double = day.weatherCode.isThunderstorm ? 60 : 0
        if day.weatherCode.isThunderstorm {
            reasons.append("thunderstorm risk")
        }

        let raw = windComponent - stormPenalty
        let score = clamp(raw / 100.0) * 100
        return DailyActivityScore(date: day.date, score: score, rationale: reasons.joined(separator: ", "))
    }

    /// Outdoor sightseeing wants mild temperatures, low precipitation
    /// chance, calm wind, and clear-ish skies. Modeled multiplicatively
    /// (rather than as a weighted sum) because a single bad dimension --
    /// e.g. a 95% chance of rain -- should tank the day's suitability even
    /// if the temperature happens to be pleasant.
    private func outdoorSightseeingScore(_ day: DailyWeatherForecastModel) -> DailyActivityScore {
        var reasons: [String] = []

        // Comfortable range roughly 12-26C, fading out toward extremes.
        let idealLow = 12.0, idealHigh = 26.0
        let midpoint = (idealLow + idealHigh) / 2
        let halfRange = (idealHigh - idealLow) / 2
        let tempDistance = abs(day.temperatureMaxC - midpoint)
        let tempFactor = clamp(1 - max(0, tempDistance - halfRange) / 15)
        reasons.append(String(format: "high of %.0f°C", day.temperatureMaxC))

        // Precipitation probability directly penalizes, multiplicatively.
        let precipFactor = clamp(1 - day.precipitationProbabilityMaxPercent / 100)
        if day.precipitationProbabilityMaxPercent > 40 {
            reasons.append(String(format: "%.0f%% chance of rain", day.precipitationProbabilityMaxPercent))
        }

        // Wind comfort: fades out above 30 km/h.
        let windFactor = clamp(1 - day.windSpeedMaxKMH / 45)
        if day.windSpeedMaxKMH > 30 {
            reasons.append("breezy")
        }

        // Sky condition: a mild penalty for overcast/precipitating skies,
        // and an extra hit if it's actively precipitating right now.
        var skyFactor = day.weatherCode.isClearOrMostlyClear ? 1.0 : 0.75
        if day.weatherCode.isPrecipitating {
            skyFactor *= 0.6
            reasons.append("precipitation expected")
        }
        if day.weatherCode.isClearOrMostlyClear {
            reasons.append("clear skies")
        }

        let raw = tempFactor * precipFactor * windFactor * skyFactor
        let score = clamp(raw) * 100
        return DailyActivityScore(date: day.date, score: score, rationale: reasons.joined(separator: ", "))
    }

    /// Indoor sightseeing is largely weather-independent (that's the point),
    /// so it starts from a comfortably high baseline and climbs further as
    /// outdoor conditions get worse -- it's the natural fallback plan.
    private func indoorSightseeingScore(_ day: DailyWeatherForecastModel) -> DailyActivityScore {
        var reasons: [String] = ["weather-independent"]
        let baseline = 55.0

        let precipBoost = clamp(day.precipitationProbabilityMaxPercent / 100) * 25
        if day.precipitationProbabilityMaxPercent > 40 {
            reasons.append("good rainy-day option")
        }

        let extremeColdBoost = clamp((0 - day.temperatureMinC) / 15) * 10
        let extremeHeatBoost = clamp((day.temperatureMaxC - 32) / 10) * 10
        if day.temperatureMinC < 0 {
            reasons.append("cold outside")
        }
        if day.temperatureMaxC > 32 {
            reasons.append("hot outside")
        }

        let windBoost = clamp((day.windSpeedMaxKMH - 40) / 30) * 10

        let raw = baseline + precipBoost + extremeColdBoost + extremeHeatBoost + windBoost
        let score = clamp(raw / 100.0) * 100
        return DailyActivityScore(date: day.date, score: score, rationale: reasons.joined(separator: ", "))
    }

    // MARK: - Helpers

    /// Clamps to 0...1.
    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
