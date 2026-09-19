# NotchFlow

NotchFlow is a local-first macOS productivity app that turns the menu-bar/notch area into a compact command surface for frequent micro-actions. The MVP focuses on a native notch panel and clipboard history.

## Screenshots

Placeholder: capture the expanded notch panel after the first local run.

## Architecture

- macOS app: SwiftUI for UI, AppKit for floating panels, pasteboard, windows, and system integration.
- Local data: SQLite in Application Support. Clipboard bodies stay on-device by default.
- API: TypeScript, Fastify, Zod, Drizzle, PostgreSQL/Neon for optional account, device, board, settings, and sync metadata.
- Rule: the macOS app never connects directly to PostgreSQL.

## Requirements

- macOS 15+
- Xcode 16+ or newer
- Node.js 22+
- pnpm 10+
- XcodeGen for generating the macOS project

## Setup

```bash
make bootstrap
make dev-api
make macos
```

Copy `.env.example` to `.env` and set `DATABASE_URL` when you want backend database health checks and migrations.

## Commands

- `make dev-api`: run the Fastify API.
- `make macos`: generate and open the native macOS project.
- `make test`: run TypeScript and Swift tests where available.
- `make lint`: run TypeScript lint/build checks.
- `make db-generate`, `make db-migrate`, `make db-studio`: Drizzle workflows.

## Permissions

Clipboard monitoring uses `NSPasteboard` and does not need Accessibility. Global shortcuts, selected-text actions, and paste automation will request Accessibility only when those features are used.

## Roadmap

Phase 1 ships the notch shell and clipboard MVP. Screenshot, OCR, media, calendar, agents, and cloud sync remain behind feature flags until their foundations are complete.
