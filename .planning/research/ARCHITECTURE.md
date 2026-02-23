# Architecture Research: Widgy -- iOS AI-Powered Custom Widget Builder

> **Research Dimension:** Architecture
> **Date:** 2026-02-23
> **Status:** Complete
> **Confidence:** High (based on established iOS/WidgetKit patterns, Supabase Swift SDK conventions, and AI integration best practices)

---

## 1. System Overview

Widgy is an iOS 26+ application that lets users describe widgets in natural language, uses Claude AI to generate a JSON configuration, and renders those configurations as native SwiftUI widgets via WidgetKit. The backend is Supabase (auth, database, storage). The design language is Liquid Glass (iOS 26+).

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    USER DEVICE (iOS 26+)                 │
│                                                         │
│  ┌─────────────────────┐    ┌────────────────────────┐  │
│  │   Widgy Main App    │    │  Widget Extension      │  │
│  │                     │    │  (WidgetKit)           │  │
│  │  ┌───────────────┐  │    │  ┌──────────────────┐  │  │
│  │  │ Chat/Prompt   │  │    │  │ Timeline Provider│  │  │
│  │  │ Interface     │  │    │  │                  │  │  │
│  │  └──────┬────────┘  │    │  └────────┬─────────┘  │  │
│  │         │           │    │           │            │  │
│  │  ┌──────▼────────┐  │    │  ┌────────▼─────────┐  │  │
│  │  │ AI Pipeline   │  │    │  │ JSON Config      │  │  │
│  │  │ Manager       │  │    │  │ Reader           │  │  │
│  │  └──────┬────────┘  │    │  └────────┬─────────┘  │  │
│  │         │           │    │           │            │  │
│  │  ┌──────▼────────┐  │    │  ┌────────▼─────────┐  │  │
│  │  │ Widget Config │  │    │  │ SwiftUI Renderer │  │  │
│  │  │ Store         │  │    │  │ Engine           │  │  │
│  │  └──────┬────────┘  │    │  └──────────────────┘  │  │
│  │         │           │    │                        │  │
│  └─────────┼───────────┘    └────────────────────────┘  │
│            │                          ▲                  │
│            ▼                          │                  │
│  ┌─────────────────────────────────────────────────┐    │
│  │         App Group Shared Container              │    │
│  │  (Widget JSON configs, cached assets, prefs)    │    │
│  └─────────────────────────────────────────────────┘    │
│                         │                                │
└─────────────────────────┼────────────────────────────────┘
                          │
              ┌───────────▼───────────┐
              │     Network Layer     │
              │                       │
              ├───────────────────────┤
              │                       │
    ┌─────────▼──────┐    ┌──────────▼─────────┐
    │  Supabase      │    │  Claude API        │
    │  (Auth, DB,    │    │  (Anthropic)       │
    │   Storage)     │    │                    │
    └────────────────┘    └────────────────────┘
