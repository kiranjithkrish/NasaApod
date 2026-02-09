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

All UI follows a declarative, state-driven approach:

**Content State** - `LoadingState<T>` enum:
```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}
```
- Single enum ensures only one state at a time (can't be loading AND errored simultaneously)
- Views switch on state to render appropriate UI
- ViewModel updates state, SwiftUI reacts automatically

**Presentation State** - Optional enums for sheets:
```swift
enum Sheet: Identifiable {
    case datePicker
}
@State private var activeSheet: Sheet?  // nil = dismissed
```
- Avoids boolean flags like `isDatePickerPresented: Bool`
- Extensible: add more cases for additional sheets

**Navigation State** - Destination enum:
```swift
enum Destination: Hashable {
    case imageDetail(APOD)
}
@Published var destination: Destination?
```
- Navigation driven by state, not imperative push/pop
- Extensible for deep linking: just set `destination = .imageDetail(apod)` from URL handler
- Single source of truth for navigation stack

### Only Cache Last Successful APOD

**Challenge requirement**: "Last service call including image should be cached and loaded if any subsequent service call fails"

**Interpretation**: Cache only the LAST successful APOD + image, not every one loaded.

**Implementation**:
- `CacheService.saveLastSuccessful()` clears previous cache before saving
- `ImageCacheActor.saveLastSuccessfulImage()` clears previous before saving
- APOD date used as cache key (foreign key relationship between APOD data and image)

**Why date as key?**
- Links APOD JSON data with its cached image
- When loading from cache, we can retrieve both the APOD metadata AND its image
- Prevents mismatched data (wrong image for an APOD)

**Why clear before save?**
- Ensures only ONE entry exists at a time
- Meets the "last service call" requirement precisely
- Architecture is extensible: remove the clear step to cache all APODs in future

### Sheet-Based Date Picker

ExploreView uses a sheet for date selection instead of inline compact picker:

**Why?**
- Compact DatePicker had unreliable auto-dismiss on date selection
- Sheet provides clear user flow: tap → select → Done
- Graphical picker style shows full calendar
- State-driven: `activeSheet = .datePicker` to show, `= nil` to dismiss

### User-Friendly Error Messages

NetworkError provides context-specific messages for each HTTP status code (400, 401, 404, 429, 5xx) so users understand what went wrong.


### CacheService vs URLSession cache

URLSession respects HTTP cache headers - if the server says `no-cache`, it won't cache. The challenge requires guaranteed offline fallback, so `CacheService` provides explicit control regardless of server headers.

### Circuit Breaker

When the API is down, repeated failures waste resources. The circuit breaker stops retrying after N failures and uses cache instead, providing graceful degradation.

### Actor-based Concurrency

`CacheService`, `ImageCacheActor`, and `CircuitBreaker` use actors for thread-safe state without manual locks. Swift 6 strict concurrency catches data races at compile time.

### Why custom image caching instead of AsyncImage?

NASA's image server doesn't send `Cache-Control` headers, so URLSession's caching behavior is unreliable. Images were reloading on every view appearance during testing.

`CachedAsyncImage` + `ImageCacheActor` gives us explicit control:
- Memory cache (`NSCache`, 50 MB) for fast session access
- Disk cache for offline support after app restart
- Meets the "last service call including image should be cached" requirement

### Protocol-based Dependency Injection

Chose protocol-based DI over struct closures (Point-Free style) for better Xcode tooling and familiarity for reviewers.

### scenePhase Auto-Refresh vs Pull-to-Refresh

APOD does not change intra-day, so pull-to-refresh was misleading — it implied new data might be available. Instead, the Today page monitors `scenePhase` and auto-refreshes only when the day has actually changed (user returns to the app on a new day). Uses `Calendar.current.isDateInToday()` to compare the loaded APOD's date with today — zero-cost check, no timers or polling.

### FetchResult Enum at Repository Level

The repository returns `FetchResult` (`.fresh` or `.cachedFallback`) instead of a raw `APOD`. This lets the UI know whether data came from the network or cache without inferring it from date comparison. The Explore page uses this to show an offline banner and sync the date picker when displaying cached fallback data.

### FileManager in CacheService

CacheService uses `FileManager.default` directly. Abstracting it would allow mocking disk errors, but adds complexity and `FileManager` isn't `Sendable` (complicates actor isolation). Tests use real filesystem and clean up after each run.

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

## Future Improvements

- Animated GIF support (currently displays first frame)
