//
//  WeatherbasedActivitiesAppApp.swift
//  WeatherbasedActivitiesApp
//
//  Created by Sujeet kumar on 04/07/26.
//

import SwiftUI
import SwiftData

@main
struct WeatherbasedActivitiesAppApp: App {
    var body: some Scene {
        WindowGroup {
            CitySearchView(viewModel: AppContainer.shared.makeCitySearchViewModel())
        }
    }
}

