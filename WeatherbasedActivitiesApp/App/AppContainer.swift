//
//  AppContainer.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 05/07/26.
//

import Foundation

@MainActor
class AppContainer {
    static let shared = AppContainer()

    let searchCityUseCase: SearchCityUseCase
    let makeRankActivitiesUseCase: () -> RankActivitiesUseCase
    
    init() {
        let apiClient: APIClient = URLSessionAPIClient()
        let cityRepository: CityRepository = CityRepositoryImp(apiClient: apiClient)
        let dailyWeatherForcastRepository: DailyWeatherForecastRepository = DailyWeatherDetailsRepositoryImp(apiClient: apiClient)
        let activityRankingSystem: ActivityRankingSystem = ActivityRankingSystemImpl()
        
        self.searchCityUseCase = SearchCityUseCaseImpl(cityRepository: cityRepository)
        self.makeRankActivitiesUseCase = {
            RankActivitiesUseCaseImpl(
                dailyWeatherforcastReposittory: dailyWeatherForcastRepository,
                activityRecomendationSystem: activityRankingSystem)
        }
    }
    
    func makeCitySearchViewModel() -> CitySearchViewModel {
        CitySearchViewModel(searchCityUseCase: searchCityUseCase)
    }

    func makeActivityListViewModel(for city: CityModel) -> ActivityListViewModel {
        ActivityListViewModel(cityModel: city, rankActivitiesUseCase: makeRankActivitiesUseCase())
    }

}
