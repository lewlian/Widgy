# STACK.md -- Widgy: iOS AI-Powered Custom Widget Builder

> **Research type:** Project Stack Dimension
> **Date:** 2026-02-23
> **Confidence methodology:** HIGH = verified in official docs/releases; MEDIUM = strong signals from ecosystem; LOW = best inference, verify before committing

---

## 1. Executive Summary

Widgy is a greenfield iOS 26+ app that lets users create custom homescreen/lockscreen widgets through natural language conversation with Claude AI. Widgets are rendered from a config-based JSON schema (no dynamic code generation). Backend is Supabase. This document prescribes the full technology stack with specific libraries, versions, rationale, and anti-recommendations.

---

## 2. Platform & Language

| Layer | Choice | Version | Confidence |
|-------|--------|---------|------------|
| **Language** | Swift | 6.x (ships with Xcode 26) | HIGH |
| **UI Framework** | SwiftUI | iOS 26 SDK | HIGH |
| **Minimum Target** | iOS 26.0 | -- | HIGH |
| **IDE** | Xcode 26 | Latest beta/release | HIGH |
| **Package Manager** | Swift Package Manager (SPM) | Built into Xcode | HIGH |

### Rationale
- **Swift 6**: Full strict concurrency checking enabled by default. The complete concurrency model (actors, structured concurrency, Sendable) is production-ready. iOS 26-only means zero backward-compatibility burden, so lean fully into async/await, `@Observable`, and the latest SwiftUI APIs.
- **SwiftUI-only**: No UIKit wrappers needed for an iOS 26-only app. SwiftUI is the first-class citizen for Liquid Glass and all new widget rendering APIs.
- **SPM over CocoaPods/Carthage**: CocoaPods is in maintenance mode. SPM is the default and all dependencies listed below support it natively.

### What NOT to use
- **UIKit**: No reason for iOS 26-only. SwiftUI covers all widget and main app UI needs. UIKit adds bridging complexity with no benefit.
- **CocoaPods**: Legacy. Slower builds, extra `Podfile` maintenance, no Xcode integration. All recommended deps support SPM.
- **Objective-C**: Zero new Obj-C code. Swift 6 concurrency features have no Obj-C equivalent.

---

## 3. iOS 26 / Liquid Glass Specific

| Component | API / Framework | Confidence |
|-----------|----------------|------------|
| **Liquid Glass UI** | SwiftUI `.glassEffect()` modifier, `GlassEffectContainer` | HIGH |
| **Design tokens** | System materials, vibrancy, and dynamic tinting via Liquid Glass | HIGH |
| **Navigation** | `NavigationStack` with Liquid Glass tab bars and toolbars (automatic in iOS 26) | HIGH |
| **Widget rendering** | WidgetKit with Liquid Glass support (automatic for system-provided containers) | HIGH |

### Rationale
- iOS 26 introduced Liquid Glass as the system-wide design language at WWDC 2025. SwiftUI views automatically adopt Liquid Glass styling for navigation bars, tab bars, and toolbars. Custom glass effects use the `.glassEffect()` modifier.
- **Key consideration**: Widgets on the homescreen/lockscreen get Liquid Glass treatment automatically when using standard WidgetKit containers. Custom widget backgrounds should use system materials to blend correctly.

### What NOT to use
- **Custom blur/vibrancy hacks**: Do not manually create `UIVisualEffectView` wrappers. Use `.glassEffect()` and system materials instead.
- **Third-party design system libraries**: Liquid Glass is system-provided. Third-party theming libraries will fight the OS.

---

## 4. WidgetKit (Core Domain)

| Component | API | iOS Version | Confidence |
|-----------|-----|-------------|------------|
| **Home Screen Widgets** | `WidgetKit` / `TimelineProvider` | iOS 14+ | HIGH |
| **Lock Screen Widgets** | `WidgetFamily.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline` | iOS 16+ | HIGH |
| **Interactive Widgets** | `AppIntent`-based interactions via `Button`, `Toggle` in widget views | iOS 17+ | HIGH |
| **Widget Configuration** | `AppIntentConfiguration` (replaces `IntentConfiguration`) | iOS 17+ | HIGH |
| **StandBy Mode Widgets** | Same WidgetKit families, optimized for StandBy display | iOS 17+ | HIGH |
| **Live Activities** | `ActivityKit` (if real-time widget updates needed) | iOS 16.1+ | MEDIUM |
| **Animated Widget Transitions** | `ContentTransition` and animated timeline updates | iOS 26 | MEDIUM |

