//
//  ActivityRecomendation.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import Foundation


/// The suitability score computed for one activity on one specific day.
struct DailyActivityScore: Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    /// 0 unsuitable ... 100  most ideal suitability score.
    let score: Double
    /// explanation of why the score landed where it did.
    let rationale: String
}

/// The fully ranked view of a single activity across the whole forecast window.
struct ActivityRecommendation: Identifiable, Equatable {
    var id: Activity { activity }

    let activity: Activity
    /// currently the average of
    /// daily scores. Used to sort the activity list.
    let overallScore: Double
    /// The single best day for this activity, if any days were scored.
    let bestDay: DailyActivityScore?
    /// Per-day breakdown, in chronological order, for the detail UI.
    let dailyScores: [DailyActivityScore]
}
