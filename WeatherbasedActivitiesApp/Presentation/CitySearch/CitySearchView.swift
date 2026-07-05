//
//  CitySearchView.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import SwiftUI

struct CitySearchView: View {
    @StateObject private var viewModel: CitySearchViewModel

    init(viewModel: @autoclosure @escaping () -> CitySearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Activity Forecast")
                .searchable(text: $viewModel.query, prompt: "Search for a city")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableCompat(
                title: "Search for a city",
                message: "Find the best days for skiing, surfing, and sightseeing over the next week.",
                systemImage: "magnifyingglass"
            )
        case .searching:
            LoadingView(message: "Searching...")
        case .loaded(let cities):
            List(cities) { city in
                NavigationLink(value: city) {
                    VStack(alignment: .leading) {
                        Text(city.name).font(.headline)
                        Text(city.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: CityModel.self) { cityModel in
                ActivityListView(viewModel: AppContainer.shared.makeActivityListViewModel(for: cityModel))
            }
        case .empty(let query):
            ContentUnavailableCompat(
                title: "No results",
                message: "No cities found matching \"\(query)\".",
                systemImage: "magnifyingglass"
            )
        case .error(let message):
            ErrorView(message: message) {
                Task { await viewModel.performSearch(query: viewModel.query) }
            }
        }
    }
}

/// A minimal `ContentUnavailableView` stand-in, kept custom so the target
/// can support iOS versions prior to 17 without losing this UI.
private struct ContentUnavailableCompat: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CitySearchView(viewModel: CitySearchViewModel(searchCityUseCase: PreviewSearchCityUseCase() as SearchCityUseCase))
}

private struct PreviewSearchCityUseCase: SearchCityUseCase {
    func execute(cityName: String) async throws -> [CityModel] {
        [CityModel(id: 1, name: "Innsbruck", country: "Austria", countryCode: "AT", admin1: "Tyrol", latitude: 47.26, longitude: 11.39, timezone: "Europe/Vienna")]
    }
}
