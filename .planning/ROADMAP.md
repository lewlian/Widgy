# Roadmap: Widgy

## Overview

Widgy delivers AI-powered widget creation for iOS 26+ through 8 phases that follow the natural dependency chain: the JSON schema is the central contract, the renderer interprets it, the widget extension displays it on the homescreen, the AI pipeline produces it, the app UI ties it together, auth and monetization gate AI costs, data sources make widgets dynamic, and lockscreen support completes the surface area. Each phase delivers a working, demonstrable capability that builds on the previous one. The core loop -- describe a widget, see it rendered, place it on your homescreen -- is functional by the end of Phase 5.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Schema and Foundation** - Xcode project structure, WidgyCore shared package, v1.0 JSON widget config schema with versioning
- [ ] **Phase 2: Renderer Engine** - SwiftUI renderer that interprets JSON configs into widget views with Liquid Glass styling and live preview
- [ ] **Phase 3: Widget Extension** - Working homescreen widgets rendered from JSON configs via App Group shared container
- [ ] **Phase 4: AI Pipeline** - Claude-powered widget generation via Supabase Edge Functions with streaming, validation, and conversation context
- [ ] **Phase 5: Main App UI** - Chat interface, live preview integration, widget gallery, and conversation history
- [ ] **Phase 6: Auth and Monetization** - Sign in with Apple, credit-based subscription tiers, usage tracking, and server-side configuration
- [ ] **Phase 7: Data Sources and Bindings** - iOS-native data providers (weather, calendar, health, battery, etc.) with dynamic data resolution in widgets
- [ ] **Phase 8: Lockscreen Widgets and Launch Polish** - Lockscreen widget families, StandBy optimization, onboarding flow, and App Store preparation

## Phase Details

### Phase 1: Schema and Foundation
**Goal**: Establish the project structure and the JSON config schema that serves as the contract between the AI, the renderer, and the persistence layer
**Depends on**: Nothing (first phase)
**Requirements**: SCHEMA-01
**Success Criteria** (what must be TRUE):
  1. Xcode project builds with main app target, widget extension target, and WidgyCore local Swift Package all compiling cleanly
  2. A sample widget JSON config can be decoded into typed Swift structs (WidgetConfig) and re-encoded without data loss
  3. The schema supports all v1 layout primitives (VStack, HStack, ZStack, Text, SFSymbol, Image, Spacer, Divider, Gauge, Frame, Padding, ContainerRelativeShape) with styling properties (colors, gradients, fonts, corner radius)
  4. Every config includes a schema_version field and a migration function scaffold exists for future version upgrades
  5. App Group shared container is configured and both targets can read/write JSON files to it
**Plans**: TBD

Plans:
- [ ] 01-01: Xcode project setup with both targets and WidgyCore Swift Package
- [ ] 01-02: JSON widget config schema definition and Codable model implementation
- [ ] 01-03: App Group shared container and AppGroupManager

### Phase 2: Renderer Engine
**Goal**: Users can see any valid JSON widget config rendered as a native SwiftUI view with Liquid Glass styling at actual widget dimensions
**Depends on**: Phase 1
**Requirements**: REND-01, REND-02, VALID-02, PLATFORM-01
**Success Criteria** (what must be TRUE):
  1. A recursive NodeRenderer can render all v1 node types (Text, SFSymbol, Image, VStack, HStack, ZStack, Spacer, Divider, Gauge, Frame, Padding, ContainerRelativeShape) from a WidgetConfig
  2. Rendered previews display at actual widget dimensions for systemSmall, systemMedium, and systemLarge sizes with mock homescreen chrome
  3. Unknown or invalid config properties are handled gracefully (ignored with fallback, never crash)
  4. Liquid Glass material backgrounds and vibrancy modifiers are applied to widget containers
  5. A ConfigValidator rejects malformed configs with descriptive errors before rendering
**Plans**: TBD

Plans:
- [ ] 02-01: NodeRenderer implementation for all v1 node types
- [ ] 02-02: ConfigValidator, preview chrome, and Liquid Glass integration

### Phase 3: Widget Extension
**Goal**: Users can see a real widget on their iOS homescreen, rendered from a JSON config stored in the App Group shared container
**Depends on**: Phase 1, Phase 2
**Requirements**: WIDG-01, OFFLINE-01
**Success Criteria** (what must be TRUE):
  1. An AppIntentTimelineProvider reads widget configs from the App Group shared container and renders them as homescreen widgets
  2. Users can place multiple distinct widgets on their homescreen, each displaying a different saved config selected via SelectWidgetIntent
  3. Widgets render correctly in systemSmall, systemMedium, and systemLarge families
  4. Widgets continue to display their last rendered content when the device is offline or the main app is not running
  5. When the main app saves or updates a config, WidgetCenter.reloadTimelines triggers and the homescreen widget updates
**Plans**: TBD

Plans:
- [ ] 03-01: AppIntentTimelineProvider, SelectWidgetIntent, and timeline reload integration

### Phase 4: AI Pipeline
**Goal**: Users can describe a widget in natural language and receive a valid, renderable JSON config generated by Claude AI
**Depends on**: Phase 1 (schema), Phase 2 (renderer for validation testing)
**Requirements**: CHAT-01, CHAT-02, VALID-01
**Success Criteria** (what must be TRUE):
  1. A Supabase Edge Function proxies requests to the Claude API with the API key never exposed to the client
  2. The system prompt includes the full widget schema reference and few-shot examples, and Claude generates valid WidgetConfig JSON via structured output (tool use)
  3. Responses stream via SSE from the Edge Function to the iOS app, showing progressive generation
  4. Invalid JSON responses trigger automatic retry with error context (max 2 retries) before surfacing failure to the user
  5. Multi-turn conversation context is maintained so follow-up messages like "make the font bigger" or "change the color to blue" produce targeted edits to the existing config
