# PITFALLS.md — Widgy: iOS AI-Powered Custom Widget Builder

> Research dimension: Common mistakes, gotchas, and failure modes specific to iOS AI widget builders with config-based JSON rendering, WidgetKit extensions, Supabase backend, Claude API, and iOS 26+ Liquid Glass targeting.

---

## Table of Contents

1. [App Store Review Pitfalls](#1-app-store-review-pitfalls)
2. [WidgetKit Limitations and Gotchas](#2-widgetkit-limitations-and-gotchas)
3. [AI Cost Management Mistakes](#3-ai-cost-management-mistakes)
4. [Config-Based Rendering Edge Cases](#4-config-based-rendering-edge-cases)
5. [Supabase Scaling Issues](#5-supabase-scaling-issues)
6. [iOS 26 / Liquid Glass Adoption Risks](#6-ios-26--liquid-glass-adoption-risks)
7. [Cross-Cutting Pitfalls](#7-cross-cutting-pitfalls)

---

## 1. App Store Review Pitfalls

### 1.1 Guideline 2.5.2 — Remote Code Execution Perception

**The Pitfall:** Apple prohibits apps that download or execute code. A config-based JSON rendering system that constructs UI dynamically from server-provided JSON can be flagged as "remote code execution" if the JSON schema is too expressive (e.g., contains logic expressions, conditional branching, or anything that resembles a scripting language).

**Warning Signs:**
- JSON configs include `if/else` conditions, loops, or expression evaluation
- Reviewer notes mention "downloaded executable code" or "interpreted code"
- Config schema allows arbitrary function-like constructs

**Prevention Strategy:**
- Keep the JSON schema declarative-only: layout, styling, static data bindings. No logic, no expressions, no computed values in the JSON itself
- All rendering logic must live in the compiled Swift code; JSON only selects from a pre-built set of SwiftUI components and layouts
- Document the schema explicitly in App Review notes: "Widget configurations are declarative layout descriptions similar to Interface Builder XIBs, not executable code"
- Pre-build a finite catalog of widget component types; JSON merely composes them

**Phase:** Foundation (Phase 1) — schema design must be locked before building the renderer

---

### 1.2 Guideline 4.2.3 — Minimum Functionality / Template Apps

**The Pitfall:** If the AI generates widgets that all look essentially the same (minor text/color variations), Apple may reject for "template app" or "minimum functionality." Widget customization apps have been historically scrutinized here.

**Warning Signs:**
- Generated widgets are visually monotonous across different prompts
- App offers no meaningful differentiation from existing widget apps
- Users report "all widgets look the same"

**Prevention Strategy:**
- Ensure the config schema supports genuinely diverse layouts: grids, stacks, overlays, mixed media, charts, countdowns, progress indicators
- Ship with a rich set of built-in templates that demonstrate range
- The AI generation pipeline should produce varied visual outputs — test with prompt diversity benchmarks
- Include manual customization controls beyond AI generation so the app has standalone utility

**Phase:** Phase 1-2 — template diversity and manual editing should be core from the start

---

### 1.3 Guideline 5.6 — Developer Code of Conduct (AI-Generated Content)

**The Pitfall:** Apple requires that AI features must not generate harmful, misleading, or inappropriate content. Widget content is visible on the home screen — more visible than in-app content — which raises the bar.

**Warning Signs:**
- No content filtering on AI-generated text/image descriptions
- Users can create widgets displaying offensive text visible on lock screen
- AI generates medical, financial, or legal content claims in widget text

**Prevention Strategy:**
- Implement a content moderation layer between Claude's output and the config renderer
- Use Claude's system prompt to constrain outputs to widget-appropriate content
- Maintain a blocklist for prohibited content categories
- Add a reporting mechanism for community-shared widget configs

**Phase:** Phase 2 — must be in place before AI generation goes live

---

### 1.4 Guideline 3.1.1 — In-App Purchase for AI Features

**The Pitfall:** If AI widget generation consumes server-side resources (Claude API calls), Apple requires this to be gated behind IAP, not external payment. Apps have been rejected for directing users to external payment for AI features.

**Warning Signs:**
- Free tier offers unlimited AI generations (unsustainable)
- Payment links go to Stripe/web checkout instead of IAP
- No clear delineation between free features and AI-premium features

**Prevention Strategy:**
- Gate AI generation behind a StoreKit 2 subscription from day one
- Offer a limited free tier (e.g., 5 generations/day) without external payment
- Never reference external pricing or payment methods in the app

**Phase:** Phase 1 — monetization architecture should be designed alongside the AI pipeline

---

## 2. WidgetKit Limitations and Gotchas

### 2.1 Timeline-Based Rendering Only

**The Pitfall:** WidgetKit does not support real-time updates. Widgets render from a timeline of snapshots. Developers commonly build features assuming they can push updates to widgets on demand, then discover the system throttles or ignores reload requests.

**Warning Signs:**
- Design specs show "live updating" widgets (stock tickers, real-time counters)
- `WidgetCenter.shared.reloadAllTimelines()` called excessively (system will throttle after ~30-70 reloads/day)
- Users report widgets showing stale data

**Prevention Strategy:**
- Design all widgets as periodic-snapshot displays, not live views
- Use `TimelineReloadPolicy.atEnd` or `.after(date)` with realistic intervals (minimum 15 minutes)
- For time-sensitive widgets, use `relevanceScore` to hint to the system, but do not depend on guaranteed timing
- Clearly communicate update frequency expectations to users in the UI

**Phase:** Phase 1 — widget update model is a foundational architecture decision

---

### 2.2 30MB Memory Limit

**The Pitfall:** Widget extensions have a hard ~30MB memory ceiling. Config-based rendering with image assets, decoded JSON, and SwiftUI view hierarchies can exceed this silently, causing the widget to display a blank/placeholder state with no crash log.

**Warning Signs:**
- Widgets intermittently show blank/placeholder content
- Configs referencing multiple high-resolution images
- Complex nested JSON configs producing deep view hierarchies
- No memory profiling on the widget extension target

**Prevention Strategy:**
- Profile the widget extension separately in Instruments (not just the main app)
- Limit image sizes in configs (enforce max dimensions, e.g., 400x400, and use compressed formats)
- Cap JSON config depth/complexity with validation before rendering
- Implement a fallback "simplified" rendering mode when configs are complex
- Use `ImageRenderer` to pre-render complex layouts as a single image when they exceed component count thresholds

**Phase:** Phase 2 — must be addressed when the renderer handles user-generated configs

---

### 2.3 Limited SwiftUI View Support

**The Pitfall:** WidgetKit supports a strict subset of SwiftUI. Common views like `ScrollView`, `List`, `NavigationStack`, `TextField`, animations, and custom gesture handlers are all unsupported. Developers build a JSON schema that maps to full SwiftUI, then discover half the components crash or silently fail in the widget extension.

**Warning Signs:**
- Config schema includes unsupported view types
- Widget preview works in Xcode canvas but fails on device
- No separate validation of configs against widget-compatible components

**Prevention Strategy:**
- Maintain an explicit allowlist of WidgetKit-compatible SwiftUI views: `Text`, `Image`, `VStack`, `HStack`, `ZStack`, `Spacer`, `Link`, `Gauge`, `ProgressView`, `ContainerRelativeShape`, `Canvas`
- The JSON schema should only expose these components — reject configs containing unsupported views at the validation layer
- Test every component type in actual widget extension on device, not just SwiftUI previews

**Phase:** Phase 1 — the renderer's component catalog must be widget-compatible from the start

---

### 2.4 Widget Size and Family Handling

**The Pitfall:** Developers build for `.systemSmall` and assume configs scale to `.systemMedium`, `.systemLarge`, `.systemExtraLarge`, `.accessoryCircular`, `.accessoryRectangular`, and `.accessoryInline` (Lock Screen). Each family has different dimensions, padding, and content expectations. A single config that "works everywhere" is a myth.

**Warning Signs:**
- Single-config approach with no family-specific adaptations
- Text truncation on small widgets, wasted space on large ones
- Lock Screen widgets rendering full-color content (they're monochrome)

**Prevention Strategy:**
- Require configs to specify per-family layouts or use a responsive layout system with family-aware breakpoints
- Have the AI generate family-specific variants for each widget
- Lock Screen accessory widgets need a completely separate rendering path (monochrome, minimal)
- Test all supported families in the preview and on device for every config change

**Phase:** Phase 1-2 — architecture must support multi-family from the schema level

---

### 2.5 App Intent / Interactive Widget Pitfalls (iOS 17+)

**The Pitfall:** Interactive widgets (buttons, toggles via App Intents) are powerful but introduce a separate lifecycle. The intent handler runs in the widget extension process, not the main app. Shared state via App Groups must be carefully managed. Many developers hit crashes because the intent tries to access main-app-only dependencies.

**Warning Signs:**
- Interactive widget actions silently fail
- Shared UserDefaults or CoreData not configured with App Group
- Intent handler imports main app modules that have unavailable dependencies in the extension

**Prevention Strategy:**
- Keep intent handlers minimal — update shared state only, trigger timeline reload
- Use App Group shared container for all widget/app communication
- Factor shared models into a framework target imported by both app and extension
- Test interactive widgets independently from the main app

**Phase:** Phase 2-3 — after core rendering is stable

---

## 3. AI Cost Management Mistakes

### 3.1 Unbounded Token Usage per Generation

**The Pitfall:** Claude API costs scale with token usage. A widget config generation prompt that includes the full schema, examples, user preferences, and conversation history can easily consume 10K-50K tokens per request. At scale, this destroys margins.

**Warning Signs:**
- Average generation cost exceeds $0.05-0.10 per widget created
- Prompts grow over time as schema evolves without pruning
- No monitoring of per-request token counts
- System prompt includes the entire JSON schema with all documentation

**Prevention Strategy:**
- Set hard `max_tokens` limits on Claude API calls (widget configs should need <2K output tokens)
- Use Claude Haiku for simple modifications/variations, Sonnet for complex generation, Opus only for edge cases — model routing based on prompt complexity
- Cache and reuse system prompts; use prompt caching (Anthropic supports this) to reduce input token costs
- Strip unnecessary schema documentation from prompts — provide only the subset relevant to the requested widget type
- Monitor per-user and aggregate token usage with alerts at thresholds

**Phase:** Phase 2 — implement cost controls before opening AI generation to users

---

### 3.2 No Generation Caching / Deduplication

**The Pitfall:** Users will request similar widgets repeatedly ("show me a weather widget" "make me a weather widget" "weather widget please"). Without caching, each request hits Claude at full cost.

**Warning Signs:**
- High API costs with low unique-config diversity
- Same semantic requests generating different JSON each time (inconsistent UX too)
- No cache hit rate metrics

**Prevention Strategy:**
- Implement semantic similarity matching on prompts — return cached configs for near-duplicate requests
- Store generated configs in Supabase with prompt embeddings for similarity search
- Offer a "template gallery" of pre-generated popular widget types to reduce AI calls
- Use a two-tier system: check template match first, then generate only if no match

**Phase:** Phase 2-3 — after the generation pipeline is stable

---

### 3.3 Retry Storm on API Failures

**The Pitfall:** When Claude API returns errors (rate limits, overload, network timeout), naive retry logic can amplify costs and create cascading failures. Each retry consumes tokens if the request partially processed.

**Warning Signs:**
- Exponential cost spikes correlating with API degradation events
- No circuit breaker pattern in the API client
- Users see "generation failed" after long waits followed by duplicate results

**Prevention Strategy:**
- Implement exponential backoff with jitter and a maximum of 3 retries
- Use a circuit breaker: after N consecutive failures, stop attempting for a cooldown period
- Show users a clear "try again later" state rather than silently retrying
- Queue failed requests for background retry rather than blocking the UI
- Set request timeouts at 30 seconds — widget configs should generate fast

**Phase:** Phase 2 — must be in place before production AI traffic

---

### 3.4 Prompt Injection via User Input

**The Pitfall:** Users provide natural language descriptions for widget generation. Without sanitization, adversarial prompts can manipulate Claude into generating invalid configs, exhausting tokens on long outputs, or producing inappropriate content.

**Warning Signs:**
- Users report "weird" widget generation results
- Anomalously long API responses for simple requests
- Generated configs contain unexpected fields or content

**Prevention Strategy:**
- Sandwich user input between strong system prompts that constrain output format
- Validate Claude's JSON output against the schema before rendering — reject malformed configs
- Set hard `max_tokens` ceiling to prevent runaway generation
- Log and review anomalous generation patterns

**Phase:** Phase 2 — implement alongside the AI pipeline

---

## 4. Config-Based Rendering Edge Cases

### 4.1 Schema Versioning and Migration

**The Pitfall:** The JSON config schema will evolve (new components, changed properties, deprecated fields). Widgets saved with schema v1 must still render when the app ships schema v3. Without versioning, old widgets break silently.

**Warning Signs:**
- No `schemaVersion` field in config JSON
- App updates cause previously-working widgets to render incorrectly
- No migration path for stored configs
- Database full of configs with no version metadata

**Prevention Strategy:**
- Include a `schemaVersion` integer in every config from day one
- Write forward-compatible renderers that handle unknown fields gracefully (ignore, don't crash)
- Implement migration functions: `migrateV1toV2()`, `migrateV2toV3()` — run at config load time
- Never delete fields from the schema — deprecate and ignore them
- Store the original prompt alongside the config so users can re-generate with the new schema

**Phase:** Phase 1 — schema versioning must be in the first config format

---

### 4.2 Malformed or Adversarial Configs

**The Pitfall:** User-generated or AI-generated configs may be malformed: deeply nested structures, excessively large text strings, missing required fields, or referencing non-existent assets. Without validation, the renderer crashes or produces undefined behavior.

**Warning Signs:**
- Widget extension crashes with no visible error
- Blank widgets after applying certain configs
- No JSON Schema validation step in the rendering pipeline

**Prevention Strategy:**
- Define a formal JSON Schema (draft 2020-12) for widget configs and validate every config at ingestion
- Set hard limits: max nesting depth (5 levels), max text length (500 chars), max components per widget (50), max image count (4)
- Implement a `SafeRenderer` wrapper that catches rendering errors and shows a fallback "error widget" instead of blank/crash
- Fuzz test the renderer with randomized malformed configs

**Phase:** Phase 1-2 — validation layer is critical before accepting any user/AI-generated configs

---

### 4.3 Asset Reference Resolution

**The Pitfall:** Configs may reference images, icons, or fonts. If these are URLs, the widget extension must download them within its limited runtime and memory. If they're local asset names, they must exist in the extension's asset catalog. Broken references cause blank spaces or crashes.

**Warning Signs:**
- Widgets show broken image placeholders
- Widget extension times out trying to download remote images
- Asset catalog in the widget extension target is empty (assets only in the main app)

**Prevention Strategy:**
- Pre-download and cache all referenced images in the main app; pass them to the widget via App Group shared container
- For remote images, use a `URLSession` background download in the main app, never in the widget extension
- Config validation should verify all asset references resolve before the config is activated
- Ship a set of bundled default images/icons in the widget extension target for fallback

**Phase:** Phase 2 — asset pipeline must be designed for the widget extension's constraints

---

### 4.4 Dynamic Data Binding Complexity Creep

**The Pitfall:** Config-based rendering starts simple (static text, colors, images) but requirements grow: "show the current date," "show battery level," "show step count from HealthKit." Each data source adds binding complexity, and the JSON schema balloons into an ad-hoc programming language — which then triggers App Store review concerns (see Pitfall 1.1).

**Warning Signs:**
- JSON schema includes `dataSource`, `binding`, `expression` fields
- Requests for "just one more data source" keep arriving
- Schema documentation grows faster than app features

**Prevention Strategy:**
- Define a fixed, enumerated set of data sources (date, weather, battery, health, calendar) as first-class widget types, not generic bindings
- Each data source has a dedicated, compiled Swift provider — not a generic evaluator
- Resist the urge to make the schema "programmable" — constraints are a feature for App Store compliance
- Document the boundary clearly: "The config describes layout and style. Data comes from built-in providers."

**Phase:** Phase 1 — this architectural boundary must be set early

---

## 5. Supabase Scaling Issues

### 5.1 Row-Level Security (RLS) Misconfiguration

**The Pitfall:** Supabase RLS is powerful but easy to misconfigure. A missing policy means either users can see everyone's widget configs (data leak) or no one can access anything (broken app). The most common mistake: forgetting to enable RLS on new tables.

**Warning Signs:**
- New tables created without RLS enabled
- Users report seeing other users' widgets
- API calls return empty results despite data existing (overly restrictive policies)
- No automated RLS policy tests

**Prevention Strategy:**
- Enable RLS on every table immediately upon creation — make this a checklist item
- Write and run automated tests that verify: user A cannot read user B's data, user A can read their own data
- Use Supabase's SQL editor to audit all table policies monthly
- Create a base migration template that includes RLS enablement

**Phase:** Phase 1 — RLS must be configured from the first database table

---

### 5.2 Realtime Subscription Overuse

**The Pitfall:** Supabase Realtime is convenient but each subscription consumes a connection slot. Widget config syncing doesn't need real-time updates — widgets already operate on a timeline-based update model. Using Realtime for config sync wastes connections and inflates costs.

**Warning Signs:**
- High Realtime connection counts relative to active users
- Supabase dashboard shows connection limit warnings
- Widget configs don't need sub-second sync latency

**Prevention Strategy:**
- Use standard REST/PostgREST queries for config CRUD — no Realtime subscriptions for widget data
- Reserve Realtime only for features that genuinely need it (e.g., collaborative editing if ever added)
- Implement a polling-based sync with reasonable intervals (5-15 minutes) for config updates across devices
- Monitor connection counts in Supabase dashboard

**Phase:** Phase 1-2 — choose the right data sync pattern from the start

---

### 5.3 Storage Bucket Costs for Widget Assets

**The Pitfall:** If users upload custom images for widgets, Supabase Storage costs can grow unpredictably. A single user uploading 10MB of images per widget, times thousands of users, equals significant storage and bandwidth costs.

**Warning Signs:**
- No per-user storage quota
- No image compression/resizing on upload
- Storage costs growing faster than user base
- Large images being served to widget extensions unnecessarily

**Prevention Strategy:**
- Enforce image size limits on upload (max 1MB per image, max 5 images per widget)
- Resize and compress images server-side using a Supabase Edge Function before storage
- Implement per-user storage quotas tied to subscription tier
- Use CDN caching for frequently accessed widget assets
- Clean up orphaned assets (images no longer referenced by any config) on a weekly cron

**Phase:** Phase 2-3 — implement when user image uploads are added

---

### 5.4 Edge Function Cold Starts for AI Proxy

**The Pitfall:** If Claude API calls are proxied through Supabase Edge Functions (to keep the API key server-side), cold starts add 1-3 seconds of latency on top of Claude's generation time. Users experience 5-10 second waits for widget generation.

**Warning Signs:**
- First generation after idle period is noticeably slower
- P95 latency for generation is 3x+ the P50
- Users abandon the generation flow due to perceived slowness

**Prevention Strategy:**
- Use a warm-up strategy: ping the Edge Function periodically to keep instances warm
- Show an engaging loading animation during generation (skeleton widget, shimmer effect)
- Consider using a dedicated backend (e.g., a small always-on server) for the AI proxy if cold starts become a significant UX issue
- Implement streaming responses from Claude through the Edge Function to show progressive results

**Phase:** Phase 2 — optimize once the AI pipeline is functional

---

### 5.5 Free Tier Limitations at Scale

**The Pitfall:** Supabase free tier has hard limits: 500MB database, 1GB storage, 2GB bandwidth, 500K Edge Function invocations/month. An AI widget app with moderate traction will hit these within weeks, and the jump to Pro ($25/mo) is just the start.

**Warning Signs:**
- Approaching any free tier limit without a paid plan in place
- No cost projections based on user growth models
- Database size growing due to storing full JSON configs plus generation history

**Prevention Strategy:**
- Start on Supabase Pro from launch if expecting any real user base
- Model costs per user: estimate DB rows per user, storage per user, Edge Function calls per user
- Implement config pruning: limit generation history to last 50 per user, archive or delete old configs
- Set up Supabase billing alerts at 50%, 75%, and 90% of plan limits

**Phase:** Phase 1 — cost modeling should inform the architecture

---

## 6. iOS 26 / Liquid Glass Adoption Risks

### 6.1 iOS 26 Beta Instability

**The Pitfall:** Building exclusively for iOS 26+ (announced WWDC 2025) means developing against beta APIs that may change or be removed. Apple commonly modifies or deprecates APIs between beta 1 and GM. Liquid Glass APIs in particular are brand new and subject to revision.

**Warning Signs:**
- Code compiles on beta 2 but breaks on beta 3
- Liquid Glass API signatures change between Xcode betas
- No fallback path for API changes

**Prevention Strategy:**
- Abstract all Liquid Glass-specific code behind a protocol/interface layer so implementations can be swapped
- Track Apple Developer Forums and release notes for every beta
- Maintain compatibility with the beta version from WWDC and be prepared to refactor
- Do not ship to the App Store until iOS 26 reaches RC (Release Candidate) status
- Consider supporting iOS 17+ as a minimum with Liquid Glass as a progressive enhancement on iOS 26

**Phase:** Phase 1 — abstraction layer should be part of the architecture from the start

---

### 6.2 Liquid Glass Material Rendering Performance

**The Pitfall:** Liquid Glass is a computationally expensive material effect (real-time blur, refraction, dynamic tinting). Widgets with complex layouts rendered through Liquid Glass may stutter or consume excessive energy, especially on older devices that support iOS 26 (likely iPhone 15 and newer only).

**Warning Signs:**
- Widget rendering takes >16ms (below 60fps) in Instruments
- Battery drain complaints from users with Liquid Glass widgets
- Widgets flicker or show rendering artifacts on lower-end supported devices

**Prevention Strategy:**
- Profile Liquid Glass rendering in the widget extension using Instruments' GPU profiler
- Limit Liquid Glass application to container backgrounds, not every individual component
- Provide a non-Liquid-Glass fallback style for performance-sensitive scenarios
- Test on the lowest-end device that supports iOS 26, not just the latest iPhone

**Phase:** Phase 2-3 — performance optimization after core rendering works

---

### 6.3 Tiny Initial User Base

**The Pitfall:** iOS 26 will have near-zero market share at launch (historically, the latest iOS version reaches ~50% adoption after 3-4 months). An iOS 26-only app launches to a tiny addressable market.

**Warning Signs:**
- Post-launch user acquisition is near zero
- App Store Optimization (ASO) shows low impressions because most users can't install
- Revenue projections assumed broader market

**Prevention Strategy:**
- Consider iOS 17+ as the deployment target with Liquid Glass as a conditional enhancement (`if #available(iOS 26, *)`)
- If iOS 26-only is a deliberate bet, plan for a slow initial ramp and set expectations accordingly
- Time the marketing push to coincide with iOS 26 public release (typically September) rather than WWDC
- Use the beta period for development and testing, not growth

**Phase:** Phase 1 — deployment target decision is a foundational choice

---

### 6.4 WidgetKit API Changes in iOS 26

**The Pitfall:** iOS 26 may introduce new WidgetKit capabilities (new families, new interaction models, revised timeline APIs) that change best practices. Building on iOS 25 WidgetKit patterns may mean missing iOS 26-specific features, or worse, using deprecated patterns.

**Warning Signs:**
- WWDC sessions announce new WidgetKit APIs not reflected in the app's architecture
- Competitor apps adopt iOS 26 widget features first
- App uses deprecated WidgetKit patterns flagged in Xcode warnings

**Prevention Strategy:**
- Watch all WWDC 2025 WidgetKit and SwiftUI sessions immediately and revise the architecture plan
- Build the renderer's component system to be extensible — new widget capabilities should be additive, not requiring rewrites
- Assign time in each phase to incorporate new platform capabilities as betas reveal them

**Phase:** Phase 1 — watch sessions and adapt architecture before building

---

## 7. Cross-Cutting Pitfalls

### 7.1 App Group Configuration Errors

**The Pitfall:** The main app and widget extension communicate via App Groups. Misconfigured App Group entitlements (different group ID, missing from one target, not enabled in provisioning profile) cause silent data sharing failures — the widget shows default/empty content while the app works perfectly.

**Warning Signs:**
- Widget always shows placeholder content after initial configuration
- App Group identifier mismatch between app and extension targets
- Works in simulator but fails on device (provisioning profile issue)

**Prevention Strategy:**
- Use a single, explicitly named App Group (e.g., `group.com.widgy.shared`)
- Verify the App Group is enabled in both targets' entitlements AND in the Apple Developer Portal provisioning profiles
- Write an integration test that writes from the app and reads from the extension
- Add a debug screen that shows the App Group shared container contents

**Phase:** Phase 1 — configure correctly from the first widget build

---

### 7.2 Overengineering the MVP

**The Pitfall:** The combination of AI, WidgetKit, Supabase, config rendering, and Liquid Glass is already complex. Adding social features, community sharing, analytics dashboards, or multi-platform support before the core widget creation flow works is a common death trap for side projects.

**Warning Signs:**
- Phase 1 scope includes features beyond "create a widget with AI and display it"
- More backend tables than UI screens
- Three months in with no working widget on the home screen

**Prevention Strategy:**
- Phase 1 deliverable: a user can describe a widget, AI generates a config, the config renders as an actual widget on the home screen. Full stop.
- Defer community sharing, advanced analytics, collaborative editing, and iPad/Mac support to Phase 3+
- Use the "working software" test: at the end of each phase, can you demo the app to someone?

**Phase:** All phases — scope discipline is continuous

---

### 7.3 Extension Lifecycle Misunderstanding

**The Pitfall:** The widget extension is a separate process with an independent lifecycle. It does not share memory, network sessions, or authentication state with the main app. Developers frequently assume `URLSession` cookies, Keychain access, or Supabase auth tokens are automatically available in the extension.

**Warning Signs:**
- Widget fails to fetch data (no auth token in extension)
- Keychain items not accessible from the extension (missing Keychain access group)
- Network requests from the extension fail silently

**Prevention Strategy:**
- Share auth tokens via App Group `UserDefaults` or shared Keychain access group
- Design the extension to be self-sufficient: it should be able to render from locally cached configs without network access
- Never assume the main app is running when the widget extension executes
- Test the extension independently (kill the main app, reboot device, verify widget still renders)

**Phase:** Phase 1-2 — extension architecture must account for isolation

---

### 7.4 Testing Gaps Due to Extension Complexity

**The Pitfall:** Widget extensions are notoriously hard to test. Xcode previews don't fully replicate on-device behavior. Timeline providers can't be easily unit tested. The combination of AI generation + config parsing + widget rendering across two targets creates a wide surface area with many testing gaps.

**Warning Signs:**
- No unit tests for the config parser/validator
- Widget testing is entirely manual ("deploy to device and look at it")
- AI-generated configs are only tested with AI-generated prompts (no adversarial/edge case testing)

**Prevention Strategy:**
- Unit test the JSON config parser and validator exhaustively — these are pure functions, easy to test
- Build a "Widget Preview" screen in the main app that renders configs using the same renderer, enabling faster visual iteration
- Create a config test suite: 20+ curated configs covering all component types, edge cases, and previously-failed configs
- Snapshot test rendered widgets using `ImageRenderer` or SwiftUI preview snapshots

**Phase:** Phase 1-2 — testing infrastructure should be built alongside the renderer

---

## Summary: Phase-Mapped Pitfall Priority

| Phase | Critical Pitfalls to Address |
|-------|------------------------------|
| **Phase 1 (Foundation)** | 1.1 (schema design), 2.1 (timeline model), 2.3 (component allowlist), 4.1 (schema versioning), 4.4 (data binding boundary), 5.1 (RLS), 6.1 (iOS 26 abstraction), 6.3 (deployment target), 7.1 (App Groups), 7.2 (scope discipline) |
| **Phase 2 (AI Integration)** | 1.2 (template diversity), 1.3 (content moderation), 1.4 (IAP), 2.2 (memory limits), 3.1 (token management), 3.3 (retry logic), 3.4 (prompt injection), 4.2 (config validation), 4.3 (asset references), 5.4 (cold starts), 7.3 (extension lifecycle), 7.4 (testing) |
| **Phase 3 (Scale)** | 2.4 (all widget families), 2.5 (interactive widgets), 3.2 (generation caching), 5.2 (Realtime usage), 5.3 (storage costs), 5.5 (tier limits), 6.2 (Liquid Glass perf), 6.4 (new WidgetKit APIs) |

---

*Research completed: 2026-02-23. Based on domain expertise in iOS development, WidgetKit, App Store review processes, Anthropic Claude API, Supabase platform, and iOS 26 beta program.*
