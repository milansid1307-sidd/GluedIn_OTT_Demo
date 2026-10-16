# GluedIn OTT Demo

An OTT-style iOS application built as a second-round technical assignment, demonstrating Clean Architecture, MVVM, UIKit/XIB, and AVPlayer integration.

---

## Steps to Build and Run

1. Open `GluedIn_OTT_Demo.xcodeproj` in Xcode 16+
2. Select a simulator or physical device (iPhone, iOS 16+)
3. Press `Cmd+R` — no additional setup required
4. No third-party dependencies — no `pod install` or `swift package resolve` needed

**Minimum supported iOS version:** iOS 16.0

---

## Architecture Overview

The app follows **Clean Architecture** with **MVVM** across three strict layers:

```
Presentation Layer   →   Domain Layer   →   Data Layer
ViewController            UseCase             Repository impl
ViewModel                 Repository          DataSource
UICollectionView          Domain Models       DTOs + Mappers
```

Data flows strictly top-down with no layer skipping:

```
UI → ViewModel → UseCase → Repository → DataSource → Static JSON
```

ViewModels depend only on UseCase protocols. UseCases depend only on Repository protocols. This means the mock data source can be swapped for a real API without touching any UI, ViewModel, or UseCase code.

---

## Project / Module Structure

```
GluedIn_OTT_Demo/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Presentation/
│   ├── Splash/
│   │   └── SplashViewController.swift
│   ├── Home/
│   │   ├── HomeViewController.swift + .xib
│   │   ├── HomeViewModel.swift
│   │   └── Cells/
│   │       ├── HeroBannerCell.swift + .xib
│   │       ├── ContentRailCell.swift + .xib
│   │       └── ContentCardCell.swift + .xib
│   ├── Detail/
│   │   ├── View/ContentDetailViewController.swift + .xib
│   │   └── ViewModel/ContentDetailViewModel.swift
│   ├── Player/
│   │   ├── View/PlayerViewController.swift + .xib
│   │   └── ViewModel/PlayerViewModel.swift
│   └── SeeAll/
│       └── View/SeeAllViewController.swift
├── Domain/
│   ├── Model/           (Content, ContentRail, HeroBanner)
│   ├── Repository/      (ContentRepositoryProtocol)
│   └── UseCase/         (GetHomeContentUseCase, GetMoreRailsUseCase)
├── Data/
│   ├── DTO/             (HomeResponseDTO, RailDTO, ContentDTO)
│   ├── Mapper/          (ContentMapper — DTO → Domain)
│   ├── Repository/      (ContentRepositoryImpl)
│   └── Remote/          (ContentRemoteDataSourceProtocol, MockContentDataSource)
├── Player/
│   ├── PlayerEvent.swift
│   ├── PlayerEventHandler.swift
│   └── AnalyticsEventRepository.swift
└── Resources/
    ├── MockHomeResponse.json
    └── splash_screen.gif
```

---

## Libraries Used

**None.** Zero third-party dependencies. Uses only Apple frameworks:

| Framework | Purpose |
|---|---|
| `UIKit` | All UI — ViewControllers, cells, layout |
| `AVFoundation` | AVPlayer, AVPlayerLayer, AVPlayerItem |
| `AVKit` | PiP (Picture-in-Picture) support |
| `ImageIO` | GIF frame decoding for splash screen |
| `Network` | NWPathMonitor for connectivity detection |
| `os.Logger` | Structured logging for player analytics |

---

## Key Technical / Architectural Decisions

### XIB-per-file
Every screen and cell has a dedicated `.xib`. No Storyboard (removed to avoid segue coupling). Programmatic views added only where XIB constraints are impractical (SeeAll header, video preview mute button, toast messages).

### Protocol + DI at every boundary
Every layer boundary is a Swift protocol. `SceneDelegate` builds the full dependency chain via `instantiate()` factory methods — no singletons in domain or data layers.

### ViewState enum
ViewModels expose `ViewState<T>: idle | loading | success(T) | empty | error(String)`. ViewControllers observe via `onStateChange` closure — `[weak self]` throughout to avoid retain cycles.

### async/await
All data fetching uses Swift Concurrency. `MockContentDataSource` simulates 500ms delay via `try await Task.sleep`. ViewModels are `@MainActor` — no manual `DispatchQueue.main.async`.

### Image caching
`UIImageView+Cache` uses `NSCache<NSString, UIImage>` keyed by URL string. Thumbnail loaded on Home is reused on Detail — no re-download on navigation.