### Widget Architecture for Widgy

Since widgets are **config-driven JSON rendered to SwiftUI**, the architecture is:

```
JSON Config --> Widget Schema Parser --> SwiftUI View Builder --> WidgetKit Timeline
```

- Each user-created widget is stored as a JSON document (in Supabase).
- A `WidgetSchemaRenderer` takes the JSON and produces a SwiftUI view hierarchy.
- `TimelineProvider` fetches the latest config and renders it.
- Widget Extension communicates with the main app via **App Groups** and shared `UserDefaults` / file containers.

### Key WidgetKit Constraints (Critical for Architecture)
- **No networking in widget extension at render time**: Must pre-fetch data. Use `TimelineProvider.getTimeline()` to schedule updates, but heavy network calls should happen in the main app and be passed via App Groups.
- **Limited memory**: Widget extensions are constrained (~30MB). Keep JSON parsing lightweight.
- **Static views only**: No scrolling, no video, no complex gestures. Design the JSON schema around what WidgetKit can actually render.
- **Size families**: Support `.systemSmall`, `.systemMedium`, `.systemLarge`, `.systemExtraLarge`, `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`.

### What NOT to use
- **`IntentConfiguration` (deprecated)**: Use `AppIntentConfiguration` exclusively. The `SiriKit Intents`-based configuration is legacy.
- **Dynamic code execution for widgets**: WidgetKit does not support this. The JSON-to-SwiftUI renderer must be a compile-time mapping, not runtime code generation.

---

## 5. Supabase (Backend)

| Component | Library | Version | Confidence |
|-----------|---------|---------|------------|
| **Supabase Swift SDK** | `supabase-swift` | 2.x (latest: ~2.22+) | HIGH |
| **Auth** | `supabase-swift` Auth module (Sign in with Apple, email/password) | 2.x | HIGH |
| **Database** | PostgREST via `supabase-swift` | 2.x | HIGH |
| **Realtime** | Supabase Realtime via `supabase-swift` | 2.x | MEDIUM |
| **Storage** | Supabase Storage via `supabase-swift` | 2.x | HIGH |
| **Edge Functions** | Supabase Edge Functions (Deno) | -- | HIGH |

### SPM Package
```swift
// Package.swift or Xcode SPM dependency
.package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
```

### Rationale
- **supabase-swift 2.x**: Complete rewrite with native Swift concurrency (async/await). Fully supports iOS 17+. Includes Auth, PostgREST, Realtime, Storage, and Edge Functions clients in a single package.
- **Sign in with Apple**: Required for App Store if any third-party auth is offered. Supabase Auth supports it natively.
- **Edge Functions for Claude API proxy**: The Anthropic API key should NEVER be in the iOS app bundle. Use Supabase Edge Functions as a secure proxy to call the Claude API server-side. This also enables rate limiting, usage tracking, and prompt injection filtering.
- **Row Level Security (RLS)**: All widget configs stored in Postgres with RLS policies. Users can only access their own widgets.
- **Realtime**: Optional but useful if implementing collaborative widget editing or live preview sync.

### Database Schema Considerations
- `widgets` table: stores JSON config, user_id, widget metadata, created/updated timestamps
- `conversations` table: stores chat history per widget for context continuity
- `user_profiles` table: subscription tier, usage counts
- `widget_templates` table: community/system templates

### What NOT to use
- **Firebase**: Supabase is specified. Firebase would add Google dependency and different auth/db paradigms.
- **Direct Anthropic API calls from iOS**: Security risk. API keys in app bundles can be extracted. Always proxy through Edge Functions.
- **Core Data / SwiftData for primary storage**: Supabase is the source of truth. Use SwiftData only for local caching/offline support (see Section 8).

---

## 6. AI Integration (Anthropic Claude)

| Component | Approach | Confidence |
|-----------|----------|------------|
| **API Access** | Anthropic Messages API via Supabase Edge Functions (proxy) | HIGH |
| **Model** | `claude-sonnet-4-20250514` (primary), `claude-haiku-235-20241022` (fast/cheap tasks) | HIGH |
| **Streaming** | Server-Sent Events (SSE) from Edge Function to iOS app | HIGH |
| **Prompt Format** | System prompt + user messages with structured JSON output | HIGH |
| **Response Parsing** | Structured output / tool use for guaranteed JSON schema compliance | HIGH |

### Architecture

```
iOS App --> Supabase Edge Function --> Anthropic Messages API
                                          |
                                    Claude Response (JSON widget config)
                                          |
iOS App <-- SSE Stream <-- Edge Function <--
```

