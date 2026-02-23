# App Store Review Notes for Widgy

## Overview

Widgy is an AI-powered widget creation app that lets users describe widgets in natural language and generates them using a declarative JSON configuration system.

## How Widget Generation Works

1. The user describes a widget in plain English (e.g., "a clock widget with the date").
2. The AI returns a JSON configuration object that describes the widget layout.
3. The app parses the JSON and renders it using **pre-built, native SwiftUI components**.

## Why This Is NOT Remote Code Execution (Guideline 2.5.2)

The JSON configuration is purely declarative data, not executable code:

- **No scripting or code execution**: The JSON only selects from a fixed set of pre-built SwiftUI view types (Text, SFSymbol, VStack, HStack, ZStack, Gauge, Divider, Spacer, Image, Frame, Padding, ContainerRelativeShape).
- **No dynamic code loading**: There is no JavaScript, WebView, or interpreted language involved. All rendering logic is compiled into the app binary.
- **Closed property set**: Each node type has a fixed, validated set of properties (font, color, spacing, alignment, etc.). Unknown properties are ignored.
- **Schema validation**: All JSON is validated against the WidgetConfig schema before rendering. Invalid configurations are rejected.
- **No network access from widgets**: Widget extensions render from locally-stored JSON only. The AI call happens in the main app, and the resulting config is stored via App Groups.
- **No arbitrary views**: The renderer maps JSON node types to a closed enum. There is no mechanism to introduce new view types at runtime.

## Analogies to Approved Patterns

This approach is functionally identical to:
- Shortcut actions that configure widgets via parameters
- Server-driven UI frameworks (e.g., Airbnb's Lona, server-driven SwiftUI) that are widely approved
- Widget configuration intents that select from pre-defined layouts

## Data Sources

Dynamic data (weather, battery, calendar, health) is fetched through standard iOS APIs with appropriate permission prompts. Data binding uses simple string interpolation (`{{source.field}}`), not code execution.

## Contact

For any questions during review, please contact us through App Store Connect.