```

---

## 2. Component Definitions and Boundaries

### 2.1 Main App Target (`Widgy`)

**Responsibility:** User-facing application. Houses all interactive UI, the AI prompt pipeline, widget config management, user authentication, and Supabase sync logic.

**Contains:**
- **Chat/Prompt Interface** -- The conversational UI where users describe desired widgets. Liquid Glass design. Handles multi-turn refinement ("make the font bigger", "change the color to blue").
- **AI Pipeline Manager** -- Orchestrates calls to Claude API. Manages system prompts, schema validation, retry logic, token budgets, and response parsing.
- **Widget Config Store** -- Local persistence layer for widget JSON configs. Writes to App Group shared container so the widget extension can read them. Also syncs to Supabase for cloud backup / cross-device.
- **Widget Gallery/Editor** -- Browse, preview, edit, and manage saved widget configurations. Live preview uses the same SwiftUI renderer engine.
- **Auth Manager** -- Supabase Auth integration (Sign in with Apple, email/password). Guards API access and cloud sync.
- **Supabase Sync Service** -- Handles CRUD operations against Supabase Postgres (widget configs table, user profiles, usage tracking). Manages real-time subscriptions if needed.

**Does NOT contain:** Widget rendering at the OS level (that is WidgetKit's job). The main app can preview widgets using the same renderer, but actual home screen widgets run in the extension process.

---

### 2.2 Widget Extension Target (`WidgyWidgets`)

**Responsibility:** Runs in a separate process managed by iOS. Provides timeline entries to the system. Reads JSON configs from the shared App Group container and renders them via the SwiftUI Renderer Engine.

**Contains:**
- **Timeline Provider** -- Implements `TimelineProvider` (or `AppIntentTimelineProvider` for configurable widgets). Returns timeline entries based on stored widget configs. Handles `.systemSmall`, `.systemMedium`, `.systemLarge`, and `.accessoryCircular`/`.accessoryRectangular` families.
- **Widget Configuration Intent** -- An `AppIntent`-based configuration that lets users pick which saved widget to display on a particular home screen slot. Uses `WidgetConfigurationIntent` with a parameter for widget ID.
- **JSON Config Reader** -- Reads the selected widget's JSON from the shared container. Deserializes into the `WidgetConfig` model.
- **SwiftUI Renderer Engine** (shared code) -- The same rendering engine used in the main app for previews. Interprets JSON config and produces SwiftUI views.

**Does NOT contain:** Network calls to Claude API (widgets cannot trigger AI generation). Minimal or no network calls at all -- relies on pre-cached data in the shared container. If dynamic data is needed (e.g., weather, stocks), the main app pre-fetches and writes to the shared container, or a background task does.

---

### 2.3 Shared Framework / Swift Package (`WidgyCore`)

**Responsibility:** Code shared between the main app and the widget extension. Avoids duplication and ensures rendering consistency.

**Contains:**
- `WidgetConfig` model (Codable struct matching JSON schema)
- `WidgetRenderer` (the SwiftUI view that interprets a `WidgetConfig`)
- `AppGroupManager` (reads/writes to the shared App Group container)
- Common design tokens (colors, fonts, spacing constants for Liquid Glass)
- Utility extensions

**Build target:** Swift Package (local) or shared framework embedded in both targets.

---

### 2.4 Supabase Backend

**Responsibility:** Cloud persistence, authentication, and (optionally) serverless functions.

**Tables:**
| Table | Purpose |
|---|---|
| `profiles` | User metadata, preferences, subscription tier |
| `widget_configs` | Stored widget JSON configs (linked to user_id) |
| `generations` | AI generation history/logs for analytics and re-generation |
| `shared_widgets` | Community gallery -- publicly shared widget configs |

**Auth:** Supabase Auth with Sign in with Apple (required for App Store) and optional email/password.

**Storage:** Supabase Storage for user-uploaded images referenced in widget configs (backgrounds, icons).

**Edge Functions (optional):** Could proxy Claude API calls for API key security (see section 5).

**Row Level Security:** All tables use RLS policies so users can only read/write their own data. `shared_widgets` has a public read policy.

---

### 2.5 Claude API (Anthropic)

**Responsibility:** Generates widget JSON configs from natural language descriptions.

**Integration pattern:** Direct API calls from the main app (or proxied through Supabase Edge Functions for key security).

**Not responsible for:** Rendering, persistence, or any client-side logic.

---

## 3. JSON Widget Config Schema Design

The JSON schema is the contract between the AI and the renderer. It must be:
1. **Expressive enough** to represent meaningful widget layouts
2. **Constrained enough** that the AI reliably produces valid output
3. **Versioned** so older configs remain renderable as the schema evolves

### 3.1 Schema Structure

```json
{
  "schema_version": "1.0",
  "widget_id": "uuid-string",
  "name": "My Weather Widget",
  "description": "Shows current temp and conditions",
  "supported_families": ["systemSmall", "systemMedium"],
  "background": {
    "type": "gradient",
    "colors": ["#1a1a2e", "#16213e"],
    "startPoint": "topLeading",
    "endPoint": "bottomTrailing"
  },
  "layout": {
    "type": "VStack",
    "alignment": "leading",
    "spacing": 8,
    "children": [
      {
        "type": "HStack",
        "spacing": 4,
        "children": [
          {
            "type": "SFSymbol",
            "name": "sun.max.fill",
            "size": 24,
            "color": "#FFD700",
            "renderingMode": "multicolor"
          },
          {
            "type": "Text",
            "content": "72°F",
            "font": "title",
            "weight": "bold",
            "color": "#FFFFFF"
          }
        ]
      },
      {
        "type": "Text",
        "content": "Sunny",
        "font": "subheadline",
        "color": "#CCCCCC"
      },
      {
        "type": "Spacer"
      },
      {
        "type": "Text",
        "content": "San Francisco",
        "font": "caption",
        "color": "#999999"
      }
    ]
  }
}
```

### 3.2 Supported Node Types

| Node Type | Description | Key Properties |
|---|---|---|
| `VStack` | Vertical stack | `alignment`, `spacing`, `children` |
| `HStack` | Horizontal stack | `alignment`, `spacing`, `children` |
| `ZStack` | Z-axis overlay | `alignment`, `children` |
| `Text` | Text label | `content`, `font`, `weight`, `color`, `lineLimit` |
| `SFSymbol` | SF Symbol icon | `name`, `size`, `color`, `renderingMode` |
| `Image` | Remote/asset image | `source` (url or asset name), `contentMode`, `cornerRadius` |
| `Spacer` | Flexible space | `minLength` |
| `Divider` | Visual separator | `color`, `thickness` |
| `Gauge` | Progress gauge | `value`, `min`, `max`, `label`, `style` |
| `ContainerRelativeShape` | Rounded container | `fill`, `children` |
| `Padding` | Padding wrapper | `edges`, `length`, `child` |
| `Frame` | Fixed/flexible frame | `width`, `height`, `maxWidth`, `maxHeight`, `alignment`, `child` |
| `Conditional` | Show/hide based on data | `condition`, `trueChild`, `falseChild` |

### 3.3 Data Binding (Future / Phase 2+)

For dynamic widgets (weather, calendar, etc.), the schema supports data placeholders:

```json
{
  "type": "Text",
  "content": "{{weather.temperature}}°",
  "font": "title"
}
```

The renderer resolves `{{...}}` placeholders against a data context dictionary populated by the main app before writing to the shared container. For v1, all values are static (baked in at generation time).

### 3.4 Schema Versioning Strategy

- `schema_version` field in every config
- Renderer includes migration logic: `migrate(config, from: "1.0", to: "1.1")`
- Old configs are auto-migrated on read
- Breaking changes increment the major version; additive changes increment the minor version

---

## 4. SwiftUI Renderer Engine Architecture

The renderer is a recursive, declarative interpreter that walks the JSON config tree and produces SwiftUI views.

### 4.1 Core Design

```swift
// Entry point
struct WidgetRendererView: View {
    let config: WidgetConfig
    let dataContext: [String: Any] // for dynamic bindings
    @Environment(\.widgetFamily) var family

