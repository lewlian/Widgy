# Features Research: iOS AI-Powered Custom Widget Builder (Widgy)

> **Research dimension:** Features
> **Date:** 2026-02-23
> **Downstream consumer:** Requirements definition
> **Competitive context:** WidgetSmith, Color Widgets, Widgy (original), Top Widgets, Brass, widget-adjacent apps

---

## Executive Summary

The iOS widget customization market splits into two tiers: (1) template-pickers (WidgetSmith, Color Widgets) that let users select from pre-designed styles, and (2) freeform editors (the original Widgy app, Brass) that expose a layer-based canvas. Both tiers share a common set of table-stakes features. Widgy's differentiator -- natural-language AI widget creation with config-based JSON rendering -- sits in an entirely new third tier: **generative widget creation**. This document catalogs the feature landscape, classifies each feature, and flags complexity and dependencies.

---

## 1. Table Stakes (Must-Have or Users Leave)

These features are present in every successful widget app. Omitting any one will cause immediate user churn.

### 1.1 Widget Size Support
- **Description:** Support all three standard WidgetKit sizes: Small (2x2), Medium (2x4), Large (2x4 tall). iOS 16+ adds Lock Screen widgets (circular, rectangular, inline). iOS 26 adds the Control Center widget surface.
- **Complexity:** Medium -- each size has different layout constraints; Lock Screen widgets are a separate WidgetKit family.
- **Dependencies:** Core rendering engine must handle all size classes.
- **Notes:** Accessory-family (Lock Screen) widgets have severe size/color constraints. Prioritize Home Screen sizes first.

### 1.2 Live Preview
- **Description:** Real-time visual preview of the widget as the user configures it, before placing on the Home Screen.
- **Complexity:** Medium -- requires rendering the widget config into a SwiftUI preview within the app.
- **Dependencies:** Rendering engine, widget config schema.

### 1.3 Basic Data Sources
- **Description:** Date/time, weather, battery level, step count (HealthKit), calendar events, reminders. These are the data sources every competitor exposes.
- **Complexity:** Medium-High -- each data source requires its own integration (WeatherKit, HealthKit, EventKit, etc.) and appropriate permissions.
- **Dependencies:** iOS permissions, background refresh, WidgetKit timeline provider.

### 1.4 Font and Color Customization
- **Description:** Users must be able to change text color, background color, and font on their widgets.
- **Complexity:** Low-Medium -- standard SwiftUI styling; the config schema needs font/color fields.
- **Dependencies:** Config schema, rendering engine.

### 1.5 Background Customization
- **Description:** Solid colors, gradients, images from photo library, and transparency/translucency effects. WidgetSmith, Color Widgets, and Widgy all offer this.
- **Complexity:** Medium -- photo library integration, image cropping/scaling, gradient editor.
- **Dependencies:** PhotosUI, config schema.

### 1.6 Widget Gallery / Saved Widgets
- **Description:** A list/grid of user-created widgets that can be managed (edit, duplicate, delete, rename).
- **Complexity:** Low-Medium -- local persistence (SwiftData or Core Data), list UI.
- **Dependencies:** Persistence layer, config schema.

### 1.7 Onboarding Flow
- **Description:** First-run experience that teaches users how to create a widget and place it on the Home Screen. Critical because many users do not know the "long press > Edit Home Screen > +" flow.
- **Complexity:** Low -- 3-5 screen walkthrough.
- **Dependencies:** None.
- **Notes:** Must include a step that explicitly shows how to add the widget via the iOS widget picker. This is the #1 support question for all widget apps.

### 1.8 Widget Refresh / Timeline
- **Description:** Widgets must update on a reasonable cadence. WidgetKit controls refresh budgets (~40-70 refreshes/day). The app must implement TimelineProvider correctly.
- **Complexity:** Medium -- understanding WidgetKit timeline policies, efficient data fetching.
- **Dependencies:** WidgetKit extension, data sources.

