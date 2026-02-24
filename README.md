# Widgy

**Describe it. See it. Use it.** — AI-powered custom widgets for iOS 26.

Widgy lets you create beautiful, personalized homescreen and lockscreen widgets just by describing what you want in plain English. No design tools. No coding. Just tell the AI what you're imagining, and it builds it for you.

## What is Widgy?

iOS widgets are powerful but limited to what app developers provide. Widgy breaks that constraint — you describe a widget in natural language, and AI generates a fully functional widget that runs natively on your homescreen.

**The problem:** You want a widget that shows your next meeting with a gradient background and a calendar icon, but no app offers exactly that layout.

**The solution:** Tell Widgy *"Show my next calendar event with a blue-to-purple gradient and a calendar icon"* and it creates it instantly.

## How It Works

1. **Describe** — Type what you want in the chat interface. Be as specific or vague as you like.
2. **Preview** — See a live preview of your widget rendered in real-time with sample data.
3. **Iterate** — Ask for changes through natural conversation: *"Make the text bigger"*, *"Change the background to dark"*, *"Add the weather too"*.
4. **Save** — Save your widget to the gallery when you're happy with it.
5. **Use** — Add it to your homescreen or lockscreen through the standard iOS widget picker.

## Key Features

- **Natural language widget creation** — Describe any widget and AI builds it
- **Multi-turn conversation** — Refine your widget through back-and-forth chat
- **Live data bindings** — Widgets can show real-time weather, calendar events, health stats, and battery level
- **iOS 26 Liquid Glass** — Native support for Apple's latest glass material design
- **Homescreen + Lockscreen** — Small, medium, and large homescreen widgets, plus lockscreen accessories
- **Widget gallery** — Browse and manage your saved widget collection
- **Streaming generation** — Watch your widget being built in real-time via SSE
- **Sign in with Apple** — Secure authentication with no passwords
- **Credit-based monetization** — Free tier with optional credit packs via StoreKit 2

## Architecture Overview

Widgy uses a **JSON config** architecture: the AI generates a JSON widget definition that follows a strict schema, and a SwiftUI renderer engine interprets it into native views at runtime.

```
User prompt → Supabase Edge Function → Claude AI → JSON config → SwiftUI Renderer → Native Widget
```

This means widgets are:
- **Lightweight** — Just a small JSON blob stored locally
- **Portable** — Shared between the main app and widget extension via App Groups
- **Safe** — No arbitrary code execution, just declarative UI config

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI, iOS 26 SDK |
| Language | Swift 6 (strict concurrency) |
| Widgets | WidgetKit, AppIntents |
| AI Backend | Supabase Edge Functions + Claude API |
| Auth | Sign in with Apple + Supabase Auth |
| Payments | StoreKit 2 |
| Data Sources | WeatherKit, EventKit, HealthKit |
| Architecture | @Observable, async/await, Sendable |

## Project Structure

```
Widgy/
├── Widgy/                          # Main iOS app
│   ├── App/                        # App entry point, config
│   ├── Views/                      # SwiftUI views (Chat, Gallery, History, Settings)
│   ├── Services/                   # AI pipeline, auth, store management
│   └── Resources/                  # Assets, colors
├── WidgyWidgets/                   # Widget extension (homescreen + lockscreen)
├── Packages/WidgyCore/             # Shared Swift Package
│   └── Sources/WidgyCore/
│       ├── Models/                 # JSON schema (WidgetNode, NodeProperties, StyleTypes)
│       ├── Renderer/               # SwiftUI renderer engine
│       ├── Services/               # Data sources (weather, calendar, health)
│       └── Utilities/              # Color parsing, helpers
├── supabase/
│   └── functions/generate-widget/  # Edge Function (TypeScript) — AI prompt + streaming
├── .planning/                      # Architecture research and roadmap
└── project.yml                     # XcodeGen project spec
```

## Getting Started

### Prerequisites

- **Xcode 26.2+** with iOS 26 SDK
- **Supabase account** with Edge Functions enabled
- **Anthropic API key** for Claude

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/lewlian/Widgy.git
   cd Widgy
   ```

2. Create a `.env` file with your credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ANTHROPIC_API_KEY=your_anthropic_key
   ```

3. Deploy the Supabase Edge Function:
   ```bash
   supabase functions deploy generate-widget
   supabase secrets set ANTHROPIC_API_KEY=your_key
   ```

4. Generate the Xcode project and build:
   ```bash
   xcodegen generate
   open Widgy.xcodeproj
   ```

5. Build and run on iOS 26 Simulator.

## Roadmap

All 8 phases of the initial build are complete:

- [x] **Phase 1** — Schema & Foundation (JSON config model, XcodeGen setup)
- [x] **Phase 2** — Renderer Engine (SwiftUI rendering, Liquid Glass)
- [x] **Phase 3** — Widget Extension (WidgetKit, AppIntents, App Groups)
- [x] **Phase 4** — AI Pipeline (Supabase Edge Function, SSE streaming)
- [x] **Phase 5** — Main App UI (Chat, Gallery, History, Settings)
- [x] **Phase 6** — Auth & Monetization (Sign in with Apple, StoreKit 2)
- [x] **Phase 7** — Data Sources (WeatherKit, EventKit, HealthKit bindings)
- [x] **Phase 8** — Lockscreen Widgets, Onboarding & Polish

## Monetization

Widgy uses a **credit-based** freemium model:
- **Free tier** — Credits included to try widget generation
- **Credit packs** — Purchase additional credits via In-App Purchase
- **Pro subscription** — Unlimited generation (planned)

Each widget generation or edit consumes one credit. Credits are managed locally with StoreKit 2 and synced with Supabase for authenticated users.

## License

This project is not currently open source. All rights reserved.