    var body: some View {
        NodeRenderer(node: config.layout, dataContext: dataContext)
            .widgetBackground(config.background)
    }
}

// Recursive node renderer
struct NodeRenderer: View {
    let node: LayoutNode
    let dataContext: [String: Any]

    var body: some View {
        switch node.type {
        case .vStack:
            VStack(alignment: node.alignment, spacing: node.spacing) {
                ForEach(node.children) { child in
                    NodeRenderer(node: child, dataContext: dataContext)
                }
            }
        case .text:
            Text(resolve(node.content, with: dataContext))
                .font(node.swiftUIFont)
                .foregroundColor(node.swiftUIColor)
        case .sfSymbol:
            Image(systemName: node.name)
                .resizable()
                .frame(width: node.size, height: node.size)
                .foregroundColor(node.swiftUIColor)
        // ... other node types
        }
    }
}
```

### 4.2 Key Renderer Principles

1. **Type-safe decoding:** JSON is decoded into strongly-typed Swift structs (`LayoutNode`, `BackgroundConfig`, etc.) via `Codable`. Invalid nodes are skipped with a fallback placeholder, not crashed on.
2. **Graceful degradation:** Unknown node types render as `EmptyView()` with a debug log. This ensures forward compatibility when the schema adds new types.
3. **Widget family adaptation:** The renderer can adjust layout based on `widgetFamily`. The AI can provide per-family layouts, or the renderer can intelligently truncate content for smaller sizes.
4. **Performance:** WidgetKit views must be lightweight. The renderer avoids any async work, network calls, or heavy computation. Everything is pre-resolved before the view is constructed.
5. **Preview support:** The same renderer powers in-app live previews. The main app wraps it in a mock widget chrome to simulate the home screen appearance.

### 4.3 Validation Layer

Before rendering, a `ConfigValidator` checks:
- Schema version is supported
- Required fields are present
- Color hex strings are valid
- SF Symbol names exist (checked against a known-good list)
- Nesting depth does not exceed a safe maximum (e.g., 10 levels)
- No circular references

Invalid configs surface a user-friendly error in the preview, not a crash.

---

## 5. AI Prompt Pipeline Architecture

### 5.1 Pipeline Stages

```
User Input ──> Prompt Builder ──> Claude API ──> Response Parser ──> Validator ──> Config Store
                    │                                   │                │
                    │                                   │                ▼
                    ▼                                   ▼          [If invalid]
             System Prompt +                    JSON extraction     Retry with
             Schema Reference +                 from response       error context
             Conversation History                                  (max 2 retries)