### 1.9 Multiple Widget Instances
- **Description:** Users can create and place multiple distinct widgets of different sizes simultaneously.
- **Complexity:** Low-Medium -- WidgetKit intent-based configuration or App Intents for widget selection.
- **Dependencies:** App Intents framework, widget config schema, persistence.

---

## 2. Differentiators (Competitive Advantage)

These features create distance from WidgetSmith and template-based competitors. They are the reason users would choose Widgy over alternatives.

### 2.1 AI Conversational Widget Creation (PRIMARY DIFFERENTIATOR)
- **Description:** Users describe a widget in natural language ("Show me a minimal clock with the weather below it in a dark theme") and Claude generates a valid widget config JSON. The conversation continues to iterate ("make the font bigger", "add my next calendar event").
- **Complexity:** High -- requires prompt engineering, config schema validation, error recovery, streaming responses, conversation state management.
- **Dependencies:** Claude API (Supabase Edge Function proxy), config schema, rendering engine, Supabase auth.
- **Notes:** This is THE differentiator. No competing widget app offers AI-driven creation. The conversation UX must feel as natural as chatting -- not like filling out a form.

### 2.2 Config-Based JSON Rendering Engine
- **Description:** Widgets are defined as JSON configurations that are rendered by a SwiftUI-based rendering engine. This decouples creation (AI) from display (renderer) and enables sharing, versioning, and server-side generation.
- **Complexity:** High -- designing a schema expressive enough for rich widgets but constrained enough for AI to generate reliably. Must handle layout (stacks, grids, spacing), styling (fonts, colors, gradients, shadows, corner radius), data bindings ({{weather.temp}}, {{date.formatted}}), and conditional logic.
- **Dependencies:** Core architecture decision. Everything depends on this.
- **Notes:** The schema is the product. Too simple = boring widgets. Too complex = AI generates broken configs. Finding the sweet spot is the critical design challenge.

### 2.3 iOS 26 Liquid Glass Integration
- **Description:** iOS 26 introduces Liquid Glass, a translucent, depth-aware material system. Widgets that adopt Liquid Glass will look native and premium on iOS 26; those that don't will look dated.
- **Complexity:** Medium-High -- requires adopting the new material APIs (GlassEffect modifier or equivalent), understanding how Liquid Glass interacts with backgrounds, text legibility, and the new visual hierarchy. As of iOS 26 beta, the API surface is still evolving.
- **Dependencies:** iOS 26+ deployment target (or conditional adoption), SwiftUI rendering engine.
- **Specific capabilities to leverage:**
  - Glass material backgrounds that blur and tint based on wallpaper
  - Depth/parallax layering within widget content
  - Vibrant text and symbol rendering that remains legible on glass
  - Adaptive tinting that shifts with light/dark mode and wallpaper color
- **Notes:** Being an early adopter of Liquid Glass is a significant differentiator. WidgetSmith and legacy competitors will take months to fully adopt.

### 2.4 Smart Template Suggestions
- **Description:** AI suggests widget designs based on context: time of day, frequently used apps, calendar density, workout schedule. "It looks like you have a busy day -- here's a widget showing your next 3 meetings."
- **Complexity:** Medium -- requires analyzing user context and generating appropriate prompts.
- **Dependencies:** AI engine (2.1), data sources (1.3), user preference learning.

### 2.5 Widget Sharing and Community
- **Description:** Users can share widget configs (JSON) with others via link, QR code, or an in-app community gallery. Shared widgets can be "installed" with one tap.
- **Complexity:** Medium -- Supabase storage for shared configs, deep links or universal links, moderation considerations.
- **Dependencies:** Supabase backend, config schema, user accounts.
- **Notes:** The original Widgy app had a strong community sharing feature. This is a proven engagement driver.

### 2.6 Conversation History and Widget Versioning
- **Description:** Users can revisit past AI conversations, see the evolution of a widget design, and revert to earlier versions.
- **Complexity:** Medium -- storing conversation + config snapshots in Supabase.
- **Dependencies:** Supabase backend, AI conversation engine (2.1).