### Model Selection Rationale
- **Claude Sonnet 4** (`claude-sonnet-4-20250514`): Best balance of intelligence, speed, and cost for widget generation. Strong at structured JSON output. Use for primary widget creation/editing conversations.
- **Claude Haiku 3.5** (`claude-haiku-235-20241022`): Use for lightweight tasks -- widget description summarization, simple config tweaks, quick suggestions. ~10x cheaper than Sonnet.
- **Claude Opus 4** (`claude-opus-4-20250514`): Overkill for widget config generation. Reserve only if complex multi-step reasoning is needed (unlikely for this use case).

### Structured Output Strategy
Use Claude's **tool use / function calling** to enforce JSON schema compliance:

```json
{
  "name": "generate_widget_config",
  "description": "Generate a widget configuration from user description",
  "input_schema": {
    "type": "object",
    "properties": {
      "widget_type": { "enum": ["systemSmall", "systemMedium", "systemLarge", ...] },
      "background": { ... },
      "elements": { "type": "array", "items": { ... } }
    },
    "required": ["widget_type", "elements"]
  }
}
```

This guarantees the response is valid JSON matching the widget schema, eliminating parsing failures.

### Streaming Implementation
- Edge Function uses the Anthropic SDK (`@anthropic-ai/sdk` for Deno/Node) to call the Messages API with `stream: true`.
- Edge Function forwards SSE events to the iOS client.
- iOS client uses `URLSession` with `AsyncBytes` to consume the stream progressively.
- Display partial widget preview as tokens arrive for a responsive UX.

### What NOT to use
- **OpenAI API**: Project specifies Claude/Anthropic.
- **On-device LLMs (Core ML)**: Not powerful enough for structured widget generation. Latency and quality would suffer.
- **Langchain / LlamaIndex Swift ports**: Over-abstraction for a focused use case. Direct API calls through Edge Functions are simpler and more maintainable.
- **Storing API keys in iOS app**: Security vulnerability. Always proxy.

---

## 7. JSON Schema & Validation

| Component | Library | Version | Confidence |
|-----------|---------|---------|------------|
| **JSON Decoding** | Swift `Codable` (Foundation) | Built-in | HIGH |
| **Schema Validation** | Custom Swift validation layer using `Codable` + runtime checks | -- | HIGH |
| **JSON Schema Definition** | Shared schema between Edge Functions and iOS (JSON Schema Draft 2020-12) | -- | HIGH |

### Rationale
- **Swift `Codable` is sufficient**: For a well-defined widget config schema, `Codable` with custom `init(from:)` provides compile-time type safety and runtime validation. No need for a heavy JSON Schema validation library.
- **Schema-as-Swift-types**: Define the widget config as Swift structs with `Codable` conformance. Invalid JSON fails to decode with descriptive errors.

### Widget Config Schema Design

```swift
struct WidgetConfig: Codable, Sendable {
    let version: Int // Schema version for migration
    let widgetFamily: WidgetFamily
    let background: BackgroundConfig
    let elements: [WidgetElement]
    let metadata: WidgetMetadata
}

enum WidgetElement: Codable, Sendable {
    case text(TextElementConfig)
    case image(ImageElementConfig)
    case shape(ShapeElementConfig)
    case gauge(GaugeElementConfig)
    case stack(StackConfig) // HStack, VStack, ZStack
    case spacer(SpacerConfig)
    case dateDisplay(DateDisplayConfig)
    case weatherDisplay(WeatherDisplayConfig)
    // ... extensible
}
```

### Schema Versioning
- Include a `version` field in every widget config.
- Migration logic in the renderer handles older schemas gracefully.
- This is critical for App Store updates that evolve the schema.

### What NOT to use
- **JSONSchema.swift or similar JSON Schema validation libraries**: Over-engineered for this case. The schema is owned by us, not arbitrary. Swift types ARE the schema.
- **XML-based config**: JSON is the standard for API communication and Codable support.
- **Property lists**: Less portable, no advantage over JSON for this use case.

---

## 8. Local Persistence & Caching

| Component | Library | Version | Confidence |
|-----------|---------|---------|------------|
| **Local Cache** | SwiftData | iOS 17+ (ships with iOS 26) | HIGH |
| **Keychain** | `KeychainAccess` or native Security framework | 4.x / built-in | MEDIUM |
| **Widget Data Sharing** | App Groups + shared `UserDefaults` and file container | Built-in | HIGH |
| **Image Caching** | `Kingfisher` or `SDWebImageSwiftUI` | 8.x / 3.x | MEDIUM |

