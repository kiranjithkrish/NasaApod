# NASA APOD

An iOS app displaying NASA's Astronomy Picture of the Day using their public API.

## Requirements

- iOS 18.0+
- Xcode 16+
- Swift 6

## Build & Run

1. Open `NasaApod.xcodeproj` in Xcode
2. Select a simulator or device
3. Build and run (⌘R)

No third-party dependencies required.

## Architecture

**Clean Architecture** with MVVM:

```
Features/          UI layer (Views + ViewModels)
    ↓
Domain/            WHAT we need (Models, Protocols)
    ↓
Data/              HOW we get it (Network, Cache, Repository)
```

### Domain vs Data

```
┌─────────────────────────────────────────┐
│  Domain (WHAT)                          │
│  Models, Protocols                      │
│  → No external dependencies             │
├─────────────────────────────────────────┤
│  Data (HOW)                             │
│  Repository, APIService, CacheService   │
│  → Network, disk, external systems      │
└─────────────────────────────────────────┘
```

**Why Repositories folder in both?**
- `Domain/Repositories/` contains the **protocol** (interface) - defines WHAT the app needs
- `Data/Repositories/` contains the **implementation** - defines HOW to get it

This separation means Features depend only on Domain protocols, not Data implementations. Easy to swap implementations (real vs mock for testing).

### Key Components

```
┌──────────────────┬────────────────────────────────────────────┐
│  APIService      │  URLSession wrapper with retry logic       │
├──────────────────┼────────────────────────────────────────────┤
│  CacheService    │  Actor-based cache (memory + disk)         │
├──────────────────┼────────────────────────────────────────────┤
│  APODRepository  │  Coordinates network and cache             │
├──────────────────┼────────────────────────────────────────────┤
│  CircuitBreaker  │  Prevents cascading failures when API down │
└──────────────────┴────────────────────────────────────────────┘
```

## Design Decisions

### State-Driven UI

All state is modeled with enums to prevent impossible states. `LoadingState<T>` for content (idle/loading/loaded/failed), optional enums for sheets and navigation destinations. No boolean flags — each state is mutually exclusive and extensible.

### Only Cache Last Successful APOD

Challenge requires "last service call including image should be cached". We cache only ONE APOD at a time — `saveLastSuccessful()` clears previous before saving. APOD date is used as cache key to link data with its image. Architecture is extensible: remove the clear step to cache all APODs.

### CacheService vs URLSession Cache

URLSession respects HTTP cache headers — if the server says `no-cache`, it won't cache. We need guaranteed offline fallback, so `CacheService` provides explicit control regardless of server headers. NASA's image server also doesn't send `Cache-Control` headers, so `CachedAsyncImage` + `ImageCacheActor` gives us explicit memory + disk caching.

### FetchResult Enum at Repository Level

The repository returns `FetchResult` (`.fresh` or `.cachedFallback`) instead of a raw `APOD`. This lets the UI know whether data came from the network or cache without inferring it from date comparison. The Explore page uses this to show an offline banner and sync the date picker.

### scenePhase Auto-Refresh

APOD does not change intra-day, so pull-to-refresh was misleading. Instead, the Today page monitors `scenePhase` and auto-refreshes only when the day has changed. Uses `Calendar.current.isDateInToday()` — zero-cost check, no timers or polling.

### Circuit Breaker

When the API is down, the circuit breaker stops retrying after N failures and returns cached data instead. Prevents resource waste and provides graceful degradation.

### Actor-based Concurrency

`CacheService`, `ImageCacheActor`, and `CircuitBreaker` use actors for thread-safe state without manual locks. Swift 6 strict concurrency catches data races at compile time.

### Protocol-based DI

Chose protocol-based DI over struct closures (Point-Free style) for better Xcode tooling and familiarity for reviewers. `FileManager.default` used directly in `CacheService` — abstracting it adds complexity and `FileManager` isn't `Sendable`.

## Testing

### Test Style

Tests follow **BDD style** with Given/When/Then comments:

**Why BDD style?**
- Tests document expected behavior
- Clear what's being tested without running the app
- Serves as living documentation

### Test Coverage

- **Core Utilities**: LoadingState, RetryPolicy, CircuitBreaker
- **Domain Models**: APOD validation, MediaType
- **Data Layer**: APIService, CacheService, APODRepository
- **Image Caching**: ImageCacheActor (memory + disk, last successful behavior)
- **ViewModels**: TodayViewModel (stale refresh), ExploreViewModel (cached fallback, date sync)

## Project Structure

```
NasaApod/
├── App/                    # Entry point, DI container
├── Core/
│   ├── Utilities/          # LoadingState, AppLogger, CircuitBreaker
│   └── ImageCaching/       # Self-contained image caching module
│       ├── ImageCacheActor.swift      # Hybrid memory + disk cache
│       └── CachedAsyncImage.swift     # SwiftUI view with cache key
├── Domain/
│   ├── Models/             # APOD, MediaType, APODError
│   └── Repositories/       # APODRepositoryProtocol
├── Data/
│   ├── Network/            # APIService, APODEndpoint, NetworkError
│   ├── Cache/              # CacheService (APOD data cache)
│   └── Repositories/       # APODRepository
└── Features/
    ├── Today/              # Today's APOD
    ├── Explore/            # Date picker + ImageDetailView
    ├── Favorites/          # Placeholder for expansion
    └── Settings/           # Placeholder for expansion
```

## API

**Endpoint**: `https://api.nasa.gov/planetary/apod`

Uses a registered API key (1,000 requests/hour).

## Security

API key is hardcoded for demo/review convenience. A production app would use a more secure approach.

## Features

- [x] Display today's APOD (image or embedded video)
- [x] Date picker to explore any day's APOD
- [x] Tap image to view full-screen detail with zoom
- [x] Offline support with last successful APOD cached
- [x] Circuit breaker for network resilience
- [x] State-driven navigation (extensible for deep linking)
- [x] Tab bar navigation (extensible)
- [x] Dark mode support
- [x] Dynamic Type accessibility
- [x] iPad support

## Known Issues

- **No offline handling in Today view** — Only the Explore page shows an offline banner with cached fallback. Today page shows an error when offline with no cached data.
- **No auto-refresh in Explore view** — scenePhase monitoring only runs on the Today page. If the user is on the Explore tab when the day changes, it won't auto-refresh.
- **"APOD not yet published" treated as error** — When NASA hasn't published today's APOD yet (typically before morning US time), it's shown as a generic error. Ideally this would be a distinct state to enable auto-retry or a countdown UI.
- **Theming is basic** — A new theme requires additional UI-layer wiring (backgrounds, nav bars, scroll views). The current theme system is not yet fully applied across all containers.

## Future Improvements

- Cache all visited APODs — currently only the last successful is cached; architecture supports caching all (remove the `clearCache()` before save)
- Deep linking — `Destination` enum is ready but no URL handler wired up
- Theme picker — `AppTheme` protocol supports custom themes but no UI to switch
- Favorites and Settings — tabs are scaffolded for extensibility but not yet implemented
- Animated GIF support (currently displays first frame)
