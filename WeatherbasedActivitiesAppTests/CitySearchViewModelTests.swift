//
//  File.swift
//  WeatherbasedActivitiesAppTests
//
//  Created by Sujeet kumar on 05/07/26.
//

import XCTest
@testable import WeatherbasedActivitiesApp

@MainActor
final class CitySearchViewModelTests: XCTestCase {

    func test_initialState_isIdle() {
        let useCase = MockSearchCityUseCase()
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase)
        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_performSearch_withResults_setsLoadedState() async {
        let useCase = MockSearchCityUseCase()
        useCase.citiesToReturn = [Fixtures.city()]
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase)

        await viewModel.performSearch(query: "Innsbruck")

        XCTAssertEqual(viewModel.state, .loaded([Fixtures.city()]))
    }

    func test_performSearch_withNoResults_setsEmptyState() async {
        let useCase = MockSearchCityUseCase()
        useCase.citiesToReturn = []
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase)

        await viewModel.performSearch(query: "Nowhereville")

        XCTAssertEqual(viewModel.state, .empty(query: "Nowhereville"))
    }

    func test_performSearch_withError_setsErrorStateWithMessage() async {
        let useCase = MockSearchCityUseCase()
        useCase.errorToThrow = AppError.noConnection
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase)

        await viewModel.performSearch(query: "Innsbruck")

        guard case .error(let message) = viewModel.state else {
            return XCTFail("Expected .error state, got \(viewModel.state)")
        }
        XCTAssertEqual(message, AppError.noConnection.errorDescription)
    }

    func test_settingEmptyQuery_resetsToIdle() {
        let useCase = MockSearchCityUseCase()
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase)

        viewModel.query = "  "

        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_debouncedSearch_onlyFiresOnceForRapidTyping() async throws {
        let useCase = MockSearchCityUseCase()
        useCase.citiesToReturn = [Fixtures.city()]
        let viewModel = CitySearchViewModel(searchCityUseCase: useCase, debounceMilliseconds: 50)

        viewModel.query = "I"
        viewModel.query = "In"
        viewModel.query = "Inn"
        viewModel.query = "Innsbruck"

        // Wait comfortably past the debounce window for the settle + one search.
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(useCase.receivedQueries, ["Innsbruck"])
        XCTAssertEqual(viewModel.state, .loaded([Fixtures.city()]))
    }
}