### Rationale
- **SwiftData**: Native Apple persistence framework, replaces Core Data for new projects. Perfect for caching widget configs, conversation history, and user preferences locally. Fully SwiftUI-integrated with `@Query` macro.
- **App Groups**: Required for sharing data between the main app and widget extension. Store the latest widget configs in the shared container so widgets render without network dependency.
- **Image caching**: If widgets support user-uploaded images or remote assets, a caching library prevents redundant downloads. `Kingfisher` is the most mature option with SwiftUI support.

### What NOT to use
- **Core Data**: SwiftData supersedes it for new iOS 17+ projects. Core Data adds boilerplate with no benefit.
- **Realm**: Third-party dependency with its own sync story. Conflicts with Supabase as primary backend.
- **UserDefaults for large data**: Widget configs can be complex. Use the shared file container for JSON files, not UserDefaults (which has size limits and perf issues).

---

## 9. Networking

| Component | Library | Version | Confidence |
|-----------|---------|---------|------------|
| **HTTP Client** | `URLSession` (Foundation) | Built-in | HIGH |
| **SSE Streaming** | `URLSession.AsyncBytes` | Built-in (iOS 15+) | HIGH |
| **API Layer** | Supabase Swift SDK (wraps URLSession) | 2.x | HIGH |

### Rationale
- **No Alamofire**: For an iOS 26-only app, `URLSession` with async/await is clean, performant, and has zero dependency overhead. The Supabase SDK already wraps URLSession internally.
- **SSE for streaming**: `URLSession.bytes(for:)` provides an `AsyncSequence` of bytes, perfect for consuming Claude's streaming responses forwarded through Edge Functions.

### What NOT to use
- **Alamofire**: Unnecessary abstraction for iOS 26+. Modern URLSession API is equally ergonomic.
- **Moya**: Same reasoning. Adds layers with no benefit when Supabase SDK handles most API calls.
- **gRPC**: Overkill. REST + SSE covers all needs.

---

## 10. Architecture & Patterns

| Pattern | Choice | Confidence |
|---------|--------|------------|
| **App Architecture** | MVVM with `@Observable` (Observation framework) | HIGH |
| **Dependency Injection** | Swift Environment + manual injection (no DI framework) | HIGH |
| **Navigation** | `NavigationStack` with type-safe `NavigationPath` | HIGH |
| **Concurrency** | Swift structured concurrency (async/await, actors, TaskGroups) | HIGH |
| **State Management** | `@Observable` classes + SwiftUI `@State` / `@Environment` | HIGH |

### Rationale
- **`@Observable` over `ObservableObject`**: The Observation framework (iOS 17+) is the modern replacement. More precise view updates (only re-renders when accessed properties change), less boilerplate (no `@Published`).
- **No third-party DI**: SwiftUI's `@Environment` and custom `EnvironmentKey` provide a clean, native DI system. For the widget extension, manual injection via initializers is simpler and safer.
- **Actors for thread safety**: Use actors for shared mutable state (e.g., `ConversationManager`, `WidgetConfigStore`). Swift 6 strict concurrency makes data races compile-time errors.

### What NOT to use
- **`ObservableObject` / `@Published`**: Legacy pattern. `@Observable` is strictly better for iOS 17+.
- **RxSwift / Combine**: Combine is in maintenance mode. `@Observable` + async/await replaces reactive patterns for SwiftUI apps.
- **The Composable Architecture (TCA)**: Heavyweight for this app scope. TCA's learning curve and boilerplate are justified for large teams, not a focused product.
- **VIPER / Clean Architecture**: Over-architected for a SwiftUI-first app. MVVM with `@Observable` maps naturally to SwiftUI's data flow.

---

## 11. Testing

| Component | Library | Version | Confidence |
|-----------|---------|---------|------------|
| **Unit Testing** | Swift Testing framework (`@Test`, `#expect`) | Swift 6 / Xcode 16+ | HIGH |
| **UI Testing** | XCTest UI Testing | Built-in | HIGH |
| **Snapshot Testing** | `swift-snapshot-testing` (Point-Free) | 1.17+ | MEDIUM |
| **Mocking** | Protocol-based mocking (manual) | -- | HIGH |

### Rationale
- **Swift Testing over XCTest for unit tests**: The new `@Test` macro and `#expect` API are cleaner, support parameterized tests, and are the future direction. XCTest UI Testing is still needed for UI automation.
- **Snapshot testing**: Critical for widget rendering validation. Ensure JSON configs produce the expected SwiftUI output visually.
- **No mocking frameworks**: Swift's protocol-oriented design makes manual mocks straightforward. Mocking frameworks add complexity and often break with Swift version updates.