### 2.7 Dynamic Data Bindings with Live Expressions
- **Description:** The config schema supports data-binding expressions like `{{weather.current.temp}}`, `{{battery.level}}`, `{{calendar.next.title}}` that resolve at widget render time. This is what makes AI-generated widgets dynamic rather than static screenshots.
- **Complexity:** High -- requires a safe expression evaluator, graceful fallbacks for missing data, and integration with every supported data source.
- **Dependencies:** Config schema (2.2), data sources (1.3), WidgetKit timeline provider (1.8).

### 2.8 Theme System / Style Tokens
- **Description:** Define reusable style tokens (color palettes, font sets, spacing scales) that the AI can reference. Users say "make it match my Home Screen aesthetic" and the AI applies a coherent theme.
- **Complexity:** Medium -- token schema, AI prompt integration, potential wallpaper color extraction.
- **Dependencies:** Config schema (2.2), AI engine (2.1).

### 2.9 Interactive Widgets (iOS 17+)
- **Description:** iOS 17 introduced widget interactivity via App Intents (buttons, toggles). The config schema should support defining interactive elements that trigger actions (toggle a reminder, start a timer, etc.).
- **Complexity:** High -- App Intents integration, defining which actions are safe/supported, schema extension for interactions.
- **Dependencies:** App Intents framework, config schema (2.2).

### 2.10 StandBy Mode Optimization (iOS 17+)
- **Description:** Widgets displayed in StandBy mode (landscape charging dock) have different design considerations: high contrast, larger text, red-tint night mode. AI should generate StandBy-aware variants.
- **Complexity:** Low-Medium -- primarily design awareness in the AI prompt + StandBy-specific rendering adjustments.
- **Dependencies:** AI engine (2.1), rendering engine.

---

## 3. Anti-Features (Deliberately NOT Building)

These are features that competitors have, or that seem attractive, but that Widgy should deliberately avoid.

### 3.1 Manual Layer-Based Editor / Drag-and-Drop Canvas
- **Why not:** The original Widgy app IS a layer-based editor. It's powerful but intimidating and complex. The entire value proposition of THIS Widgy is that the AI replaces the manual editor. Building a manual editor would (a) massively increase scope, (b) undermine the AI-first narrative, (c) compete with the existing Widgy app. If users want manual control, they use the conversation to iterate ("move the clock up 10 pixels").
- **Risk of including:** 3-6 months of additional development, confusing product identity, split user workflows.

### 3.2 Icon Pack / App Icon Customization
- **Why not:** Several widget apps (Color Widgets, Brass) bundle custom app icon packs to drive monetization. This is tangential to the core product, adds significant asset management overhead, and dilutes focus. iOS 18+ Automatic tinting makes custom icons less compelling anyway.
- **Risk of including:** Scope creep, maintenance burden for hundreds of icon assets.

### 3.3 Full Home Screen Theme Packages
- **Why not:** Some apps sell complete Home Screen "themes" (wallpaper + icon set + widgets). This is a content business, not a product business. It requires ongoing asset production and rapidly becomes a commodity.
- **Risk of including:** Turns the team into a content factory instead of a product team.

### 3.4 Social Feed / In-App Social Network
- **Why not:** A community gallery for sharing configs (2.5) is valuable. A full social feed with likes, comments, follows, and algorithmic ranking is a massive undertaking that distracts from the core AI creation experience. Keep sharing simple: browse, search, install.
- **Risk of including:** Moderation burden, engagement-metric chasing, 2-3 months of development for a non-core feature.

### 3.5 Web-Based Widget Editor
- **Why not:** Widgets are rendered by WidgetKit on-device. There's no mechanism to push a widget config from a web editor to the device without going through the app. A web editor would create a disjointed experience and require duplicating the rendering engine in web technologies.
- **Risk of including:** Massive duplication of effort, inconsistent rendering.

### 3.6 Android Support
- **Why not:** Android widgets use a completely different system (RemoteViews, Glance). The config schema and AI can theoretically be cross-platform, but the rendering engine cannot. Android is a separate product, not a feature of this one.
- **Risk of including:** Doubles the engineering surface for rendering, testing, and platform-specific quirks.

