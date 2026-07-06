# City and Weather based Activities

A native iOS app that lets you search for a city and see a ranked list of
activities — **Skiing, Surfing, Outdoor Sightseeing, Indoor Sightseeing** —
suited to that location over the next 7 days, using the
[Open-Meteo](https://open-meteo.com) Geocoding and Forecast APIs.

## a. Overview

Search a city → pick it from geocoded results → see the four activities
ranked for the week ahead, each with a best day and a short reason for its
score. Two Open-Meteo endpoints, no other data source, no API key required.

## b. Platform & tooling

| | |
|---|---|
| Platform | iOS, native |
| UI | SwiftUI, `NavigationStack` / `.searchable` |
| Language | Swift 5.9+ |
| Min target | iOS 26.2 |
| Concurrency | async/await (no Combine) |
| Dependencies | none — no third-party packages |
| Testing | XCTest |

Why SwiftUI + Async/Await?
I chose SwiftUI combined with native async/await for this project because it perfectly aligns with modern reactive programming principles. This combination eliminates extensive boilerplate code and natively integrates with Swift 6's strict concurrency framework to ensure a responsive, thread-safe user experience.

## c. Architecture

Clean Architecture-flavored MVVM, four layers, strict dependency direction:

```
Presentation (SwiftUI Views + ViewModels)
      │  depends on
      ▼
Domain (Models, Protocols, Use Cases, Ranking Engine)
      ▲  implements
      │
Data (DTOs, Networking, Repositories)
```

- **Domain** — pure Swift, `Foundation`-only, no networking/UI imports.
  Defines the protocols (`GeocodingServiceProtocol`, `WeatherServiceProtocol`)
  that Data implements, the use cases (`SearchCityUseCase`,
  `RankActivitiesUseCase`) that Presentation calls, and
  `ActivityRankingEngine` — a synchronous, side-effect-free scorer with no
  network dependency at all.
- **Data** — `Endpoint` (URL building), `APIClientProtocol` /
  `URLSessionAPIClient`, DTOs matching the wire format, and repositories
  that map DTOs into domain models. A change in Open-Meteo's JSON shape
  only touches this layer.
- **Presentation** — SwiftUI views + `@MainActor` ViewModels. Each screen
  exposes one `@Published` **state enum**
  (`idle / loading / loaded / empty / error`) instead of separate booleans,
  so "loading and error at once" can't type-check.
- **App** — `AppContainer`, the single composition root that wires the real
  `URLSession → APIClient → repositories → use cases` graph and injects it
  through initializers. Everything downstream depends on protocols, never
  concrete types — which is what makes every layer mockable in tests.

**Data flow:**

```
CitySearchView ⇄ CitySearchViewModel → SearchCityUseCase → CityRepository → CityRepositoryImpl → Open-Meteo Geocoding API

(tap a city)

ActivityListView ⇄ ActivityListViewModel → RankActivitiesUseCase ─┬→ DailyWeatherDetailsRepository → DailyWeatherDetailsRepositoryImpl → Open-Meteo Forecast API
                                                                    └→ ActivityRankingSystem (pure scoring)
```

## d. Build & run

No `.xcodeproj` is committed — project files are binary, don't diff
cleanly, and there are no external dependencies to justify one. To run:

1. Xcode → **File → New → Project → iOS → App**, Product Name
   `WeatherActivities`, Interface **SwiftUI**.
2. Delete the generated `ContentView.swift` / default
   `WeatherActivitiesApp.swift`.
3. Drag in `WeatherActivities/` (app target) and `WeatherActivitiesTests/`
   (test target) — "Copy items if needed" checked.
4. Point the target's Info.plist setting at `Resources/Info.plist`.
5. Select an iOS 17+ simulator, **⌘R**.

No API keys or config needed. Requires an internet connection at runtime —
there's no bundled/offline fixture data.

## e. Testing

Run with **⌘U** in Xcode, or:
```
xcodebuild test -scheme WeatherActivities -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Result on my machine:** ` 47/47 tests passing`

**Strategy** — every layer tested against protocol mocks, nothing touches
the real network:

- `ActivityRankingSsytemTests` — the core logic. Per-activity scoring on
  hand-built fixtures (e.g. skiing >80 on cold/snowy/calm, <20 on
  hot/dry), cross-activity sort order, aggregation (`overallScore` =
  average of daily scores, `bestDay` = max), and empty-forecast edge case.
- `CitySearchViewModelTests` / `ActivityListViewModelTests` — state
  transitions, debounce (rapid typing → exactly one search call), retry,
  against mock use cases.
- `UseCaseTests` — query trimming/short-circuiting, correct forecast-day
  count requested, error propagation.
- `RepositoryTests` / `MapperTests` — DTO→domain mapping against a mock
  API client and realistic Open-Meteo JSON fixtures, including tolerating
  optional fields being absent and rejecting ragged arrays.

**Not covered:** SwiftUI snapshot tests, and a live integration test
against the real API (kept out so the suite stays fast and
network-independent).

## f. API usage notes

- **Geocoding:** `GET geocoding-api.open-meteo.com/v1/search?name={query}&count=10&language=en&format=json`.
  A 2-character minimum gates the call so single keystrokes don't fire
  requests.
- **Forecast:** `GET api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&daily={fields}&forecast_days=7&timezone={tz|auto}`,
  requesting `weathercode`, `temperature_2m_max/min`, `precipitation_sum`,
  `precipitation_probability_max`, `snowfall_sum`, `windspeed_10m_max`,
  `windgusts_10m_max`, `cloudcover_mean`. `timezone` uses the city's own
  timezone from the geocoding result, so daily buckets align to local
  calendar days.

Units are Open-Meteo's metric defaults (°C, km/h, cm, mm) — no unit toggle.
`URLSessionAPIClient` maps `URLError`/non-2xx responses into a single
`AppError` type before Domain ever sees them. No retry/backoff, no caching
— one request per user action.

## g. Activity recommendation logic

Each activity gets a 0–100 score per day, averaged across 7 days for the
overall ranking, with the best single day and a short rationale kept
alongside for the UI.

- **Skiing** — rewards fresh snowfall and cold temperatures, penalized by
  dangerously high wind (lift closures/exposure risk).
- **Surfing** — Open-Meteo's Forecast API has no wave/swell data (that's
  their separate Marine API, out of scope here). I used **max wind speed
  as a proxy**: near-zero → flat, 15–35 km/h → favorable, very high →
  dangerous/choppy, with a hard penalty for thunderstorms regardless of
  wind. This is the biggest modeling compromise in the app, and I'd rather
  flag it than present it as real surf forecasting.
- **Outdoor sightseeing** — scored *multiplicatively*
  (temperature comfort × precipitation chance × wind comfort × sky
  condition), not additively — a 95% rain chance should tank the score
  even with a pleasant temperature, and an additive model let good
  temperature paper over bad precipitation in my own test for this case.
- **Indoor sightseeing** — weather-independent by design: starts from a
  comfortable baseline and rises as outdoor conditions worsen (rain,
  temperature extremes, high wind) — it's the fallback that shines when
  nothing else does.

Coefficients live as commented constants inside `ActivityRankingEngine`,
one file, so they're easy to challenge or retune without touching anything
else — I consider them the most negotiable part of this submission.

## h. Assumptions

- The four listed activities are fixed — no custom/user-added activities.
- "Next 7 days" = the API's `forecast_days=7`, anchored to the city's local
  timezone, not the device's.
- Search is incremental/debounced-as-you-type, not a single explicit
  submit only.
- Open-Meteo's free, unauthenticated tier is acceptable for this exercise.
- Metric units without a toggle are acceptable.
- No location-permission / "use current location" flow was requested, so
  city entry is search-only.

## i. Trade-offs & omissions

- Surf scoring is a wind-speed proxy, not real wave data (see §g).
- No caching or offline mode — every city tap refetches; the
  `DailyWeatherForecastRepository` boundary is where a cache decorator would slot
  in later.

  
## j. Cross-platform notes

Not asked for here, but the layering was drawn with it in mind: Domain is
already `Foundation`-only Swift with no UIKit/SwiftUI imports, so a second
platform would ideally share it via **Kotlin Multiplatform** (port
`ActivityRankingSystem`, models, and use-case interfaces into
`commonMain`) rather than hand-porting the scoring logic twice and risking
drift. If KMP weren't an option, the same layering maps near 1:1 onto
Jetpack Compose + `ViewModel` + `StateFlow<State>` — the porting effort
would concentrate almost entirely in Presentation, since Domain and Data
are conceptually identical.

## k. AI usage disclosure
Activity Recommendation & Rating Logic: AI was utilized to analyze the complex weather conditions and generate initial technical specifications for the activity matching algorithm. Leveraging AI to translate these diverse requirements saved significant design time, with all AI-generated logic manually reviewed, verified, and refined before being integrated into the app.

Test Suite Generation: Automated testing scenarios and unit test cases were generated using AI to accelerate development, ensure comprehensive code coverage, and eliminate repetitive boilerplate test writing.