```

### 5.2 System Prompt Design

The system prompt is critical. It must:
- Define the exact JSON schema with all valid node types and properties
- Provide 3-5 example widget configs (few-shot examples)
- Specify constraints ("only use SF Symbol names from the provided list", "always include schema_version", "respond ONLY with valid JSON")
- Include the widget family context ("the user wants a systemSmall widget, which is approximately 170x170 points")
- Encourage creative but valid designs

```
System prompt structure:
├── Role definition ("You are a widget designer...")
├── JSON schema specification (complete reference)
├── Constraints and rules
├── Size/family context
├── Few-shot examples (3-5 complete widget configs)
└── Output format instructions ("Respond with ONLY the JSON...")
```

### 5.3 Conversation Context for Refinement

Multi-turn refinement is essential ("make it bigger", "add a subtitle"). The pipeline maintains a conversation history:

```swift
struct AIConversation {
    var messages: [AIMessage] // role: .user / .assistant
    var currentConfig: WidgetConfig? // last valid config
    var widgetFamily: WidgetFamily
}
```

When the user requests a change, the pipeline sends:
1. System prompt (always)
2. Previous messages (for context)
3. The current JSON config ("Here is the current widget config: ...")
4. The user's modification request

This allows Claude to make targeted edits rather than regenerating from scratch.

### 5.4 API Key Security

Two viable patterns:

**Option A: Direct client-side calls (simpler, less secure)**
- API key stored in iOS Keychain after initial configuration
- User provides their own Anthropic API key, OR
- App bundles a key with rate limiting via Supabase usage tracking

**Option B: Supabase Edge Function proxy (recommended for production)**
- Client sends prompt to a Supabase Edge Function
- Edge Function validates the user's auth token, checks usage limits, then calls Claude API
- API key never leaves the server
- Enables server-side usage tracking and rate limiting

**Recommended:** Option B for production. Option A is acceptable for MVP/beta with user-supplied keys.

### 5.5 Error Handling and Retries

| Error Type | Strategy |
|---|---|
| Invalid JSON response | Re-request with "Your previous response was not valid JSON. Please respond with ONLY valid JSON." |
| Schema validation failure | Re-request with specific error: "The 'font' field must be one of: title, headline, body, ..." |
| Network error | Retry with exponential backoff (max 3 attempts) |
| Rate limit | Surface to user with "Please wait a moment before generating another widget" |
| Token limit exceeded | Truncate conversation history, keeping system prompt + last 2 turns |

---

## 6. Supabase Integration Patterns

### 6.1 Client SDK Setup

Use the official `supabase-swift` SDK. Initialize in the app's entry point:

```swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://xxx.supabase.co")!,
    supabaseKey: "anon-key"
)
```

### 6.2 Data Sync Strategy

**Primary source of truth:** Local (App Group shared container).
**Supabase role:** Cloud backup, cross-device sync, community sharing.

Sync flow:
1. User creates/edits widget -> written to local store immediately
2. Background task syncs to Supabase (fire-and-forget with retry queue)
3. On app launch, pull remote changes and merge (last-write-wins for MVP; conflict resolution can be added later)
4. Offline-first: app works fully without connectivity; syncs when available

### 6.3 Real-Time (Optional, Phase 2+)

Supabase Realtime can push updates for:
- Community gallery updates (new shared widgets)
- Cross-device sync (editing on iPad, seeing changes on iPhone)

Not needed for MVP.

### 6.4 Row Level Security Policies

```sql
-- Users can only access their own widget configs
CREATE POLICY "Users manage own widgets" ON widget_configs
  FOR ALL USING (auth.uid() = user_id);