### 3.7 Excessive Data Source Integrations at Launch
- **Why not:** It's tempting to integrate every possible data source (stocks, sports scores, Spotify now playing, smart home, etc.). Each integration adds complexity, permissions, and API dependencies. Launch with the top 5-6 data sources (date/time, weather, battery, calendar, health/steps, reminders) and add more based on user demand.
- **Risk of including:** Delayed launch, increased maintenance burden, many integrations used by <5% of users.

---

## 4. Feature Dependency Map

```
Config Schema (2.2) ─────────────────────────────────────┐
    │                                                      │
    ├── Rendering Engine ──── Live Preview (1.2)           │
    │       │                                              │
    │       ├── Liquid Glass (2.3)                         │
    │       ├── StandBy Mode (2.10)                        │
    │       └── Interactive Widgets (2.9)                  │
    │                                                      │
    ├── Data Bindings (2.7) ── Data Sources (1.3)          │
    │                              │                       │
    │                              └── Widget Refresh (1.8)│
    │                                                      │
    ├── AI Conversation Engine (2.1) ──────────────────────┘
    │       │
    │       ├── Smart Suggestions (2.4)
    │       ├── Theme System (2.8)
    │       └── Conversation History (2.6)
    │
    ├── Widget Gallery (1.6) ── Multiple Instances (1.9)
    │
    └── Sharing (2.5)

Supabase Backend
    ├── Auth ── AI Engine (2.1)
    ├── Storage ── Sharing (2.5)
    ├── Database ── Conversation History (2.6)
    └── Edge Functions ── Claude API Proxy (2.1)
```

---

## 5. Complexity Summary

| Feature | Complexity | Category | Launch Priority |
|---------|-----------|----------|-----------------|
| Widget Size Support (1.1) | Medium | Table Stakes | P0 |
| Live Preview (1.2) | Medium | Table Stakes | P0 |
| Basic Data Sources (1.3) | Medium-High | Table Stakes | P0 |
| Font/Color Customization (1.4) | Low-Medium | Table Stakes | P0 |
| Background Customization (1.5) | Medium | Table Stakes | P0 |
| Widget Gallery (1.6) | Low-Medium | Table Stakes | P0 |
| Onboarding Flow (1.7) | Low | Table Stakes | P0 |
| Widget Refresh/Timeline (1.8) | Medium | Table Stakes | P0 |
| Multiple Instances (1.9) | Low-Medium | Table Stakes | P0 |
| AI Conversational Creation (2.1) | High | Differentiator | P0 |
| Config JSON Rendering (2.2) | High | Differentiator | P0 |
| Liquid Glass (2.3) | Medium-High | Differentiator | P0 |
| Smart Suggestions (2.4) | Medium | Differentiator | P1 |
| Sharing/Community (2.5) | Medium | Differentiator | P1 |
| Conversation History (2.6) | Medium | Differentiator | P1 |
| Dynamic Data Bindings (2.7) | High | Differentiator | P0 |
| Theme System (2.8) | Medium | Differentiator | P2 |
| Interactive Widgets (2.9) | High | Differentiator | P2 |
| StandBy Optimization (2.10) | Low-Medium | Differentiator | P1 |

---

## 6. Competitive Feature Matrix

| Feature | WidgetSmith | Color Widgets | Widgy (Original) | Brass | **Widgy (AI)** |
|---------|:-----------:|:-------------:|:-----------------:|:-----:|:--------------:|
| Template-based creation | Yes | Yes | No | Yes | No |
| Freeform editor | No | No | Yes (layers) | Partial | No (AI instead) |
| AI creation | No | No | No | No | **Yes** |
| Data sources | 8-10 | 3-5 | 10+ | 5-7 | 5-6 at launch |
| Photo backgrounds | Yes | Yes | Yes | Yes | Yes |
| Liquid Glass | Not yet | Not yet | Not yet | Not yet | **Day 1** |
| Widget sharing | No | No | Yes | No | Yes |
| Interactive widgets | Limited | No | No | No | P2 |
| Lock Screen widgets | Yes | Yes | Partial | Yes | P1 |
| StandBy mode | Basic | No | No | No | P1 |
| Monetization | Subscription | Freemium+Ads | Freemium | Subscription | Subscription |