**Plans**: TBD

Plans:
- [ ] 04-01: Supabase Edge Function as Claude API proxy with SSE streaming
- [ ] 04-02: System prompt engineering, structured output, response parsing, and retry logic
- [ ] 04-03: Conversation manager for multi-turn refinement

### Phase 5: Main App UI
**Goal**: Users can create widgets through a conversational chat interface, see live previews, and manage their saved widgets in a gallery
**Depends on**: Phase 2 (renderer), Phase 4 (AI pipeline)
**Requirements**: MGMT-01, MGMT-02
**Success Criteria** (what must be TRUE):
  1. User can type a widget description in a chat interface styled with Liquid Glass and see the AI-generated widget rendered as a live preview alongside the conversation
  2. User can save a generated widget, and it appears in a gallery view with thumbnail previews
  3. User can edit, delete, duplicate, and rename saved widgets from the gallery
  4. User can browse conversation history and tap into any past conversation to continue iterating on that widget
  5. Saving a widget from the chat automatically writes the config to the App Group container and triggers homescreen widget refresh
**Plans**: TBD

Plans:
- [ ] 05-01: Chat interface with live preview integration
- [ ] 05-02: Widget gallery with save, edit, delete, duplicate, rename
- [ ] 05-03: Conversation history and project archives

### Phase 6: Auth and Monetization
**Goal**: Users authenticate with Sign in with Apple and AI generation is gated behind a credit-based subscription model with server-side configuration
**Depends on**: Phase 4 (AI pipeline), Phase 5 (app UI)
**Requirements**: AUTH-01, MONET-01, MONET-02, MONET-03, MONET-04
**Success Criteria** (what must be TRUE):
  1. User can sign in with Apple and their identity persists across app launches via Supabase Auth
  2. Free users receive 3 one-time credits and are prompted to subscribe when exhausted
  3. Standard ($4.99/mo) and Pro ($9.99/mo) subscribers receive their allocated monthly credits via StoreKit 2 subscription verification
  4. Every AI generation request logs token consumption (user ID, project ID, session timestamp, input/output tokens) to the Supabase database
  5. Credit thresholds, tier limits, and feature flags are configurable server-side without an app update, and minor edits below a configurable token threshold consume fractional or zero credits
**Plans**: TBD

Plans:
- [ ] 06-01: Supabase Auth with Sign in with Apple and RLS policies
- [ ] 06-02: StoreKit 2 subscriptions and credit-based generation gating
- [ ] 06-03: Token consumption logging and server-side configurable thresholds

### Phase 7: Data Sources and Bindings
**Goal**: Widgets display live, updating data from iOS-native sources (weather, calendar, health, battery, etc.) resolved at render time through data binding placeholders
**Depends on**: Phase 3 (widget extension), Phase 4 (AI pipeline for data source routing)
**Requirements**: DATA-01, DATA-02
**Success Criteria** (what must be TRUE):
  1. Data binding placeholders in widget configs (e.g., {{weather.temperature}}, {{battery.level}}, {{calendar.next.title}}) resolve to live values at widget render time
  2. Dedicated data providers exist for WeatherKit, EventKit, HealthKit, CoreLocation, battery/device info, and date/time, each with appropriate iOS permission request flows
  3. The AI identifies which data sources a user's description requires and generates configs with the correct binding placeholders without the user needing to specify data source names
  4. Dynamic widgets refresh on a timeline (15-60 min intervals depending on data type) while respecting WidgetKit's refresh budget
**Plans**: TBD

Plans:
- [ ] 07-01: Data provider framework and binding placeholder resolution in renderer
- [ ] 07-02: Individual data source implementations (WeatherKit, EventKit, HealthKit, battery, date/time, CoreLocation)
- [ ] 07-03: AI data source routing and permission request flows

### Phase 8: Lockscreen Widgets and Launch Polish
**Goal**: Users can place widgets on their lockscreen and in StandBy mode, and the app is ready for App Store submission
**Depends on**: Phase 3 (widget extension), Phase 7 (data sources)
**Requirements**: WIDG-02
**Success Criteria** (what must be TRUE):
  1. Lockscreen widgets render correctly in accessoryCircular, accessoryRectangular, and accessoryInline families with appropriate monochrome/high-contrast styling
  2. The AI generates lockscreen-appropriate widget configs when users specify lockscreen placement (compact layouts, no color, high contrast text)
  3. An onboarding flow guides first-time users through creating their first widget and placing it on their homescreen
  4. App Store review documentation includes a technical explanation of the declarative JSON config approach (not dynamic code execution) per Guideline 2.5.2
**Plans**: TBD

Plans:
- [ ] 08-01: Lockscreen widget families and StandBy mode rendering
- [ ] 08-02: Onboarding flow and App Store preparation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Schema and Foundation | 0/3 | Not started | - |
| 2. Renderer Engine | 0/2 | Not started | - |
| 3. Widget Extension | 0/1 | Not started | - |
| 4. AI Pipeline | 0/3 | Not started | - |
| 5. Main App UI | 0/3 | Not started | - |
| 6. Auth and Monetization | 0/3 | Not started | - |
| 7. Data Sources and Bindings | 0/3 | Not started | - |
| 8. Lockscreen Widgets and Launch Polish | 0/2 | Not started | - |
