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

| Layer | Contains | Knows about external systems? |
|-------|----------|------------------------------|
| **Domain** | Models (`APOD`), Protocols (`APODRepositoryProtocol`) | No - pure business logic |
| **Data** | Implementations (`APODRepository`, `APIService`, `CacheService`) | Yes - network, disk, etc. |

**Why Repositories folder in both?**
- `Domain/Repositories/` contains the **protocol** (interface) - defines WHAT the app needs
- `Data/Repositories/` contains the **implementation** - defines HOW to get it

This separation means Features depend only on Domain protocols, not Data implementations. Easy to swap implementations (real vs mock for testing).

### Key Components

| Component | Purpose |
|-----------|---------|
| `APIService` | URLSession wrapper with retry logic |
| `CacheService` | Actor-based cache (memory + disk) |
| `APODRepository` | Coordinates network and cache with circuit breaker |
| `CircuitBreaker` | Prevents cascading failures when API is unavailable |

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
- Single enum prevents impossible states (no `isLoading: Bool` + `error: Error?` combinations)
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

### Explicit Dependency Injection

ImageCache is injected explicitly via initializer, not SwiftUI Environment:

```swift
// Explicit injection (used)
TodayView(viewModel: viewModel, imageCache: imageCache)

// vs Environment (not used)
TodayView().environment(\.imageCache, imageCache)
```

**Why explicit?**
- Not every screen needs image cache (unlike dismiss or colorScheme)
- Compile-time guarantee that dependencies are provided
- Clearer data flow and easier debugging
- Environment is better for truly global, cross-cutting concerns

### Sheet-Based Date Picker

ExploreView uses a sheet for date selection instead of inline compact picker:

**Why?**
- Compact DatePicker had unreliable auto-dismiss on date selection
- Sheet provides clear user flow: tap → select → Done
- Graphical picker style shows full calendar
- State-driven: `activeSheet = .datePicker` to show, `= nil` to dismiss

### User-Friendly HTTP Error Messages

NetworkError provides context-specific messages:

| Status | Message |
|--------|---------|
| 400 | "Invalid request. Please try again." |
| 401 | "Invalid API key. Please check your configuration." |
| 403 | "API access denied. You may have exceeded the rate limit." |
| 404 | "No APOD available for this date. NASA publishes daily on US Eastern Time." |
| 429 | "Too many requests. Please wait a moment and try again." |
| 5xx | "NASA server is temporarily unavailable. Please try again later." |

**Why 404 message mentions timezone?**
- APOD publishes daily on US Eastern Time
- Users in other timezones may query "today" before NASA publishes
- Also applies to dates before June 16, 1995 (APOD start date)

### CacheService vs URLSession cache

URLSession respects HTTP cache headers - if the server says `no-cache`, it won't cache. The challenge requires guaranteed offline fallback, so `CacheService` provides explicit control regardless of server headers.

### Circuit Breaker

When the API is down, repeated failures waste resources. The circuit breaker stops retrying after N failures and uses cache instead, providing graceful degradation.

### Actor-based Concurrency

`CacheService` and `CircuitBreaker` use actors for thread-safe state without manual locks. Swift 6 strict concurrency catches data races at compile time.

### Why custom image caching instead of AsyncImage?

`AsyncImage` relies on HTTP cache headers, but NASA's servers don't guarantee proper caching. Images were reloading on every view appearance during testing.

`CachedAsyncImage` + `ImageCacheActor` provides explicit control:
- Memory cache (`NSCache`, 50 MB) for fast session access
- Disk cache for offline support after app restart
- Meets the "last service call including image should be cached" requirement

### Protocol-based Dependency Injection

Chose protocol-based DI over struct closures (Point-Free style) for better Xcode tooling and familiarity for reviewers.

### FileManager in CacheService

CacheService uses `FileManager.default` directly. Abstracting it would allow mocking disk errors, but adds complexity and `FileManager` isn't `Sendable` (complicates actor isolation). Tests use real filesystem and clean up after each run.

## Testing

Run tests with ⌘U or:

```bash
xcodebuild test -scheme NasaApod -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Style

Tests follow **BDD style** with Given/When/Then comments:

```swift
func testSaveLastSuccessful_OnlyKeepsOneAPOD_ClearsPrevious() async throws {
    // Given - Two different APODs
    let firstAPOD = makeAPOD(date: "2024-01-01")
    let secondAPOD = makeAPOD(date: "2024-02-02")

    // When - Save first, then second
    try await cacheService.saveLastSuccessful(firstAPOD)
    try await cacheService.saveLastSuccessful(secondAPOD)

    // Then - Only second (last) APOD exists
    let loaded = try await cacheService.loadLastSuccessful()
    XCTAssertEqual(loaded.date, "2024-02-02")
}
```

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

- Favorites tab to bookmark APODs
- Share functionality
- Widget for home screen
