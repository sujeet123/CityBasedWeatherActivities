//
//  ActivityListView.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import SwiftUI

struct ActivityListView: View {
    @StateObject private var viewModel: ActivityListViewModel

    init(viewModel: @autoclosure @escaping () -> ActivityListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .navigationTitle(viewModel.cityModel.name)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.state == .idle {
                    viewModel.load()
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: "Fetching 7-day forecast...")
        case .loaded(let recommendations):
            List {
                Section {
                    ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, recommendation in
                        ActivityRowView(rank: index + 1, recommendation: recommendation)
                    }
                } header: {
                    Text("Ranked for the next 7 days")
                } footer: {
                    Text("Tap an activity to see its day-by-day breakdown.")
                }
            }
            .listStyle(.insetGrouped)
        case .error(let message):
            ErrorView(message: message, onRetry: viewModel.retry)
        }
    }
}

#Preview {
    NavigationStack {
        ActivityListView(
            viewModel: ActivityListViewModel(
                cityModel: CityModel(id: 1, name: "Innsbruck", country: "Austria", countryCode: "AT", admin1: "Tyrol", latitude: 47.26, longitude: 11.39, timezone: "Europe/Vienna"),
                rankActivitiesUseCase: PreviewRankActivitiesUseCase() as RankActivitiesUseCase
            )
        )
    }
}

private struct PreviewRankActivitiesUseCase: RankActivitiesUseCase {
    func execute(cityModel: CityModel) async throws -> [ActivityRecommendation] {
        let day = DailyActivityScore(date: .now, score: 82, rationale: "8.0cm fresh snow, high of -3°C")
        return [
            ActivityRecommendation(activity: .skiing, overallScore: 78, bestDay: day, dailyScores: [day]),
            ActivityRecommendation(activity: .outdoorSightseeing, overallScore: 60, bestDay: day, dailyScores: [day]),
            ActivityRecommendation(activity: .indoorSightseeing, overallScore: 55, bestDay: day, dailyScores: [day]),
            ActivityRecommendation(activity: .surfing, overallScore: 20, bestDay: day, dailyScores: [day])
        ]
    }
}
