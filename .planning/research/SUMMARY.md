# Project Research Summary

**Project:** Widgy -- iOS AI-Powered Custom Widget Builder
**Domain:** iOS widget customization with generative AI creation
**Researched:** 2026-02-23
**Confidence:** HIGH

## Executive Summary

Widgy is a greenfield iOS 26+ app that creates a new category in the widget customization market: generative widget creation. Instead of the template-picker model (WidgetSmith, Color Widgets) or the layer-based canvas model (original Widgy, Brass), users describe widgets in natural language, and Claude AI generates a JSON configuration that a SwiftUI renderer displays as a native WidgetKit widget. The JSON config schema is the central architectural artifact -- it is the contract between the AI, the renderer, and the persistence layer. Everything else in the system exists to produce, validate, store, or render these configs.

The recommended approach is a local-first, SwiftUI-only architecture built entirely on iOS 26 APIs. The stack is intentionally minimal: Swift 6 with strict concurrency, SwiftUI with Liquid Glass, WidgetKit via AppIntentTimelineProvider, Supabase (auth, database, storage, edge functions), and Claude API proxied through Supabase Edge Functions. Only 2-3 third-party runtime dependencies are needed (Supabase Swift SDK, Kingfisher for image caching, optionally KeychainAccess). The MVVM pattern using the Observation framework (`@Observable`) maps naturally to SwiftUI. Code shared between the main app and widget extension lives in a local Swift Package (`WidgyCore`) containing the config model, renderer, and App Group manager.

The primary risks are: (1) designing a JSON schema that is expressive enough for visually interesting widgets but constrained enough for reliable AI generation -- this is THE critical design challenge; (2) Apple App Store review may flag config-based JSON rendering as remote code execution if the schema includes logic/expressions, so it must remain strictly declarative; (3) iOS 26-only deployment means near-zero addressable market at launch until fall adoption ramps up; (4) AI API costs can spiral without token budgets, model routing (Haiku for tweaks, Sonnet for generation), and generation caching. These risks are manageable with the mitigations documented in the research.

## Key Findings

### Recommended Stack

The stack targets iOS 26 exclusively, which eliminates backward compatibility overhead and enables full use of Liquid Glass, the latest WidgetKit APIs, Swift 6 structured concurrency, and the Observation framework. The dependency footprint is deliberately small -- native Apple frameworks cover networking (URLSession), persistence (SwiftData), navigation (NavigationStack), and state management (@Observable).

**Core technologies:**
- **Swift 6 / SwiftUI (iOS 26):** Full strict concurrency, Liquid Glass design language, @Observable for state management -- zero UIKit, zero Combine
- **WidgetKit (AppIntentTimelineProvider):** Config-driven widget rendering across all families (Home Screen, Lock Screen, StandBy) with App Intents for widget selection
- **Supabase Swift SDK 2.x:** Auth (Sign in with Apple), PostgREST database, Storage for user images, Edge Functions as Claude API proxy
- **Claude API (Sonnet 4 primary, Haiku 3.5 for lightweight tasks):** Structured JSON output via tool use/function calling, SSE streaming through Edge Functions
- **SwiftData:** Local caching and offline support alongside App Group shared container for widget extension communication
- **Kingfisher 8.x:** Image caching for remote assets referenced in widget configs

**Critical version notes:** Verify supabase-swift latest release, Kingfisher latest, and Claude model identifiers before development starts. iOS 26 SDK APIs may shift through beta cycles.

### Expected Features