### Shimmer loading
Custom `ShimmerView` animates a gradient sweep (`CAGradientLayer` + `CABasicAnimation`) during data fetch — no third-party library.

### Network status banner
`NWPathMonitor` on a background queue posts `.networkDidDisconnect` / `.networkDidReconnect` notifications. `NetworkStatusBanner` observes and slides a red/green strip in from the top of the window automatically.

### Splash screen
`UIImage.animatedGIF(named:)` decodes GIF frames via `CGImageSourceCreateImageAtIndex` at runtime, builds `UIImage.animatedImage(with:duration:)`. No UIWebView or third-party GIF library.

### See All sheet
Full-screen `modalPresentationStyle = .fullScreen` modal with a 2-column `UICollectionView`. Paginates 10 items per page with simulated delay and a footer spinner. Item tap dismisses the sheet then calls `onSelectContent` callback so the presenter can push Detail.

### Dark mode
`UIUserInterfaceStyle = Dark` in `Info.plist` — system-wide, no per-screen overrides.

### Detail video preview
1.5s `DispatchWorkItem` delay after `viewWillAppear`, then `AVPlayer` (muted) starts inline in the banner frame. KVO on `timeControlStatus == .playing` reveals the mute toggle button. Loops via `AVPlayerItemDidPlayToEndTime` notification. Stops and cleans up in `viewWillDisappear`.

---

## Player Event Handling Approach

Events flow through a dedicated pipeline — the ViewController never reads AVPlayer state directly:

```
AVPlayer (KVO + Notifications)
    ↓
PlayerEventHandler          — captures raw signals, emits typed PlayerEvent enum
    ↓
PlayerViewModel             — processes events, updates ViewState, calls delegate
    ↓
AnalyticsEventRepository    — logs via os.Logger (subsystem: com.gluedIn.OTT)
```

**7 events implemented:**

| Event | Mechanism |
|---|---|
| `playerReady` | KVO `player.status == .readyToPlay` |
| `playbackStarted` | KVO `timeControlStatus == .playing` |
| `playbackPaused` | KVO `timeControlStatus == .paused` |
| `bufferingStarted` | KVO `timeControlStatus == .waitingToPlayAtSpecifiedRate` |
| `bufferingEnded` | Transition out of buffering state |
| `seekPerformed(toTime:)` | Manual dispatch after `player.seek(to:)` completes |
| `playbackCompleted` | `AVPlayerItemDidPlayToEndTimeNotification` |

Observers are removed in `viewWillDisappear` and `PlayerEventHandler.detach()` — no dangling KVO.

---

## How Mock Data Source Would Be Replaced with a Real API

Only `MockContentDataSource` needs replacing — nothing else changes.

**Current:**
```swift
// Data/Remote/MockContentDataSource.swift
class MockContentDataSource: ContentRemoteDataSourceProtocol {
    func fetchHome() async throws -> HomeResponseDTO {
        // Decodes MockHomeResponse.json from Bundle
    }
    func fetchMoreRails(page: Int) async throws -> [RailDTO] {
        // Returns static paginated data
    }
}
```

**Future (real API):**
```swift
class LiveContentDataSource: ContentRemoteDataSourceProtocol {
    private let baseURL = URL(string: "https://api.example.com")!

    func fetchHome() async throws -> HomeResponseDTO {
        let (data, _) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("/home"))
        return try JSONDecoder().decode(HomeResponseDTO.self, from: data)
    }

    func fetchMoreRails(page: Int) async throws -> [RailDTO] {
        var url = baseURL.appendingPathComponent("/rails")
        url.append(queryItems: [URLQueryItem(name: "page", value: "\(page)")])
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([RailDTO].self, from: data)
    }
}
```

Inject in `SceneDelegate` or `HomeViewController.instantiate()`:
```swift
// Before:
let dataSource = MockContentDataSource()
// After:
let dataSource = LiveContentDataSource()
```

**Zero changes required in:** UI, ViewModels, UseCases, Domain Models, Repository contracts.

---

## Known Limitations

- Video URLs are publicly hosted MP4s (Pixabay CDN) — playback requires internet connectivity
- No user authentication or profile management
- Download and My List features show a "coming soon" toast — not implemented
- PiP requires a physical device; iOS Simulator does not support Picture-in-Picture
- No offline video caching — the app plays from URL only
- Seek event fires on touch-up only — intermediate drag positions not tracked
- Video URLs use Pixabay CDN stock footage — these files have **no audio track**. The mute/unmute button in the detail preview is present but has no audible effect on silent streams. Replace with audio-bearing URLs for sound functionality
