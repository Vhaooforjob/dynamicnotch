# Architecture

NotchFlow is a local-first native macOS application with an optional cloud API.

## Boundaries

- `apps/macos`: native SwiftUI/AppKit app, local SQLite, Keychain, file storage, background services.
- `apps/api`: Fastify REST API for auth, devices, settings, boards, licenses, and sync metadata.
- `packages/database`: Drizzle schema and migrations for PostgreSQL/Neon.
- `packages/contracts`: shared Zod contracts.

The macOS client talks to the API over HTTPS and never connects directly to PostgreSQL.

## Local-First Rule

Clipboard data, screenshots, OCR results, and sensitive content stay on-device by default. Sync abstractions must support local-only operation.