-- Anyone can read shared widgets
CREATE POLICY "Public read shared widgets" ON shared_widgets
  FOR SELECT USING (true);

-- Only owner can manage their shared widgets
CREATE POLICY "Owner manages shared widgets" ON shared_widgets
  FOR ALL USING (auth.uid() = user_id);
```

---

## 7. WidgetKit Timeline Management

### 7.1 Timeline Provider Implementation

```swift
struct WidgyTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = WidgyTimelineEntry
    typealias Intent = SelectWidgetIntent

    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, config: .placeholder)
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let config = AppGroupManager.shared.loadConfig(id: configuration.widgetID)
        return Entry(date: .now, config: config ?? .placeholder)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let config = AppGroupManager.shared.loadConfig(id: configuration.widgetID)
        let entry = Entry(date: .now, config: config ?? .placeholder)

        // Static widgets: single entry, reload policy .never
        // Dynamic widgets: multiple entries with time-based reload
        return Timeline(entries: [entry], policy: .never)
    }
}
```

### 7.2 Timeline Reload Strategy

| Widget Type | Reload Policy | Trigger |
|---|---|---|
| Static (user-designed, no live data) | `.never` | Main app calls `WidgetCenter.shared.reloadTimelines(ofKind:)` when config changes |
| Dynamic (weather, calendar, etc.) | `.after(Date)` | Refresh every 15-60 min depending on data type |
| User-triggered refresh | N/A | Main app calls `reloadTimelines` after AI generates or user edits |

### 7.3 Triggering Widget Refresh from Main App

When the main app saves a new or updated widget config:

```swift
func saveWidget(_ config: WidgetConfig) {
    // 1. Write to App Group shared container
    AppGroupManager.shared.save(config)

    // 2. Tell WidgetKit to reload
    WidgetCenter.shared.reloadTimelines(ofKind: "WidgyWidget")

    // 3. Sync to Supabase (background)
    Task { await supabaseSync.upload(config) }
}
```

---

## 8. Data Flow Between Components

### 8.1 Widget Creation Flow

```
1. User types "Make me a minimal weather widget"
          │
          ▼
2. Main App: Chat UI captures input
          │
          ▼
3. Main App: AI Pipeline Manager builds prompt
   (system prompt + schema + conversation history + user input)
          │
          ▼
4. Network: Claude API call (direct or via Supabase Edge Function)
          │
          ▼
5. Main App: Response Parser extracts JSON from Claude's response
          │
          ▼
6. Main App: ConfigValidator validates JSON against schema
          │
          ├── [INVALID] ──> Step 3 (retry with error context, max 2x)
          │
          ▼ [VALID]