**Must have (table stakes -- omitting any causes immediate churn):**
- All Home Screen widget sizes (small, medium, large) with Lock Screen widgets as P1
- Live preview of widgets within the app before Home Screen placement
- Basic data sources: date/time, weather (WeatherKit), battery, calendar (EventKit), health/steps (HealthKit), reminders
- Font, color, and background customization (solid, gradient, photo)
- Widget gallery with save, edit, duplicate, delete, rename
- Onboarding flow teaching widget placement (the #1 support question for all widget apps)
- Correct WidgetKit timeline/refresh implementation
- Multiple distinct widget instances via AppIntentConfiguration

**Should have (differentiators -- these are why users choose Widgy):**
- AI conversational widget creation (THE primary differentiator -- no competitor offers this)
- Config-based JSON rendering engine (decouples AI from display, enables sharing and versioning)
- iOS 26 Liquid Glass integration (day-1 adoption creates competitive distance)
- Dynamic data bindings (`{{weather.temp}}`, `{{battery.level}}`) for live widget content
- Conversation history and widget version tracking
- Smart template suggestions based on user context
- StandBy mode optimization

**Defer (v2+):**
- Interactive widgets (App Intents buttons/toggles in widgets -- high complexity)
- Theme system / style tokens
- Community sharing and widget gallery
- Advanced data sources (stocks, sports, Spotify, smart home)
- Template gallery of pre-built designs

**Deliberately NOT building (anti-features):**
- Manual layer-based editor / drag-and-drop canvas (undermines AI-first value proposition)
- Icon packs, Home Screen themes, social feed, web editor, Android support

### Architecture Approach

The architecture is a two-target iOS project (main app + widget extension) sharing code through a local Swift Package (`WidgyCore`). The main app houses the chat UI, AI pipeline, config management, auth, and Supabase sync. The widget extension reads pre-cached JSON configs from an App Group shared container and renders them using the same SwiftUI renderer engine. Communication between targets is file-system based (App Group) with `WidgetCenter.shared.reloadTimelines` for reload signals. The system is local-first: widgets always work offline from cached configs, with Supabase providing cloud backup and cross-device sync.

**Major components:**
1. **WidgyCore (shared Swift Package):** WidgetConfig Codable model, SwiftUI NodeRenderer (recursive config interpreter), AppGroupManager, ConfigValidator, design tokens
2. **Main App (Widgy target):** Chat/prompt interface, AI Pipeline Manager (prompt building, Claude API calls, response parsing, retry logic, conversation state), Widget Config Store, Widget Gallery/Editor, Auth Manager (Supabase), Sync Service
3. **Widget Extension (WidgyWidgets target):** AppIntentTimelineProvider, SelectWidgetIntent for widget selection, JSON Config Reader from shared container, SwiftUI Renderer (same engine as main app)
4. **Supabase Backend:** Auth (Sign in with Apple), Postgres tables (profiles, widget_configs, generations, shared_widgets) with RLS, Storage for user images, Edge Functions as Claude API proxy with rate limiting and usage tracking
5. **AI Pipeline:** System prompt with schema + few-shot examples, structured output via Claude tool use, SSE streaming, validation + retry on invalid JSON (max 2 retries), conversation context for iterative refinement

### Critical Pitfalls

1. **App Store rejection for "remote code execution" (Guideline 2.5.2):** The JSON schema MUST remain strictly declarative -- layout and styling only, no logic, no expressions, no conditionals that resemble a scripting language. Document this explicitly in App Review notes. Prevention: keep all rendering logic in compiled Swift; JSON selects from a pre-built catalog of SwiftUI components.

2. **WidgetKit memory limit (~30MB) and limited SwiftUI view support:** Widget extensions silently show blank content when memory is exceeded. Only a strict subset of SwiftUI works in widgets (no ScrollView, List, NavigationStack, TextField, animations, gestures). Prevention: maintain an explicit allowlist of widget-compatible views in the schema, cap config complexity (max 5 nesting levels, 50 components), profile the extension separately in Instruments.

3. **AI cost spiral from unbounded token usage:** Prompts with full schema + conversation history can hit 10K-50K tokens per request. Without controls, this destroys margins. Prevention: set hard `max_tokens` limits (<2K output), route Haiku for simple edits / Sonnet for generation, use Anthropic prompt caching, implement generation caching for semantically similar requests, monitor per-user token usage.

4. **Schema versioning neglect:** The config schema will evolve. Without a `schema_version` field and migration logic from day one, app updates will break saved widgets. Prevention: version field in every config, forward-compatible renderers that ignore unknown fields, migration functions at config load time.

5. **iOS 26 beta API instability:** Liquid Glass and new WidgetKit APIs may change between betas. Prevention: abstract Liquid Glass-specific code behind a protocol layer, track every beta release note, do not ship until RC.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation and Schema
**Rationale:** Everything depends on the project structure, the JSON config schema, and the shared code package. The schema is the central contract -- locking it down first prevents cascading rework. This phase also establishes App Group communication, which is the only reliable method for passing data to widget extensions.
**Delivers:** Xcode project with both targets, WidgyCore shared package, finalized v1.0 JSON schema, Codable WidgetConfig model with schema versioning, App Group shared container setup with manifest
**Addresses:** Config JSON Rendering (2.2), Schema Versioning, Widget Size Support (1.1) at the model level
**Avoids:** Pitfall 1.1 (schema must be declarative-only), Pitfall 4.1 (versioning from day one), Pitfall 4.4 (data binding boundary set early), Pitfall 7.1 (App Group configured correctly from start)

### Phase 2: Renderer Engine
**Rationale:** The renderer must exist before any AI output can be visualized. Building it against hardcoded test configs enables rapid iteration without AI dependency. This also establishes the in-app preview capability.
**Delivers:** SwiftUI NodeRenderer for all v1 node types (Text, SFSymbol, Image, VStack, HStack, ZStack, Spacer, Divider, Gauge, Frame, Padding, ContainerRelativeShape), ConfigValidator, in-app preview chrome simulating Home Screen appearance, Liquid Glass material backgrounds
**Addresses:** Live Preview (1.2), Font/Color Customization (1.4), Background Customization (1.5), Liquid Glass Integration (2.3)
**Avoids:** Pitfall 2.3 (only widget-compatible SwiftUI views), Pitfall 2.2 (memory-conscious rendering), Pitfall 4.2 (validation before rendering)

### Phase 3: Widget Extension
**Rationale:** Depends on the renderer (Phase 2) and shared storage (Phase 1). This is the first "real widget on the Home Screen" moment -- the core proof of concept.
**Delivers:** AppIntentTimelineProvider, SelectWidgetIntent for multi-widget support, timeline reload integration from main app, working widgets on Home Screen from hardcoded configs
**Addresses:** Widget Refresh/Timeline (1.8), Multiple Instances (1.9), Widget Gallery (1.6) at basic level
**Avoids:** Pitfall 2.1 (correct timeline model from start), Pitfall 7.3 (extension lifecycle isolation), Pitfall 2.4 (family-specific rendering)

### Phase 4: AI Pipeline
**Rationale:** Can be built in parallel with Phases 2-3 but is listed here because end-to-end testing requires the renderer. This phase establishes the primary differentiator.
**Delivers:** System prompt engineering with schema reference and few-shot examples, Claude API integration via Supabase Edge Functions, SSE streaming to iOS, structured output via tool use, response parser with JSON extraction, retry logic for invalid responses (max 2), conversation manager for multi-turn refinement
**Addresses:** AI Conversational Creation (2.1), Conversation History (2.6)
**Avoids:** Pitfall 3.1 (token budgets and model routing), Pitfall 3.3 (exponential backoff with circuit breaker), Pitfall 3.4 (prompt injection via system prompt sandwiching), Pitfall 5.4 (streaming mitigates cold start perception)

### Phase 5: Main App UI
**Rationale:** The UI layer depends on the renderer for previews and the AI pipeline for generation. Building it after both are functional avoids throwaway work.
**Delivers:** Chat interface with Liquid Glass design, live preview alongside chat, widget gallery with save/edit/delete/duplicate, basic widget editor for manual tweaks, onboarding flow with guided first-widget creation and Home Screen placement tutorial
**Addresses:** Widget Gallery (1.6), Onboarding Flow (1.7), Live Preview (1.2) full integration
**Avoids:** Pitfall 1.2 (ensure template diversity for App Store review), Pitfall 7.2 (scope discipline -- chat + preview + gallery, nothing more)

### Phase 6: Auth, Cloud Sync, and Monetization
**Rationale:** The app is fully functional locally without cloud sync. Auth and sync add value but are not on the critical path for core functionality. Monetization (StoreKit 2 subscription) must be in place before AI generation costs accrue from real users.
**Delivers:** Supabase Auth with Sign in with Apple, database tables with RLS policies, widget config sync (local-first, last-write-wins), credit-based AI generation gating, StoreKit 2 subscription (Standard/Pro tiers), usage tracking per user
**Addresses:** Auth, credit-based monetization from PROJECT.md requirements
**Avoids:** Pitfall 1.4 (IAP required for AI features), Pitfall 5.1 (RLS from first table), Pitfall 5.5 (cost modeling informs tier pricing)

### Phase 7: Data Sources and Dynamic Bindings
**Rationale:** Adds the "live" quality to widgets -- weather, calendar, battery, etc. Requires careful integration with WidgetKit's timeline refresh model and the data binding expression system.
**Delivers:** Data source providers (WeatherKit, EventKit, HealthKit, battery, date/time, reminders), `{{placeholder}}` resolution in renderer, timeline-based refresh for dynamic widgets, permission request flows
**Addresses:** Basic Data Sources (1.3), Dynamic Data Bindings (2.7)
**Avoids:** Pitfall 4.4 (fixed enumerated data sources, not generic expressions), Pitfall 2.1 (realistic refresh intervals)

### Phase 8: Polish, Lock Screen, StandBy, and Launch
**Rationale:** Final polish pass targeting App Store submission. Lock Screen and StandBy widgets require separate rendering considerations (monochrome, high contrast) that should not complicate earlier phases.
**Delivers:** Lock Screen widget families (accessory), StandBy mode optimization, smart template suggestions, community sharing basics, comprehensive testing suite, App Store assets and review documentation
**Addresses:** Lock Screen widgets, StandBy Optimization (2.10), Smart Suggestions (2.4), Sharing/Community (2.5)
**Avoids:** Pitfall 1.3 (content moderation before launch), Pitfall 6.2 (Liquid Glass performance testing on lowest-end devices)

### Phase Ordering Rationale

- **Schema first, renderer second, AI third:** The dependency chain is clear -- the schema is the contract, the renderer interprets it, the AI produces it. Building in this order means each layer validates against the previous one.
- **Widget extension before AI pipeline:** Getting a real widget on the Home Screen early (even with hardcoded configs) proves the architecture works end-to-end and catches WidgetKit gotchas (memory limits, view support, App Group issues) before adding AI complexity.
- **Auth and monetization after core loop:** The core value proposition (describe a widget, see it rendered, place it on Home Screen) must work before adding infrastructure. But monetization must be in place before real users generate AI costs.
- **Data sources late:** Static widgets are valuable on their own. Dynamic data bindings add significant complexity (permissions, refresh budgets, expression resolution) that should not block the core creation flow.
- **Lock Screen and StandBy last:** These are separate rendering concerns (monochrome, high contrast) that add scope without advancing the core product. They are important for competitive parity but should not delay the primary Home Screen widget experience.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1 (Schema Design):** The schema expressiveness vs. AI reliability trade-off is the defining design challenge. Needs iterative prototyping and testing with Claude to find the sweet spot. Also needs careful review against Apple's Guideline 2.5.2 to ensure it remains declarative-only.
- **Phase 4 (AI Pipeline):** System prompt engineering requires significant iteration. Few-shot examples, schema-aware prompting, and structured output via tool use all need empirical tuning. Cost modeling per generation is essential.
- **Phase 7 (Data Sources):** Each iOS framework integration (WeatherKit, HealthKit, EventKit) has its own permission model, availability constraints, and data freshness characteristics. WidgetKit refresh budget management adds complexity.

Phases with standard patterns (skip research-phase):
- **Phase 2 (Renderer):** Recursive SwiftUI view builder from typed data is a well-established pattern. The component allowlist is documented in WidgetKit reference.
- **Phase 3 (Widget Extension):** AppIntentTimelineProvider, App Groups, and WidgetCenter are thoroughly documented by Apple with sample code.
- **Phase 6 (Auth and Sync):** Supabase Swift SDK, Sign in with Apple, and StoreKit 2 all have extensive documentation and established integration patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All technologies are production-ready with official documentation. supabase-swift 2.x, Swift 6, and WidgetKit are mature. Only risk: iOS 26 Liquid Glass APIs may shift in beta. |
| Features | HIGH | Feature landscape is well-understood from established competitors (WidgetSmith, original Widgy, Brass). Table stakes are clear. AI creation as differentiator is novel but technically feasible. |
| Architecture | HIGH | JSON-config-to-SwiftUI rendering, App Group widget communication, and Supabase backend are all established patterns. The architecture maps cleanly to WidgetKit's constraints. |
| Pitfalls | HIGH | Pitfalls are drawn from real iOS development experience, documented WidgetKit limitations, known App Store review patterns, and AI API cost realities. Phase mapping is actionable. |

**Overall confidence:** HIGH

### Gaps to Address

- **iOS 26 Liquid Glass API stability:** The `.glassEffect()` modifier and related APIs are new and may change between betas. Abstract behind a protocol layer and track beta releases. Verify behavior on device, not just simulator.
- **Schema sweet spot for AI reliability:** No amount of research can substitute for empirical testing of Claude's ability to generate valid widget configs within a given schema. Plan for 2-3 schema iterations during Phase 1 and Phase 4.
- **WidgetKit refresh budget in practice:** Documentation says 40-70 refreshes/day, but real-world behavior varies by device usage patterns and system load. Must test with production-like conditions.
- **Edge Function cold start latency:** Documented as 1-3 seconds. Combined with Claude API latency, total generation time could be 5-10+ seconds. Streaming SSE mitigates perceived latency, but UX design must account for this. Consider always-on alternative if cold starts prove unacceptable.
- **iOS 26 market size at launch:** Near-zero addressable market until fall 2026 adoption ramps. The decision to target iOS 26-only is deliberate (per PROJECT.md) but carries a slow-start revenue risk. Consider iOS 17+ with conditional Liquid Glass as a fallback plan if adoption is too slow.
- **Credit-based pricing sustainability:** Per-request token costs must map sustainably to credit pricing. Need actual generation cost data from Phase 4 to validate the $4.99/mo Standard and $9.99/mo Pro tiers against real Claude API costs.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation -- WidgetKit, SwiftUI, App Intents, App Groups, Liquid Glass APIs
- Anthropic Documentation -- Messages API, structured output, tool use, model pricing, prompt caching
- Supabase Documentation -- supabase-swift SDK 2.x, Auth, PostgREST, Edge Functions, RLS, Storage
- Swift Evolution proposals -- Swift 6 concurrency, Observation framework, Swift Testing

### Secondary (MEDIUM confidence)
- Competitive analysis of WidgetSmith, Color Widgets, original Widgy app, Brass -- feature sets and monetization models
- iOS App Store Review Guidelines (2.5.2, 3.1.1, 4.2.3, 5.6) -- interpretation based on known rejection patterns
- WWDC 2025 session content -- Liquid Glass and iOS 26 WidgetKit updates

### Tertiary (LOW confidence)
- iOS 26 beta API surface -- subject to change before GM release
- Widget extension memory limits (~30MB) -- empirically observed, not officially documented with precision
- WidgetKit refresh budget (40-70/day) -- varies by device and system conditions

---
*Research completed: 2026-02-23*
*Ready for roadmap: yes*
