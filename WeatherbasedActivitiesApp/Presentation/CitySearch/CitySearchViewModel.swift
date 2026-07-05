//
//  File.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//
import Foundation
import Combine


@MainActor
final class CitySearchViewModel: ObservableObject {

    /// Explicit, exhaustive state for the search screen. Modeling this as an
    /// enum (rather than a handful of independent Bools) makes illegal
    /// states like "loading and error at once" unrepresentable, and makes
    /// the view's `switch` exhaustive at compile time.
    enum State: Equatable {
        case idle
        case searching
        case loaded([CityModel])
        case empty(query: String)
        case error(message: String)
    }

    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }
    @Published private(set) var state: State = .idle

    private let searchCityUseCase: SearchCityUseCase
    private let debounceNanoseconds: UInt64
    private var searchTask: Task<Void, Never>?

    init(
        searchCityUseCase: SearchCityUseCase,
        debounceMilliseconds: UInt64 = 350
    ) {
        self.searchCityUseCase = searchCityUseCase
        self.debounceNanoseconds = debounceMilliseconds * 1_000_000
    }

    /// Debounces user keystrokes so we don't fire a network request per
    /// character. Cancels any in-flight search when a newer one is queued.
    private func scheduleSearch() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: self.debounceNanoseconds)
            } catch {
                return // cancelled by a newer keystroke
            }
            guard !Task.isCancelled else { return }
            await self.performSearch(query: trimmed)
        }
    }

    /// Exposed directly for tests and for a "search" button / return-key
    /// affordance that wants to bypass the debounce.
    func performSearch(query: String) async {
        state = .searching
        do {
            let cities = try await searchCityUseCase.execute(cityName: query)
            guard !Task.isCancelled else { return }
            state = cities.isEmpty ? .empty(query: query) : .loaded(cities)
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(message: (error as? AppError)?.errorDescription ?? "Something went wrong. Please try again.")
        }
    }
}
