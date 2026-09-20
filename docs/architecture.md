# Architecture

DynamicNotch is a local-first native macOS application with an optional cloud API.

## Boundaries

- `apps/macos`: native SwiftUI/AppKit app, local SQLite, Keychain, file storage, background services.
- `apps/api`: Fastify REST API for auth, devices, settings, boards, licenses, and sync metadata.
- `packages/database`: Drizzle schema and migrations for PostgreSQL/Neon.
- `packages/contracts`: shared Zod contracts.

The macOS client talks to the API over HTTPS and never connects directly to PostgreSQL.

## macOS Lifecycle

AppKit owns the application lifecycle, status item, notch panel, and Settings window. SwiftUI feature views are embedded with `NSHostingView`. Unit-test hosts skip application services and window creation so tests do not mutate local clipboard state or register system integrations.

The Swift Package executable embeds the app Info.plist in its Mach-O binary. This keeps `swift run DynamicNotch` identifiable to AppKit and App Intents; release builds still use the Xcode-generated `.app` bundle.

## Local-First Rule

Clipboard data, screenshots, OCR results, and sensitive content stay on-device by default. Sync abstractions must support local-only operation.
