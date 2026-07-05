//
//  ActivityListViewModel.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation
import Combine

@MainActor
final class ActivityListViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded([ActivityRecommendation])
        case error(message: String)
    }

    let cityModel: CityModel
    @Published private(set) var state: State = .idle

    private let rankActivitiesUseCase: RankActivitiesUseCase
    private var loadTask: Task<Void, Never>?

    init(cityModel: CityModel, rankActivitiesUseCase: RankActivitiesUseCase) {
        self.cityModel = cityModel
        self.rankActivitiesUseCase = rankActivitiesUseCase
    }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        state = .loading
        do {
            let recommendations = try await rankActivitiesUseCase.execute(cityModel: cityModel)
            guard !Task.isCancelled else { return }
            state = .loaded(recommendations)
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(message: (error as? AppError)?.errorDescription ?? "Something went wrong. Please try again.")
        }
    }

    func retry() {
        load()
    }
}