---

## 7. Monetization Feature Considerations

### Table Stakes Monetization
- **Free tier:** Limited to 2-3 active widgets, basic data sources, limited AI conversations/day (e.g., 5).
- **Paywall placement:** After the user creates their first widget successfully (moment of value), present the upgrade. Never paywall before the user experiences the AI creation flow.

### Differentiating Monetization
- **Subscription tiers:** Monthly/annual subscription unlocking unlimited widgets, all data sources, unlimited AI conversations, community access, premium Liquid Glass templates.
- **No per-widget purchases:** Unlike some competitors that sell individual widget packs, keep it simple with a single subscription tier.
- **Free trial:** 3-day or 7-day free trial of full capabilities. Let users experience the magic first.

### Anti-Feature Monetization
- **No ads.** Ads destroy the aesthetic experience that is the entire point of widget customization.
- **No consumable IAP (e.g., "AI tokens").** Per-use AI pricing creates anxiety and friction. Flat subscription is cleaner.

---

## 8. Onboarding Feature Sequence

1. **Welcome screen** -- "Create beautiful widgets just by describing them."
2. **First widget creation** -- Guided AI conversation creating the user's first widget. Pre-seed the prompt with a suggestion ("Try: A minimal clock with today's weather").
3. **Preview and delight** -- Show the rendered widget with Liquid Glass effects. Let the user iterate once ("Want to change anything?").
4. **Placement tutorial** -- Step-by-step iOS widget placement guide with screenshots/animation.
5. **Success moment** -- Widget is live on the Home Screen. Celebrate subtly.
6. **Paywall (if free tier exhausted)** -- Only after value is demonstrated.

---

## 9. iOS 26 Liquid Glass -- Specific Feature Opportunities

| Capability | Widget Application | Complexity |
|-----------|-------------------|-----------|
| Glass material backgrounds | Default widget background that adapts to wallpaper | Low -- apply material modifier |
| Depth layering | Content elements at different visual depths (e.g., icon floats above data) | Medium -- Z-axis styling in config schema |
| Vibrant label rendering | Text that remains legible on glass without opaque backgrounds | Low -- use vibrancy modifiers |
| Adaptive tinting | Widget chrome shifts color to complement wallpaper | Low-Medium -- system-provided behavior if using standard materials |
| Animated transitions | Smooth glass transitions when widget content updates | Medium -- WidgetKit animation support |
| Sensor-driven parallax | Subtle motion of glass layers responding to device tilt | High -- may require custom rendering, unclear WidgetKit support |

**Recommendation:** Adopt glass material backgrounds and vibrant text rendering at launch (these are relatively straightforward). Depth layering is a strong visual differentiator and worth investing in for the config schema. Skip sensor-driven parallax unless Apple provides a WidgetKit API for it.

---

## 10. Key Risks and Open Questions

1. **Schema expressiveness vs. AI reliability trade-off:** The config schema must be rich enough to produce visually interesting widgets but constrained enough that Claude generates valid JSON consistently. This requires significant iteration and testing.

2. **WidgetKit refresh budget:** AI-generated widgets with dynamic data bindings will consume refresh budget. Need to be strategic about which data sources trigger refreshes vs. which are resolved at render time.

3. **Liquid Glass API stability:** iOS 26 is in beta. The Liquid Glass API surface may change before release. Plan for conditional compilation and fallback rendering.

4. **AI latency perception:** Widget generation via Claude API takes seconds. The UX must make this feel responsive (streaming partial results, progressive rendering, typing indicators).

5. **Offline capability:** What happens when the user has no internet? The AI creation flow requires connectivity, but previously created widgets must work offline. Config caching and local rendering are essential.
