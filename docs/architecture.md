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

The Swift Package executable embeds the app Info.plist in its Mach-O binary so AppKit can identify development runs. Protected features that depend on Launch Services identity and code signing, including per-app audio control, remain disabled under `swift run`; use the Xcode-generated and signed `.app` bundle for those features.

## Local-First Rule

Clipboard data, screenshots, OCR results, and sensitive content stay on-device by default. Sync abstractions must support local-only operation.

## Per-App Audio Mixer

The Media feature reads active output-process metadata from Core Audio and keeps it in memory. Browser and media helper processes are resolved to their outer application bundle before display and grouping. Per-app volume uses private process taps, a private aggregate device, and a real-time gain mixer available on macOS 14.2 and later. Tapped samples are mixed directly to the current output device and are never logged, persisted, analyzed, or sent over the network. The mixer exists only while at least one source is below 100% volume and is destroyed when the app stops. It is enabled only for a signed `.app` launch; command-line Swift Package runs provide source discovery without protected audio capture.

DynamicNotch does not use private MediaRemote APIs. Other applications' track titles are displayed only if a supported public metadata provider is added in the future.
