# Widgy

## What This Is

Widgy is an iOS app that lets users create fully custom homescreen and lockscreen widgets through natural language conversation with AI. Instead of picking from pre-built templates, users describe what they want and an AI generates a live preview they can iterate on, save, and deploy as a native iOS widget. It targets the widget customization market proven by WidgetSmith (10M+ downloads) with a generative AI creation paradigm that replaces template selection with unlimited creative freedom.

## Core Value

Users can describe any widget they imagine in plain language and see it rendered live on their screen — the gap between imagination and creation is zero.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Chat-based widget creation with AI-powered JSON config generation
- [ ] Config-based SwiftUI rendering engine interpreting JSON widget specifications
- [ ] Live inline preview at actual widget size (small, medium, large, lockscreen variants)
- [ ] Iterative editing via follow-up messages in the same conversation
- [ ] iOS-native data sources: WeatherKit, EventKit, HealthKit, CoreLocation, Contacts, PhotoKit, MusicKit, DeviceActivity, battery/device info, date/time
- [ ] AI-powered data source routing (identifies needed sources from natural language)
- [ ] Homescreen widgets (systemSmall, systemMedium, systemLarge)
- [ ] Lockscreen widgets (accessoryCircular, accessoryRectangular, accessoryInline)
- [ ] Widget management: save, edit, delete, duplicate, rename
- [ ] Conversation history and project archives (sidebar/bottom sheet)
- [ ] Sign in with Apple authentication via Supabase
- [ ] Credit-based monetization: Free (3 one-time), Standard ($4.99/mo, 15-20), Pro ($9.99/mo, 50+)
- [ ] Per-request token consumption logging (user ID, project ID, session timestamp)
- [ ] Server-side configurable credit thresholds, tier limits, and feature flags
- [ ] Minor edits consume fractional/zero credits under configurable token threshold
- [ ] Comprehensive JSON widget schema: layout primitives (stacks, grids, overlays), styling (colors, gradients, fonts, corner radius, padding), data bindings, conditional rendering
- [ ] Apple Liquid Glass design language compatibility (iOS 26+)
- [ ] Offline widget rendering with cached data values, auto-refresh when network detected
- [ ] Server-side JSON schema validation before sending configs to client
- [ ] Graceful renderer handling of unknown/invalid config properties

### Out of Scope

- External API data sources (crypto, stocks, sports, transit) — Phase 2
- Widget marketplace and community sharing — Phase 2
- Template gallery — Phase 2
- Interactive widgets and animations — Phase 2
- Creator program and revenue sharing — Phase 3
- Custom REST API data source builder — Phase 3
- Android / cross-platform — Phase 3
- OAuth/social login beyond Sign in with Apple — unnecessary complexity for v1
- Free tier credit renewal — one-time to drive conversion

## Context

- **Market**: WidgetSmith has 10M+ downloads proving massive demand for widget customization. Widgy's differentiator is generative AI replacing template selection.
- **Technical approach**: Config-based rendering (JSON → SwiftUI) rather than dynamic code generation. This is critical for App Store compliance — Apple rejects apps that execute dynamically generated code. A config interpreter is data-driven UI, not code execution.
- **AI provider**: Claude (Anthropic) for JSON config generation. System prompt includes full widget config schema so the model always generates valid configs.
- **Backend**: Supabase (Postgres + Auth + Edge Functions) for auth, credit tracking, user data, and AI routing.
- **Platform**: iOS 26+ only — fully embraces Apple's Liquid Glass design language and latest WidgetKit APIs.
- **Offline strategy**: Widget configs are self-contained. Data-bound widgets display last cached values and auto-refresh when network connectivity is detected.
- **Monetization**: Credits fund creation, not display. Once saved, widgets run forever at no cost. All pricing/thresholds are server-side configurable for post-launch tuning.

## Constraints

- **Platform**: iOS 26+ only — leverages latest WidgetKit APIs and Liquid Glass design
- **App Store**: Must use config-based rendering, not dynamic code execution. Prepare technical documentation for App Review.
- **AI costs**: Token costs must be sustainable within credit pricing. Per-request logging enables cost optimization. Claude API as provider.
- **Data sources**: Phase 1 limited to iOS-native frameworks only (no external API costs or integrations)
- **Auth**: Sign in with Apple only (required by Apple if any social login is offered)
- **Backend**: Supabase for managed infrastructure — Auth, Postgres, Edge Functions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Config-based JSON renderer over dynamic SwiftUI generation | App Store compliance, quality control, security, debuggability | — Pending |
| iOS 26+ minimum deployment target | Fully embrace Liquid Glass, latest WidgetKit APIs, simplify development | — Pending |
| Claude (Anthropic) as AI provider | Strong structured JSON output, good reasoning for widget generation | — Pending |
| Supabase as backend | Fast to ship, managed Postgres + Auth + Edge Functions | — Pending |
| Sign in with Apple only | Cleanest iOS experience, Apple requires it with social login | — Pending |
| Comprehensive JSON schema from day one | Liquid Glass compatibility requires expressive layout system upfront | — Pending |
| One-time free credits (no renewal) | Drive conversion to paid tiers | — Pending |
| Cached offline with auto-refresh | Best UX — widgets always show something, update when possible | — Pending |

---
*Last updated: 2026-02-23 after initialization*