---

## 12. Developer Tooling

| Tool | Purpose | Confidence |
|------|---------|------------|
| **SwiftLint** | Code style enforcement | HIGH |
| **SwiftFormat** | Auto-formatting | HIGH |
| **Xcode Cloud or GitHub Actions** | CI/CD | MEDIUM |
| **Periphery** | Dead code detection | MEDIUM |

---

## 13. Complete Dependency List (Package.swift)

```swift
dependencies: [
    // Supabase (auth, database, storage, realtime, edge functions)
    .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),

    // Image caching (if remote images in widgets)
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),

    // Snapshot testing (test target only)
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0"),

    // Keychain access (if not using Security framework directly)
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
]
```

**Total third-party runtime dependencies: 2-3** (Supabase SDK, Kingfisher, optionally KeychainAccess)

This is intentionally minimal. The iOS 26 SDK provides everything else natively.

---

## 14. Infrastructure (Supabase Edge Functions)

| Component | Technology | Confidence |
|-----------|-----------|------------|
| **Runtime** | Deno (Supabase Edge Functions) | HIGH |
| **Anthropic SDK** | `@anthropic-ai/sdk` (npm/Deno) | HIGH |
| **Streaming** | SSE response from Edge Function | HIGH |
| **Rate Limiting** | Edge Function middleware + Supabase DB counters | MEDIUM |
| **Prompt Management** | Versioned system prompts in Edge Function code or DB | MEDIUM |

### Edge Function Responsibilities
1. **Claude API Proxy**: Accept user message, add system prompt, call Anthropic Messages API, stream response back.
2. **Schema Validation**: Validate Claude's JSON output matches widget schema before returning to client.
3. **Usage Tracking**: Increment token usage counters per user for billing/rate limiting.
4. **Prompt Injection Filtering**: Basic guardrails on user input before sending to Claude.

---

## 15. Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| **iOS 26 APIs change in beta** | Medium | Pin to stable API surfaces. Avoid private/undocumented APIs. Monitor WWDC sessions and release notes. |
| **Supabase Swift SDK breaking changes** | Low | Pin to major version (2.x). SDK follows semver. |
| **Claude API output inconsistency** | Medium | Use tool use/function calling for structured output. Validate all responses server-side before forwarding to client. |
| **Widget extension memory limits** | Medium | Keep JSON renderer lightweight. Profile with Instruments. Avoid image decoding in extension. |
| **Liquid Glass API surface is new** | Medium | Lean on automatic system styling where possible. Custom `.glassEffect()` usage should be minimal and tested on device. |

---

## 16. Version Verification Notes

> **Important**: The following versions are based on knowledge current to early 2025. Before starting development, verify:
> - `supabase-swift` exact latest version at https://github.com/supabase/supabase-swift/releases
> - `Kingfisher` exact latest version at https://github.com/onevcat/Kingfisher/releases
> - iOS 26 SDK availability and any WidgetKit API changes in latest Xcode 26 release notes
> - Claude model identifiers at https://docs.anthropic.com/en/docs/about-claude/models
> - `swift-snapshot-testing` version at https://github.com/pointfreeco/swift-snapshot-testing/releases

---

## 17. Decision Log

| Decision | Chosen | Rejected | Why |
|----------|--------|----------|-----|
| UI Framework | SwiftUI (iOS 26 only) | UIKit, cross-platform | iOS 26 only = full SwiftUI + Liquid Glass |
| Backend | Supabase | Firebase, custom server | Project requirement; excellent Swift SDK |
| AI Provider | Claude via Edge Functions | OpenAI, on-device ML | Project requirement; structured output via tool use |
| Persistence | SwiftData + Supabase | Core Data, Realm | Native, modern, SwiftUI-integrated |
| HTTP Client | URLSession | Alamofire, Moya | Native async/await, zero deps, iOS 26 only |
| Architecture | MVVM + @Observable | TCA, VIPER, MVC | Natural SwiftUI fit, low boilerplate |
| State Management | Observation framework | Combine, RxSwift | Modern Apple direction, precise updates |
| JSON Validation | Swift Codable types | JSON Schema libraries | Schema is owned, types ARE the schema |
| Package Manager | SPM | CocoaPods, Carthage | Native, all deps support it |
| Testing | Swift Testing + XCTest UI | Quick/Nimble | Native, modern, first-class Xcode support |
