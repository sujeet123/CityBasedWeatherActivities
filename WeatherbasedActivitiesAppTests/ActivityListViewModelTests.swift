//
//  ActivityListViewModelTests.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import XCTest
@testable import WeatherbasedActivitiesApp

@MainActor
final class ActivityListViewModelTests: XCTestCase {

    func test_initialState_isIdle() {
        let useCase = MockRankActivitiesUseCase()
        let viewModel = ActivityListViewModel(cityModel: Fixtures.city(), rankActivitiesUseCase: useCase)
        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_load_withResults_setsLoadedState() async {
        let useCase = MockRankActivitiesUseCase()
        let recommendations = [
            ActivityRecommendation(activity: .skiing, overallScore: 90, bestDay: nil, dailyScores: [])
        ]
        useCase.recommendationsToReturn = recommendations
        let viewModel = ActivityListViewModel(cityModel: Fixtures.city(), rankActivitiesUseCase: useCase)

        viewModel.load()
        await waitForNonLoadingState(of: viewModel)

        XCTAssertEqual(viewModel.state, .loaded(recommendations))
        XCTAssertEqual(useCase.receivedCities, [Fixtures.city()])
    }

    func test_load_withError_setsErrorState() async {
        let useCase = MockRankActivitiesUseCase()
        useCase.errorToThrow = AppError.noForecastData
        let viewModel = ActivityListViewModel(cityModel: Fixtures.city(), rankActivitiesUseCase: useCase)

        viewModel.load()
        await waitForNonLoadingState(of: viewModel)

        guard case .error(let message) = viewModel.state else {
            return XCTFail("Expected .error state, got \(viewModel.state)")
        }
        XCTAssertEqual(message, AppError.noForecastData.errorDescription)
    }

    func test_retry_afterError_callsUseCaseAgain() async {
        let useCase = MockRankActivitiesUseCase()
        useCase.errorToThrow = AppError.timedOut
        let viewModel = ActivityListViewModel(cityModel: Fixtures.city(), rankActivitiesUseCase: useCase)

        viewModel.load()
        await waitForNonLoadingState(of: viewModel)
        XCTAssertEqual(useCase.receivedCities.count, 1)

        viewModel.retry()
        await waitForNonLoadingState(of: viewModel)
        XCTAssertEqual(useCase.receivedCities.count, 2)
    }

    /// Small polling helper: the ViewModel flips to `.loading` synchronously
    /// then completes asynchronously, so tests await the terminal state
    /// rather than sleeping a fixed duration.
    private func waitForNonLoadingState(
        of viewModel: ActivityListViewModel,
        timeout: TimeInterval = 1.0
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while viewModel.state == .loading || viewModel.state == .idle {
            if Date() > deadline {
                XCTFail("Timed out waiting for a terminal state")
                return
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
