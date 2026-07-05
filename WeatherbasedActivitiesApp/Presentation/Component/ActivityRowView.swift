//
//  ActivityRowView.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import SwiftUI

struct ActivityRowView: View {
    let rank: Int
    let recommendation: ActivityRecommendation

    @State private var isExpanded = false

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                header
            }
            .buttonStyle(.plain)

            if isExpanded {
                dailyBreakdown
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Image(systemName: recommendation.activity.iconSystemName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.activity.displayName)
                    .font(.headline)
                if let bestDay = recommendation.bestDay {
                    Text("Best day: \(Self.dayFormatter.string(from: bestDay.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            ScoreBadge(score: recommendation.overallScore)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recommendation.activity.displayName), rank \(rank), score \(Int(recommendation.overallScore)) out of 100")
    }

    private var dailyBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recommendation.dailyScores) { day in
                HStack(alignment: .top) {
                    Text(Self.dayFormatter.string(from: day.date))
                        .font(.caption.monospacedDigit())
                        .frame(width: 56, alignment: .leading)
                        .foregroundStyle(.secondary)
                    ScoreBadge(score: day.score, compact: true)
                    Text(day.rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.leading, 40)
        .padding(.top, 8)
    }
}

private struct ScoreBadge: View {
    let score: Double
    var compact: Bool = false

    private var color: Color {
        switch score {
        case 70...: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }

    var body: some View {
        Text("\(Int(score.rounded()))")
            .font(compact ? .caption2.bold() : .subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 2 : 4)
            .background(color, in: Capsule())
    }
}

#Preview {
    let sampleDay = DailyActivityScore(date: .now, score: 82, rationale: "8.0cm fresh snow, high of -3°C")
    let sample = ActivityRecommendation(
        activity: .skiing,
        overallScore: 78,
        bestDay: sampleDay,
        dailyScores: [sampleDay]
    )
    return List {
        ActivityRowView(rank: 1, recommendation: sample)
    }
}
