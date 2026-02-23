# Requirements: Widgy

## Overview

Requirements for Widgy v1 -- an iOS 26+ app that lets users create custom homescreen and lockscreen widgets through natural language conversation with AI.

Source: PROJECT.md Active requirements, validated against research/FEATURES.md and research/ARCHITECTURE.md.

## v1 Requirements

### Chat & AI Creation

| ID | Requirement | Priority |
|----|-------------|----------|
| CHAT-01 | Chat-based widget creation with AI-powered JSON config generation | P0 |
| CHAT-02 | Iterative editing via follow-up messages in the same conversation | P0 |

### Rendering Engine

| ID | Requirement | Priority |
|----|-------------|----------|
| REND-01 | Config-based SwiftUI rendering engine interpreting JSON widget specifications | P0 |
| REND-02 | Live inline preview at actual widget size (small, medium, large, lockscreen variants) | P0 |

### Widget Schema

| ID | Requirement | Priority |
|----|-------------|----------|
| SCHEMA-01 | Comprehensive JSON widget schema: layout primitives (stacks, grids, overlays), styling (colors, gradients, fonts, corner radius, padding), data bindings, conditional rendering | P0 |

### Widgets

| ID | Requirement | Priority |
|----|-------------|----------|
| WIDG-01 | Homescreen widgets (systemSmall, systemMedium, systemLarge) | P0 |
| WIDG-02 | Lockscreen widgets (accessoryCircular, accessoryRectangular, accessoryInline) | P0 |

### Data Sources

| ID | Requirement | Priority |
|----|-------------|----------|
| DATA-01 | iOS-native data sources: WeatherKit, EventKit, HealthKit, CoreLocation, Contacts, PhotoKit, MusicKit, DeviceActivity, battery/device info, date/time | P0 |
| DATA-02 | AI-powered data source routing (identifies needed sources from natural language) | P0 |

### Widget Management

| ID | Requirement | Priority |
|----|-------------|----------|
| MGMT-01 | Widget management: save, edit, delete, duplicate, rename | P0 |
| MGMT-02 | Conversation history and project archives (sidebar/bottom sheet) | P0 |

### Authentication

| ID | Requirement | Priority |
|----|-------------|----------|
| AUTH-01 | Sign in with Apple authentication via Supabase | P0 |

### Monetization

| ID | Requirement | Priority |
|----|-------------|----------|
| MONET-01 | Credit-based monetization: Free (3 one-time), Standard ($4.99/mo, 15-20), Pro ($9.99/mo, 50+) | P0 |
| MONET-02 | Per-request token consumption logging (user ID, project ID, session timestamp) | P0 |
| MONET-03 | Server-side configurable credit thresholds, tier limits, and feature flags | P0 |
| MONET-04 | Minor edits consume fractional/zero credits under configurable token threshold | P0 |

### Platform

| ID | Requirement | Priority |
|----|-------------|----------|
| PLATFORM-01 | Apple Liquid Glass design language compatibility (iOS 26+) | P0 |

### Offline & Reliability

| ID | Requirement | Priority |
|----|-------------|----------|
| OFFLINE-01 | Offline widget rendering with cached data values, auto-refresh when network detected | P0 |

### Validation

| ID | Requirement | Priority |
|----|-------------|----------|
| VALID-01 | Server-side JSON schema validation before sending configs to client | P0 |
| VALID-02 | Graceful renderer handling of unknown/invalid config properties | P0 |

## Out of Scope (v2+)

- External API data sources (crypto, stocks, sports, transit)
- Widget marketplace and community sharing
- Template gallery
- Interactive widgets and animations
- Creator program and revenue sharing
- Custom REST API data source builder
- Android / cross-platform
- OAuth/social login beyond Sign in with Apple
- Free tier credit renewal

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCHEMA-01 | Phase 1 | Pending |
| REND-01 | Phase 2 | Pending |
| REND-02 | Phase 2 | Pending |
| VALID-02 | Phase 2 | Pending |
| PLATFORM-01 | Phase 2 | Pending |
| WIDG-01 | Phase 3 | Pending |
| OFFLINE-01 | Phase 3 | Pending |
| CHAT-01 | Phase 4 | Pending |
| CHAT-02 | Phase 4 | Pending |
| VALID-01 | Phase 4 | Pending |
| MGMT-01 | Phase 5 | Pending |
| MGMT-02 | Phase 5 | Pending |
| AUTH-01 | Phase 6 | Pending |
| MONET-01 | Phase 6 | Pending |
| MONET-02 | Phase 6 | Pending |
| MONET-03 | Phase 6 | Pending |
| MONET-04 | Phase 6 | Pending |
| DATA-01 | Phase 7 | Pending |
| DATA-02 | Phase 7 | Pending |
| WIDG-02 | Phase 8 | Pending |

---
*Last updated: 2026-02-23*