7. Main App: WidgetRenderer shows live preview in-app
          │
          ▼
8. User approves ("Looks good!" or taps Save)
          │
          ▼
9. Main App: Widget Config Store writes to:
   ├── App Group shared container (JSON file)
   ├── Local persistence (SwiftData or UserDefaults)
   └── Supabase widget_configs table (async background)
          │
          ▼
10. Main App: WidgetCenter.shared.reloadTimelines(ofKind:)
          │
          ▼
11. Widget Extension: TimelineProvider reads config from shared container
          │
          ▼
12. Widget Extension: WidgetRenderer renders the widget on home screen
```

### 8.2 App Group Shared Container -- What Lives There

```
AppGroup/
├── configs/
│   ├── {widget_id_1}.json      # Individual widget configs
│   ├── {widget_id_2}.json
│   └── manifest.json           # Index of all configs with metadata
├── assets/
│   ├── {hash}.png              # Cached images referenced by widgets
│   └── {hash}.jpg
└── preferences.json            # User preferences needed by extension
```

**Write:** Main app only.
**Read:** Both main app and widget extension.
**Format:** JSON files. One file per widget config plus a manifest for indexing.

### 8.3 Inter-Process Communication Summary

| From | To | Mechanism | Data |
|---|---|---|---|
| Main App | Widget Extension | App Group shared container (file system) | Widget JSON configs, cached images |
| Main App | Widget Extension | `WidgetCenter.shared.reloadTimelines` | Reload signal (no data) |
| Widget Extension | Main App | Deep link via widget URL | User taps widget -> opens app to edit |
| Main App | Supabase | supabase-swift SDK (HTTPS) | Auth, widget configs, user data |
| Main App | Claude API | URLSession / Supabase Edge Function (HTTPS) | Prompts, JSON responses |
| Supabase | Main App | supabase-swift SDK (HTTPS + WebSocket for Realtime) | Synced data, auth tokens |

---

## 9. Suggested Build Order (Dependencies)

The following build order respects dependencies -- each phase builds on the outputs of the previous one.

### Phase 1: Foundation (No dependencies)
1. **Project setup** -- Xcode project with main app target + widget extension target + shared WidgyCore package
2. **JSON schema definition** -- Finalize v1.0 schema (the contract everything depends on)
3. **WidgetConfig model** -- Codable Swift structs in WidgyCore matching the schema

> **Why first:** Everything else depends on the project structure and the JSON schema. The schema is the central contract.

### Phase 2: Renderer (Depends on Phase 1)
4. **SwiftUI Renderer Engine** -- Implement `NodeRenderer` for all v1 node types, in WidgyCore
5. **Config Validator** -- Validation logic for schema conformance
6. **Preview chrome** -- In-app widget preview wrapper (simulates home screen appearance)

> **Why second:** The renderer must exist before you can see any output from AI generation. Build it with hardcoded test JSON configs.

### Phase 3: Local Storage (Depends on Phase 1)
7. **App Group setup** -- Configure App Group entitlement on both targets
8. **AppGroupManager** -- Read/write JSON configs to shared container
9. **Widget manifest** -- Index of saved widgets

> **Why here:** Can be built in parallel with Phase 2. Needed before the widget extension can work.

### Phase 4: Widget Extension (Depends on Phases 2 + 3)
10. **TimelineProvider** -- Implement provider that reads from App Group
11. **Widget configuration intent** -- AppIntent for selecting which widget to display
12. **Widget reload integration** -- Main app triggers reload on save

> **Why here:** Needs the renderer (Phase 2) and shared storage (Phase 3) to function.

### Phase 5: AI Pipeline (Depends on Phase 1 schema)
13. **System prompt engineering** -- Craft and test the system prompt with schema reference and few-shot examples
14. **Claude API integration** -- Network layer for API calls
15. **Response parser** -- Extract and validate JSON from Claude responses
16. **Retry logic** -- Handle invalid responses with contextual retries
17. **Conversation manager** -- Multi-turn refinement support

> **Why here:** Can be built in parallel with Phases 2-4, but is listed later because testing it end-to-end requires the renderer. Prompt engineering is an iterative process.

### Phase 6: Main App UI (Depends on Phases 2 + 5)
18. **Chat interface** -- Conversational UI for widget creation (Liquid Glass design)
19. **Live preview integration** -- Show renderer output alongside chat
20. **Widget gallery** -- Browse and manage saved widgets
21. **Widget editor** -- Manual tweaks to AI-generated configs

> **Why here:** The UI layer depends on the renderer for previews and the AI pipeline for generation.

### Phase 7: Auth and Cloud Sync (Depends on Phase 6)
22. **Supabase Auth** -- Sign in with Apple integration
23. **Supabase database** -- Table setup, RLS policies
24. **Sync service** -- Upload/download widget configs
25. **Usage tracking** -- Track AI generation count for rate limiting

> **Why last:** The app is fully functional locally without cloud sync. Auth and sync add value but are not on the critical path for core functionality.

### Phase 8: Polish and Extras (Depends on all above)
26. **Community gallery** -- Browse and install shared widgets
27. **Dynamic data bindings** -- `{{placeholder}}` support
28. **Advanced widget families** -- Lock screen, StandBy, Apple Watch
29. **Onboarding flow**
30. **App Store preparation**

---

## 10. Key Architecture Decisions and Rationale

| Decision | Choice | Rationale |
|---|---|---|
| Rendering approach | JSON config interpreted at runtime | Allows AI to generate widgets without compiling code. Safe (no arbitrary code execution). Versionable. |
| Shared code mechanism | Local Swift Package (WidgyCore) | Clean dependency management. Both targets import the same package. Better than framework for this scale. |
| App-to-extension communication | App Group file system + WidgetCenter reload | This is Apple's recommended pattern. Only reliable method for passing data to widget extensions. |
| Primary data source | Local-first with cloud sync | Widgets must work offline. WidgetKit cannot make network calls reliably. Local-first ensures reliability. |
| AI API key management | Supabase Edge Function proxy (production) | Keeps API key off-device. Enables server-side rate limiting. Acceptable for production security bar. |
| Schema evolution | Version field + migration functions | Prevents breaking existing widgets when schema evolves. Standard pattern for config-driven systems. |
| Widget family support | AI generates per-family or renderer adapts | Gives AI flexibility to design family-specific layouts while renderer can truncate intelligently for simpler cases. |
| Conversation state | Client-side message array | Simple and effective. No need for server-side session management. Conversation history is bounded by token limits. |

---

## 11. Risk Areas and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| AI generates invalid JSON | Widget fails to render | Strict validation + retry pipeline + graceful fallback UI |
| Schema becomes too complex for AI reliability | Poor generation quality | Keep v1 schema minimal. Expand incrementally based on AI performance testing. |
| WidgetKit memory limits | Extension crashes | Renderer must be lightweight. No large images loaded synchronously. Test with Instruments. |
| App Group data corruption | Widgets show stale/broken content | Atomic writes (write to temp file, then rename). Manifest checksums. |
| Claude API latency | Poor user experience | Show streaming progress. Cache recent generations. Optimistic UI patterns. |
| Schema migration breaks old widgets | User data loss | Comprehensive migration tests. Keep old renderers for N-1 versions. |

---

## 12. Technology Stack Summary

| Layer | Technology |
|---|---|
| Language | Swift 6 |
| UI Framework | SwiftUI (Liquid Glass, iOS 26+) |
| Widget Framework | WidgetKit (AppIntentTimelineProvider) |
| AI | Claude API (Anthropic) via Supabase Edge Functions |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| Local Persistence | App Group container (JSON files) + SwiftData for app-level metadata |
| Networking | URLSession (native) + supabase-swift SDK |
| Shared Code | Local Swift Package (WidgyCore) |
| Minimum Target | iOS 26.0 |
