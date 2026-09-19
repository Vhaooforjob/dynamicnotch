# MASTER CODEX PROMPT

You are the principal software architect, senior macOS engineer, senior backend engineer, database architect, product designer, QA engineer, DevOps engineer, and technical writer for this project.

Your task is to initialize and build a production-grade macOS productivity application inspired by the interaction philosophy of OneNotch, but DO NOT copy proprietary source code, branding, visual assets, names, or exact UI.

Create an original product with its own architecture, visual system, naming, components, and implementation.

Do not only write documentation.

You must actually create the repository structure, configuration files, database schema, migrations, backend, macOS application skeleton, shared components, tests, scripts, documentation, AGENTS.md, Codex skills, and initial working MVP.

Do not stop after scaffolding.

Proceed incrementally until the project can be run locally.

---

# 1. PRODUCT

Temporary project codename:

`NotchFlow`

The name must be easy to replace globally later.

Product philosophy:

> Reduce context switching by exposing high-frequency micro-actions around the MacBook notch/menu-bar area.

The notch is an interaction surface, not the product itself.

The application should combine:

* clipboard manager
* clipboard search
* copy stack
* screenshot tools
* OCR
* translation
* dictionary
* media controls
* system live activities
* calendar/reminders
* meeting alerts
* AI coding-agent monitor
* global shortcuts
* floating quick panel
* settings
* local-first persistence
* optional cloud sync

The app must remain useful even when the user never creates an account.

---

# 2. PRIMARY PLATFORM

Primary platform:

macOS 15+

Target:

Apple Silicon first.

Architecture:

SwiftUI + AppKit.

Use SwiftUI for most declarative UI.

Use AppKit where lower-level macOS integration is required.

Examples:

* NSPanel
* NSWindow
* NSPasteboard
* NSScreen
* NSWorkspace
* global mouse/key monitoring
* Accessibility API
* screen positioning
* multi-display handling
* window levels
* menu-bar behavior

Avoid Electron.

Avoid embedding a browser UI for the main app.

---

# 3. SYSTEM ARCHITECTURE

Use the following high-level architecture:

```text
┌────────────────────────────────────────────┐
│                 macOS App                  │
│                                            │
│ SwiftUI UI                                 │
│ AppKit System Integration                  │
│ Local SQLite                               │
│ Keychain                                   │
│ Local File Storage                         │
│ Background Services                        │
│                                            │
└────────────────────┬───────────────────────┘
                     │ HTTPS REST
                     ▼
┌────────────────────────────────────────────┐
│                  API                       │
│                                            │
│ TypeScript                                 │
│ Fastify                                    │
│ Zod                                        │
│ OpenAPI                                    │
│ Auth                                       │
│ Rate limiting                              │
│ Sync Engine                                │
│                                            │
└────────────────────┬───────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────┐
│          PostgreSQL — Neon                 │
│                                            │
│ users                                      │
│ devices                                    │
│ subscriptions                              │
│ boards                                     │
│ synced clipboard metadata                  │
│ preferences                                │
│ sync cursor                                │
│ telemetry consent                          │
│                                            │
└────────────────────────────────────────────┘
```

Critical rule:

DO NOT connect the native macOS client directly to PostgreSQL.

All Neon access occurs through the backend API.

---

# 4. LOCAL-FIRST ARCHITECTURE

The product must be local-first.

Clipboard content, screenshots, OCR results, and sensitive user content stay on-device by default.

Use local SQLite for primary operational data.

Use Neon for:

* users
* devices
* licenses
* subscription metadata
* preferences
* optional encrypted sync metadata
* board sync
* user-enabled clipboard sync
* device sync state

Do NOT upload clipboard data unless cloud sync has explicitly been enabled.

Create a SyncEngine abstraction so sync can later support:

* Neon backend
* iCloud
* local-only

Interfaces must not tightly couple UI to Neon.

---

# 5. REPOSITORY STRUCTURE

Create a monorepo approximately like this:

```text
notchflow/
│
├── AGENTS.md
├── README.md
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── .env.example
├── Makefile
│
├── docs/
│   ├── architecture.md
│   ├── product-requirements.md
│   ├── ui-system.md
│   ├── database.md
│   ├── api.md
│   ├── security.md
│   ├── privacy.md
│   ├── roadmap.md
│   └── decisions/
│       ├── ADR-001-native-macos.md
│       ├── ADR-002-local-first.md
│       └── ADR-003-neon-backend.md
│
├── apps/
│   │
│   ├── macos/
│   │   ├── NotchFlow/
│   │   ├── NotchFlowTests/
│   │   ├── NotchFlowUITests/
│   │   └── project.yml
│   │
│   └── api/
│       ├── src/
│       ├── tests/
│       ├── package.json
│       ├── tsconfig.json
│       └── Dockerfile
│
├── packages/
│   │
│   ├── database/
│   │   ├── src/
│   │   ├── migrations/
│   │   └── drizzle.config.ts
│   │
│   ├── contracts/
│   │   ├── src/
│   │   └── schemas/
│   │
│   └── config/
│
├── scripts/
│   ├── bootstrap.sh
│   ├── dev.sh
│   ├── lint.sh
│   ├── test.sh
│   └── migrate.sh
│
└── .codex/
    └── skills/
```

Keep platform-specific code inside the appropriate application.

---

# 6. MACOS SOURCE ARCHITECTURE

Use feature-based Clean Architecture without creating unnecessary abstraction.

Target structure:

```text
apps/macos/NotchFlow/
│
├── App/
│   ├── NotchFlowApp.swift
│   ├── AppDelegate.swift
│   ├── AppEnvironment.swift
│   └── DependencyContainer.swift
│
├── Core/
│   ├── Database/
│   ├── Networking/
│   ├── Security/
│   ├── Logging/
│   ├── Shortcuts/
│   ├── Permissions/
│   ├── Extensions/
│   └── DesignSystem/
│
├── Shell/
│   ├── Notch/
│   ├── FloatingPanel/
│   ├── MenuBar/
│   └── WindowManagement/
│
├── Features/
│   ├── Clipboard/
│   ├── Screenshot/
│   ├── OCR/
│   ├── Translation/
│   ├── Dictionary/
│   ├── Media/
│   ├── Activities/
│   ├── Calendar/
│   ├── Reminders/
│   ├── Meetings/
│   ├── AgentMonitor/
│   ├── Search/
│   ├── Onboarding/
│   └── Settings/
│
├── Services/
│   ├── ClipboardMonitor/
│   ├── ScreenshotService/
│   ├── OCRService/
│   ├── TranslationService/
│   ├── MediaService/
│   ├── CalendarService/
│   ├── ReminderService/
│   ├── AgentMonitorService/
│   └── SyncEngine/
│
└── Resources/
```

Each feature should generally contain:

```text
Feature/
├── Models/
├── Views/
├── ViewModels/
├── Services/
└── Components/
```

Do not create repositories/use-cases/interfaces simply to satisfy Clean Architecture terminology.

Abstractions must solve a real boundary.

---

# 7. APP STATE

Use modern Swift observation.

Central environment objects:

```text
AppState
NotchState
PermissionState
ClipboardState
MediaState
AgentState
SyncState
SettingsState
```

Do not create one gigantic ObservableObject.

Features must own their state.

---

# 8. NOTCH WINDOW ENGINE

Create a dedicated:

`NotchWindowController`

Use an AppKit borderless floating panel.

Requirements:

* detects built-in display
* detects notch-safe area
* supports Macs without physical notch
* supports external displays
* tracks active screen
* positions panel correctly
* does not steal focus unnecessarily
* supports hover
* click
* keyboard invocation
* drag/drop
* auto-collapse
* expanded state
* pinned state

State machine:

```text
hidden
idle
hovered
compact
expanded
pinned
activity
modal
```

Do not scatter notch animation state across SwiftUI views.

Create:

```swift
enum NotchPresentationState
```

and one centralized controller.

---

# 9. NOTCH LAYOUT

Three visual states.

## Idle

Approximately:

```text
        ┌─────────────┐
────────┤             ├────────
        │    notch    │
        └─────────────┘
```

Minimal.

No unnecessary decoration.

## Compact

Example:

```text
┌──────────────────────────────┐
│ 🎵 Song               2:13   │
└──────────────────────────────┘
```

or:

```text
┌──────────────────────────────┐
│ Claude • Working      ●      │
└──────────────────────────────┘
```

## Expanded

```text
┌──────────────────────────────────────┐
│ Clipboard  Capture  Media  AI    ⚙   │
├──────────────────────────────────────┤
│                                      │
│         Feature content              │
│                                      │
└──────────────────────────────────────┘
```

---

# 10. DESIGN LANGUAGE

Create an original macOS design language.

Do NOT visually clone OneNotch.

Design principles:

* native
* dark-first
* minimal
* compact
* high information density
* keyboard-first
* subtle depth
* smooth animation
* high legibility

Use:

* system materials
* blur
* vibrancy
* SF Symbols
* semantic colors
* rounded containers

Create design tokens.

Example:

```swift
enum NFSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}
```

Also create:

```text
NFRadius
NFTypography
NFAnimation
NFShadow
NFLayout
```

Avoid magic numbers in feature views.

---

# 11. ANIMATIONS

Motion should feel native.

Use spring-based transitions.

Examples:

```swift
.spring(response: 0.32, dampingFraction: 0.82)
```

Animation rules:

* expand from notch center
* preserve spatial continuity
* avoid full-screen transitions
* avoid excessive bounce
* target 60 FPS+
* reduce motion when accessibility setting requires it

---

# 12. CLIPBOARD MANAGER

This is MVP Priority #1.

Create:

`ClipboardMonitorService`

Use:

`NSPasteboard.general`

Poll pasteboard change count efficiently.

Do not use an aggressive timer.

Clipboard types:

```text
text
richText
url
image
file
color
code
unknown
```

Model:

```swift
ClipboardItem
```

Fields:

```text
id
type
plainText
richText
fileURL
imagePath
sourceApplication
sourceBundleIdentifier
createdAt
updatedAt
isFavorite
boardID
contentHash
metadata
```

Detect duplicate clipboard entries using content hashes.

---

# 13. LOCAL CLIPBOARD DATABASE

Use SQLite.

Prefer a lightweight native solution.

Tables:

```text
clipboard_items
boards
board_items
settings
sync_metadata
recent_searches
agent_sessions
```

Add appropriate indexes.

Examples:

```text
clipboard_items(created_at DESC)
clipboard_items(type)
clipboard_items(source_bundle_identifier)
clipboard_items(content_hash)
```

Implement retention policy.

Example:

```text
Free:
24 hours / 50 items

Pro:
configurable / 500+
```

Do not hardcode subscription business logic into database code.

---

# 14. CLIPBOARD SEARCH

Create fast fuzzy search.

Search against:

* content
* source app
* type
* board

Syntax:

```text
@text
@image
@file
@link
@code
@app:Safari
@board:Design
```

Search UI must update instantly.

Keyboard navigation:

```text
↑ ↓
Enter
Cmd+C
Cmd+Enter
Esc
```

---

# 15. COPY STACK

Implement FIFO copy stack.

Workflow:

```text
Copy A
Copy B
Copy C

Paste -> A
Paste -> B
Paste -> C
```

Provide:

```text
Enable Stack
Pause Stack
Clear Stack
Reorder
Remove Item
```

State:

```swift
CopyStackState
```

Add unit tests for ordering.

---

# 16. BOARDS

Users can create reusable collections.

Example:

```text
Design
Development
Marketing
Support
```

Board features:

* create
* rename
* reorder
* delete
* drag clipboard into board
* favorite
* search
* keyboard access

---

# 17. FLOATING CLIPBOARD PANEL

Create a panel that appears near the mouse pointer.

Shortcut example:

```text
Cmd + Shift + C
```

Requirements:

* detect cursor position
* detect active display
* clamp inside visible screen
* search field receives keyboard input
* arrows navigate results
* Enter copies/pastes
* Escape closes

---

# 18. SCREENSHOT ENGINE

Priority #2.

Create:

```text
ScreenshotCoordinator
ScreenRegionSelector
ScreenshotEditor
```

Initial modes:

```text
Area
Window
Full Screen
Repeat Area
OCR Area
```

Later:

```text
Scrolling
Smart Element
Subject Capture
```

Never ship unfinished buttons pretending advanced capture already works.

Gate incomplete features behind feature flags.

---

# 19. SCREENSHOT EDITOR

Tools:

```text
Crop
Pen
Marker
Rectangle
Ellipse
Arrow
Line
Text
Blur
Pixelate
Redact
Counter
Magnifier
```

Architecture:

```text
Annotation
AnnotationLayer
AnnotationTool
AnnotationCanvas
UndoManager
```

Support undo/redo.

Export:

```text
PNG
JPEG
WebP if feasible
```

Also support:

```text
Copy
Save
Drag
Share
```

---

# 20. SCREENSHOT PRESENTATION MODE

Later phase.

Allow:

* padding
* rounded corner
* shadow
* gradient/background
* solid background
* image background
* perspective
* device-like presentation frame

Create non-destructive adjustments.

---

# 21. OCR

Use Apple's Vision framework first.

Define abstraction:

```swift
protocol OCRProvider
```

Default:

```text
AppleVisionOCRProvider
```

OCR workflow:

```text
screen capture
    ↓
Vision OCR
    ↓
text blocks
    ↓
preview
    ↓
copy / translate / search
```

Options:

* preserve lines
* merge lines
* clean line breaks
* recognize URLs
* recognize email
* recognize QR/barcode when feasible

---

# 22. TRANSLATION

Create:

```swift
protocol TranslationProvider
```

Providers can later include:

```text
Apple
Google
AI
Custom
```

For MVP create:

```text
MockTranslationProvider
```

plus one real configurable provider if practical without embedding secrets.

Never hardcode external API keys.

Secrets go through:

* Keychain on macOS
* environment variables on server

Translation actions:

```text
Translate Selection
Copy Translation
Replace Selection
Speak
Pin Result
```

---

# 23. TEXT SELECTION ACTION

Design a service using macOS Accessibility APIs.

When appropriate and user has granted permission:

```text
selected text
     ↓
floating action
     ↓
Translate
Rewrite
Copy
Search
```

All accessibility-dependent capabilities must degrade gracefully.

Never crash or loop when permission is denied.

Provide a clear settings screen explaining why permission is requested.

---

# 24. DICTIONARY

Create dictionary result UI:

```text
word
pronunciation
part of speech
definitions
examples
synonyms
```

Use provider abstraction.

Do not tie view directly to third-party API response.

---

# 25. MEDIA

Create:

```text
MediaService
NowPlayingState
MediaControlService
```

Display:

```text
artwork
title
artist
progress
play/pause
previous
next
```

Compact notch mode:

```text
Artwork | Song — Artist | waveform
```

Expanded mode:

```text
Artwork
Song
Artist

◀︎   ▶︎/Ⅱ   ▶︎

progress
```

Architect lyrics as an optional provider.

---

# 26. LIVE ACTIVITIES

Create unified event model:

```swift
struct SystemActivity
```

Types:

```text
batteryCharging
batteryLow
batteryFull
bluetoothConnected
networkDisconnected
focusChanged
timer
meetingSoon
agentNeedsInput
agentCompleted
```

Pipeline:

```text
System Services
      ↓
ActivityBus
      ↓
ActivityPriorityEngine
      ↓
NotchPresentationController
```

This is critical.

Do not allow every feature to directly manipulate notch UI.

---

# 27. ACTIVITY PRIORITY ENGINE

Create priority values.

Example:

```text
critical      100
permission     90
meeting        80
agentInput     75
batteryLow     70
clipboard      30
media          20
informational  10
```

Queue activities.

Support:

* timeout
* replacement
* deduplication
* interruption
* restore previous UI state

Unit-test the priority engine.

---

# 28. CALENDAR

Use EventKit.

Features:

```text
Today
Upcoming
Month
Event details
Open event
```

Request permission only when feature is used.

Meeting detection should recognize URLs associated with common meeting providers.

Never scrape private calendar data into cloud sync by default.

---

# 29. REMINDERS

Use EventKit where appropriate.

Actions:

```text
Complete
Snooze
Open
```

Send relevant upcoming reminder events through `ActivityBus`.

---

# 30. AI CODING AGENT MONITOR

Create plugin-based agent monitoring architecture.

Core protocol:

```swift
protocol AgentProvider {
    var id: String { get }

    func discoverSessions() async throws -> [AgentSession]

    func observe(
        session: AgentSession
    ) -> AsyncStream<AgentEvent>
}
```

Agent providers:

```text
Codex
Claude Code
GenericTerminalAgent
```

Do not tightly couple application to one AI vendor.

---

# 31. AGENT SESSION MODEL

```text
AgentSession

id
provider
title
workingDirectory
terminalPID
terminalApp
startedAt
status
model
lastMessage
requiresPermission
progress
```

Statuses:

```text
idle
thinking
running
waitingForInput
waitingForPermission
completed
failed
cancelled
```

---

# 32. AGENT MONITOR UI

Compact:

```text
┌────────────────────────────┐
│ ● Codex      Working       │
└────────────────────────────┘
```

Expanded:

```text
┌─────────────────────────────────────┐
│ Codex                           ●    │
│                                      │
│ Working                              │
│                                      │
│ Implementing ClipboardStore...      │
│                                      │
│ project/notchflow                    │
│                                      │
│        Open Session                  │
└─────────────────────────────────────┘
```

Permission state:

```text
Claude requests permission

Run command:
pnpm db:migrate

[Reject]                [Allow]
```

Never auto-approve dangerous commands.

---

# 33. JUMP TO AGENT

Create:

```text
TerminalLocator
AgentWindowLocator
```

Attempt to restore:

```text
terminal app
window
tab
pane
working directory
```

If exact restoration is unavailable, fall back to opening the terminal app.

---

# 34. GLOBAL SHORTCUTS

Create one centralized:

`ShortcutManager`

Default shortcuts:

```text
Cmd Shift C
Clipboard

Cmd Shift V
Open Notch

Cmd Shift 4
Screenshot menu

double Cmd
Quick Peek
```

Every shortcut must be user-configurable.

Detect conflicts where possible.

Persist shortcuts locally.

---

# 35. SETTINGS

Create native Settings window.

Sections:

```text
General
Notch
Clipboard
Capture
Translation
Media
Calendar
Agents
Shortcuts
Sync
Privacy
Advanced
About
```

---

# 36. PRIVACY SETTINGS

Provide:

```text
Pause Clipboard Monitoring
Ignored Apps
Sensitive Content Guard
Cloud Sync
Analytics
Crash Reports
Clear Clipboard History
Clear Screenshot History
Reset App
```

Ignored-app logic should operate using bundle identifiers.

Password managers should be easy to exclude.

---

# 37. SENSITIVE CONTENT

Implement conservative protection.

Do NOT attempt to build an unreliable “AI secret detector” initially.

Use:

* source application exclusions
* pasteboard metadata when available
* password-field signals where possible
* user-configured rules

Never log clipboard values.

---

# 38. LOGGING

Create structured logging.

Categories:

```text
app
clipboard
capture
ocr
network
database
sync
agents
permissions
activities
```

Never log:

```text
clipboard body
OCR contents
tokens
passwords
authorization headers
private screenshots
```

---

# 39. AUTH

The application must work without an account.

Account is needed only for:

* cloud sync
* device management
* license
* account settings

Architecture:

```text
anonymous local mode
        ↓
optional sign in
        ↓
cloud features
```

Use secure token storage in macOS Keychain.

Do not store credentials in UserDefaults.

---

# 40. BACKEND

Use:

```text
Node.js
TypeScript
Fastify
Zod
Drizzle ORM
PostgreSQL
Neon
OpenAPI
Vitest
```

Use strict TypeScript.

No `any` unless justified.

API layout:

```text
src/
├── app.ts
├── server.ts
├── config/
├── plugins/
├── middleware/
├── modules/
│   ├── auth/
│   ├── users/
│   ├── devices/
│   ├── boards/
│   ├── sync/
│   ├── settings/
│   └── licenses/
└── shared/
```

---

# 41. API CONVENTION

Base:

```text
/api/v1
```

Response:

```json
{
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request",
    "details": {}
  }
}
```

Use stable machine-readable error codes.

---

# 42. INITIAL API ENDPOINTS

Implement:

```text
GET    /api/v1/health

POST   /api/v1/auth/session
DELETE /api/v1/auth/session

GET    /api/v1/me

GET    /api/v1/devices
POST   /api/v1/devices
DELETE /api/v1/devices/:id

GET    /api/v1/settings
PUT    /api/v1/settings

GET    /api/v1/boards
POST   /api/v1/boards
PATCH  /api/v1/boards/:id
DELETE /api/v1/boards/:id

POST   /api/v1/sync/push
POST   /api/v1/sync/pull
```

Clipboard cloud sync endpoint is introduced only after local MVP works.

---

# 43. POSTGRESQL / NEON

Database is PostgreSQL hosted on Neon.

Use UUID primary keys.

Prefer:

```sql
gen_random_uuid()
```

Use:

```text
timestamptz
```

for timestamps.

Every table requiring modification history should include:

```text
created_at
updated_at
```

---

# 44. INITIAL DATABASE SCHEMA

Create tables:

```text
users
devices
sessions
user_settings
boards
board_items
sync_records
sync_cursors
licenses
subscriptions
feature_entitlements
```

Suggested structure:

```sql
users
-----
id uuid PK
email text UNIQUE
display_name text
avatar_url text
created_at timestamptz
updated_at timestamptz


devices
-------
id uuid PK
user_id uuid FK
device_identifier text
name text
platform text
app_version text
last_seen_at timestamptz
created_at timestamptz


user_settings
-------------
user_id uuid PK
settings jsonb
updated_at timestamptz


boards
------
id uuid PK
user_id uuid FK
name text
sort_order integer
created_at timestamptz
updated_at timestamptz
deleted_at timestamptz


board_items
-----------
id uuid PK
board_id uuid FK
client_item_id uuid
sort_order integer
metadata jsonb
created_at timestamptz
updated_at timestamptz
deleted_at timestamptz


sync_records
------------
id uuid PK
user_id uuid FK
device_id uuid FK
entity_type text
entity_id uuid
operation text
version bigint
payload jsonb
created_at timestamptz


sync_cursors
------------
user_id uuid
device_id uuid
last_version bigint
updated_at timestamptz

PRIMARY KEY(user_id, device_id)
```

Add indexes deliberately.

Do not index every field blindly.

---

# 45. DATABASE MIGRATIONS

Use Drizzle migrations.

Commands:

```text
pnpm db:generate
pnpm db:migrate
pnpm db:studio
```

Provide:

`.env.example`

Example:

```env
DATABASE_URL=
API_PORT=4000
JWT_SECRET=
APP_ENV=development
```

Never commit secrets.

---

# 46. SYNC ARCHITECTURE

Use cursor-based incremental synchronization.

Concept:

```text
Device A
   ↓ push mutations
API
   ↓ version
Postgres
   ↓ pull since cursor
Device B
```

Every synced entity includes:

```text
id
version
updatedAt
deletedAt
```

Use tombstones for deletions.

Do not rely exclusively on last-write timestamp from device clocks.

Server owns sync sequence/version.

---

# 47. CONFLICT HANDLING

Initial conflict strategy:

Settings:

```text
last server version wins
```

Boards:

```text
last mutation wins
```

Clipboard:

```text
append / deduplicate by contentHash
```

Document conflict logic clearly.

Design interfaces so CRDT can be introduced later without rewriting UI.

---

# 48. SECURITY

Mandatory:

* parameterized queries
* schema validation
* API rate limiting
* secure headers
* request-size limits
* Keychain
* no secrets in logs
* server-only database credentials
* least privilege DB role
* HTTPS in production

Add threat model document:

`docs/security.md`

Cover:

```text
clipboard leakage
malicious clipboard payload
API token theft
database credential exposure
screenshot privacy
Accessibility permission abuse
sync leakage
agent command approval
```

---

# 49. UI COMPONENT LIBRARY

Create reusable components:

```text
NFCard
NFIconButton
NFPill
NFSearchField
NFSegmentedControl
NFEmptyState
NFPermissionCard
NFShortcutRecorder
NFActivityRow
NFClipboardRow
NFAgentRow
NFPopover
NFToast
NFDivider
NFLoadingIndicator
```

Avoid duplicate visual implementations.

---

# 50. MAIN NOTCH NAVIGATION

Tabs:

```text
Clipboard
Capture
Media
Agents
More
```

Do not permanently display every module.

Allow customization later.

---

# 51. CLIPBOARD UI

Expanded:

```text
┌──────────────────────────────────────────┐
│ 🔎 Search clipboard...              ⚙    │
├──────────────────────────────────────────┤
│ All   Text   Image   Link   File         │
├──────────────────────────────────────────┤
│                                          │
│ Safari                                   │
│ https://example.com                      │
│ 12 sec ago                               │
│                                          │
├──────────────────────────────────────────┤
│ VS Code                                  │
│ const user = ...                         │
│ 1 min ago                                │
│                                          │
└──────────────────────────────────────────┘
```

Optimize for keyboard use.

---

# 52. SCREENSHOT QUICK UI

```text
┌──────────────────────────────────┐
│ Capture                          │
│                                  │
│ [ Area ] [ Window ] [ Screen ]   │
│                                  │
│ [ OCR ]  [ Repeat ]              │
│                                  │
└──────────────────────────────────┘
```

---

# 53. MEDIA UI

```text
┌─────────────────────────────────────┐
│ [Artwork]                           │
│                                     │
│ Midnight City                       │
│ M83                                 │
│                                     │
│    ◀︎        ▶︎/Ⅱ        ▶︎          │
│                                     │
│ ━━━━━━━━━●━━━━━━━━━━━━              │
└─────────────────────────────────────┘
```

---

# 54. AGENT UI

```text
┌──────────────────────────────────────┐
│ AI Agents                        +   │
├──────────────────────────────────────┤
│ ● Codex                            │
│   Implementing database schema      │
│   ~/Projects/notchflow              │
├──────────────────────────────────────┤
│ ◐ Claude                            │
│   Waiting for permission            │
│   ~/Projects/api                    │
└──────────────────────────────────────┘
```

---

# 55. ONBOARDING

Build a five-step onboarding:

```text
1 Welcome
2 Notch interaction
3 Clipboard
4 Permissions
5 Shortcuts
```

Permission screen must explain each permission before requesting it.

Example:

```text
Accessibility

Used for:
• global shortcuts
• selected-text actions
• pasting into other apps

[Enable Accessibility]
```

Never request every permission immediately at launch.

---

# 56. PERMISSION MANAGER

Create:

```text
PermissionManager
```

Track:

```text
Accessibility
Screen Recording
Calendar
Reminders
Notifications
Microphone if ever required
```

Each feature owns the reason it needs permission.

---

# 57. PERFORMANCE TARGETS

Targets:

Application launch:

```text
< 500ms perceived shell
```

Notch open:

```text
< 100ms perceived interaction
```

Clipboard search:

```text
< 50ms typical query
```

Idle CPU:

```text
near zero
```

Memory:

Avoid retaining full-resolution images unnecessarily.

Generate thumbnails.

Store large image files on disk, not as SQLite blobs.

---

# 58. FILE STORAGE

Use:

```text
Application Support/NotchFlow/
```

Structure:

```text
database/
screenshots/
clipboard-images/
thumbnails/
cache/
logs/
```

Never store private user files inside repo paths.

---

# 59. IMAGE STORAGE

SQLite should contain paths and metadata.

Example:

```text
clipboard-images/<uuid>.heic
screenshots/<uuid>.png
thumbnails/<uuid>.jpg
```

Implement cleanup according to retention rules.

---

# 60. FEATURE FLAGS

Create:

```swift
FeatureFlags
```

Initial flags:

```text
scrollingScreenshot
smartCapture
cloudSync
advancedTranslation
agentApproval
lyrics
```

Experimental code must not pollute stable feature paths.

---

# 61. ANALYTICS

Analytics disabled by default during development.

Architect:

```swift
protocol AnalyticsClient
```

Never send clipboard content.

Allowed events might eventually include:

```text
notch_opened
clipboard_search_used
capture_started
feature_enabled
```

No raw user content.

---

# 62. TEST STRATEGY

Backend:

```text
Vitest
integration tests
API tests
database tests
```

macOS:

```text
XCTest
ViewModel tests
service tests
UI smoke tests
```

Prioritize unit tests for:

```text
Clipboard deduplication
Copy Stack
Activity priority
Retention cleanup
Search parser
Sync merge
Agent state transitions
```

---

# 63. BACKEND TEST DATABASE

Never run destructive tests against production Neon database.

Support:

```text
DATABASE_URL_TEST
```

or ephemeral test branch/database.

Tests must be isolated.

---

# 64. ERROR HANDLING

Do not use silent:

```swift
try?
```

for important operations.

Define:

```text
AppError
NetworkError
DatabaseError
PermissionError
CaptureError
SyncError
AgentError
```

User-facing errors should be clear without exposing internals.

---

# 65. CODING RULES — SWIFT

Use modern Swift.

Rules:

* Swift Concurrency
* async/await
* actors where state isolation matters
* MainActor for UI state
* avoid unnecessary singleton usage
* no force unwrap except provably safe constants
* prefer structs
* protocols only for meaningful boundaries
* dependency injection through constructors/environment
* avoid Massive ViewModels
* views should not perform database/network work

---

# 66. CODING RULES — TYPESCRIPT

Enable strict mode.

Rules:

```text
no implicit any
no floating promises
validated environment
Zod at input boundaries
typed database layer
explicit domain errors
```

Controllers should not contain core business logic.

---

# 67. FORMATTERS

Swift:

```text
swift-format
```

TypeScript:

```text
ESLint
Prettier
```

Configure scripts.

---

# 68. GIT RULES

Use Conventional Commits.

Examples:

```text
feat(clipboard): add pasteboard monitor
feat(notch): create floating panel controller
feat(api): add device registration
feat(db): add sync tables
fix(capture): clamp selection to display bounds
docs(architecture): add local-first ADR
```

---

# 69. BRANCH MODEL

Recommend:

```text
main
develop

feature/*
fix/*
refactor/*
docs/*
```

But do not over-engineer branching automation.

---

# 70. AGENTS.MD

Create root:

`AGENTS.md`

It must instruct AI coding agents to:

1. Read relevant docs before changing architecture.
2. Preserve local-first privacy.
3. Never connect macOS client directly to Neon.
4. Never log clipboard/screenshot contents.
5. Keep feature boundaries.
6. Write tests with significant logic.
7. Run lint/test before completion.
8. Update documentation if architecture changes.
9. Prefer small coherent commits.
10. Never auto-approve AI-agent shell commands.
11. Do not silently introduce external dependencies.
12. Avoid duplicated design components.
13. Keep unfinished features behind feature flags.
14. Maintain backward-compatible API migrations where reasonable.

---

# 71. CODEX SKILLS

Create:

```text
.codex/skills/
```

Skills:

```text
macos-feature/
backend-feature/
database-migration/
ui-component/
bug-fix/
security-review/
performance-review/
release-check/
```

---

# 72. SKILL — MACOS FEATURE

Create:

`.codex/skills/macos-feature/SKILL.md`

Instructions:

```text
When implementing a macOS feature:

1. Identify feature boundary.
2. Check required system permission.
3. Check AppKit vs SwiftUI responsibility.
4. Define models.
5. Define service boundary if system access exists.
6. Build feature state/ViewModel.
7. Build UI.
8. Add accessibility labels.
9. Add tests.
10. Verify multi-screen behavior where relevant.
11. Verify denied permissions.
12. Verify app does not leak user content to logs.
```

---

# 73. SKILL — BACKEND FEATURE

Workflow:

```text
contract
↓
Zod schema
↓
domain service
↓
repository/database
↓
route
↓
integration tests
↓
OpenAPI
```

Never start from the HTTP route and put all logic there.

---

# 74. SKILL — DATABASE MIGRATION

Workflow:

```text
understand current schema
↓
design migration
↓
consider backward compatibility
↓
generate migration
↓
inspect SQL
↓
run test database
↓
verify rollback/recovery strategy
↓
update docs/database.md
```

Never manually alter production schema.

---

# 75. SKILL — UI COMPONENT

Check:

```text
design token usage
dark/light mode
keyboard navigation
hover
focus
disabled
loading
empty
error
accessibility
reduced motion
```

---

# 76. SKILL — SECURITY REVIEW

Review:

```text
secret exposure
logging
authentication
authorization
SQL injection
untrusted files
clipboard data
screenshot privacy
Accessibility misuse
command execution
path traversal
API rate limits
```

---

# 77. SKILL — RELEASE CHECK

Check:

```text
build
tests
lint
migration
permissions
privacy strings
entitlements
version
changelog
debug logging
feature flags
environment variables
API compatibility
```

---

# 78. DEVELOPMENT COMMANDS

Create a Makefile.

Desired commands:

```bash
make bootstrap
make dev-api
make macos
make test
make lint
make db-generate
make db-migrate
make db-studio
```

Also provide direct pnpm equivalents.

---

# 79. BOOTSTRAP SCRIPT

`scripts/bootstrap.sh`

Should:

* verify Node
* verify pnpm
* verify Xcode
* install backend dependencies
* create `.env` from `.env.example` if absent
* generate Xcode project if required
* print next steps

Do not overwrite user configuration.

---

# 80. README

README must contain:

```text
What is NotchFlow
Screenshots placeholder
Architecture
Requirements
Setup
Neon configuration
Backend setup
macOS setup
Permissions
Commands
Repository structure
Roadmap
Security
Contributing
```

---

# 81. MVP

Do NOT attempt every feature simultaneously.

MVP definition:

## Phase 0

Infrastructure.

Build:

* repository
* macOS shell
* API
* Neon connection
* database migrations
* design system
* logging
* settings foundation

## Phase 1

Notch shell.

Build:

* floating notch panel
* expand/collapse
* external display behavior
* keyboard shortcut
* menu bar item
* settings

## Phase 2

Clipboard.

Build:

* clipboard monitor
* local SQLite
* clipboard history
* search
* filters
* floating clipboard
* copy stack
* boards

## Phase 3

Screenshot + OCR.

Build:

* area screenshot
* full screen
* window
* OCR
* basic editor

## Phase 4

Activities + Media.

Build:

* activity bus
* battery
* network
* now playing

## Phase 5

Calendar.

Build:

* upcoming meetings
* event details
* join meeting

## Phase 6

Agent monitor.

Build:

* provider protocol
* Codex provider
* Claude provider
* status UI
* jump to session

## Phase 7

Cloud sync.

Build:

* account
* devices
* boards sync
* preferences sync
* optional clipboard sync

## Phase 8

Advanced tools.

Build:

* scrolling screenshot
* translation
* dictionary
* lyrics
* screenshot presentation

---

# 82. FIRST EXECUTION

After reading this prompt:

DO NOT simply respond with an architecture proposal.

Start creating files.

First inspect environment:

```bash
pwd
ls -la
git status
swift --version
xcodebuild -version
node --version
pnpm --version
```

If repository is empty:

initialize it.

Then create documentation and project structure.

---

# 83. IMPLEMENTATION ORDER

Execute exactly in this sequence unless blocked:

```text
1 Repository bootstrap
2 Documentation
3 AGENTS.md
4 Codex skills
5 Backend workspace
6 PostgreSQL schema
7 Neon configuration
8 API health endpoint
9 macOS application shell
10 Design system
11 NotchWindowController
12 Notch state machine
13 Global ShortcutManager
14 Clipboard local storage
15 Clipboard monitor
16 Clipboard UI
17 Clipboard search
18 Copy Stack
19 Tests
```

Do not begin screenshot/AI/calendar modules before the clipboard MVP builds.

---

# 84. INITIAL DATABASE DELIVERABLE

Create actual Drizzle schema and migration.

Validate database connectivity.

Implement:

```text
GET /api/v1/health
```

Health response:

```json
{
  "data": {
    "status": "ok",
    "database": "connected"
  }
}
```

Do not expose connection strings.

---

# 85. INITIAL MACOS DELIVERABLE

The first runnable version must launch a native macOS app.

Expected interaction:

```text
Launch
↓
small notch surface appears
↓
hover
↓
surface expands
↓
Clipboard placeholder appears
↓
click settings
↓
Settings window opens
↓
global shortcut toggles panel
```

Then replace clipboard placeholder with real clipboard history.

---

# 86. NOTCH FALLBACK

Physical notch is not required.

For machines without notch:

render a centered top-screen pill.

Example:

```text
              ┌───────────────┐
──────────────┤   NotchFlow   ├──────────────
              └───────────────┘
```

External displays must use the same fallback.

---

# 87. ACCESSIBILITY

Everything interactive must expose:

* labels
* roles
* keyboard focus
* keyboard navigation

Respect:

* Reduce Motion
* Increase Contrast
* VoiceOver where feasible

---

# 88. LOCALIZATION

Initial languages:

```text
English
Vietnamese
```

Do not embed user-visible text across Swift files.

Use localization resources.

---

# 89. DEVELOPMENT UX

Provide mock data for SwiftUI previews.

Every major screen should have Preview configurations for:

```text
normal
empty
loading
error
large content
```

---

# 90. DEPENDENCY POLICY

Before adding a third-party dependency:

ask:

```text
Can Apple/Foundation provide this safely?
```

Prefer native frameworks on macOS.

Backend may use established focused dependencies.

Avoid unnecessary SDKs.

---

# 91. NO PRETEND IMPLEMENTATIONS

Do not create fake production services with:

```text
TODO: implement later
```

unless feature is intentionally outside current phase.

For future functionality:

* define interface
* add feature flag
* create documented stub
* do not expose it as working UI

---

# 92. COMPLETION REPORT FORMAT

At the end of each significant implementation phase report:

```text
Implemented
Changed files
Architecture decisions
Tests
Commands executed
Known limitations
Next recommended step
```

Keep report concise.

---

# 93. QUALITY GATES

Before claiming a phase complete:

Run:

```text
backend typecheck
backend lint
backend tests
Swift build
Swift tests
```

Fix failures before proceeding whenever possible.

Do not declare success from code inspection alone.

---

# 94. DEVELOPMENT DATABASE SAFETY

Always determine current environment before migrations.

Never:

```text
DROP DATABASE
DROP TABLE
TRUNCATE
```

without explicit need.

Never automatically perform destructive migration against production Neon.

---

# 95. ENVIRONMENT CONFIGURATION

Use:

```text
development
test
production
```

Backend config must validate environment on startup.

Fail early when required variables are missing.

---

# 96. PRODUCTION THINKING

The architecture should eventually support:

```text
Free
Pro Lifetime
Team
```

But do NOT build billing during MVP.

Create entitlement abstraction:

```text
FeatureEntitlementService
```

Examples:

```text
clipboardHistoryLimit
boardLimit
advancedCapture
cloudSync
```

Business logic should query entitlements rather than check:

```text
if user.isPro
```

throughout the app.

---

# 97. PRIVACY PRINCIPLE

Default behavior:

```text
Local
Private
Offline-capable
```

Cloud is enhancement, not requirement.

This principle overrides convenience.

---

# 98. PRODUCT PRINCIPLE

Every feature must answer:

> Does this reduce context switching?

If no, reconsider whether it belongs in the notch interface.

Complex management workflows belong in a separate normal window.

Use:

```text
Notch
=
quick actions

Main Window
=
deep management
```

---

# 99. APPLICATION SURFACES

The product has four primary surfaces:

```text
1 Notch
2 Floating Quick Panel
3 Library Window
4 Settings Window
```

Do not cram everything into the notch.

---

# 100. MAIN LIBRARY WINDOW

Create later in Clipboard phase.

Sidebar:

```text
Clipboard
Boards
Screenshots
Favorites
Agents
```

Toolbar:

```text
Search
View mode
Filter
Settings
```

Clipboard modes:

```text
List
Grid
Masonry
```

---

# 101. FINAL ARCHITECTURE TARGET

Final system:

```text
                         macOS
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
     NOTCH             QUICK PANEL         LIBRARY
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                     FEATURE LAYER
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
      Clipboard         Capture          Agents
          │                │                │
          ├────────────┬───┴───────┬────────┤
          ▼            ▼           ▼        ▼
         OCR       Translation   Media   Calendar
          │
          ▼
      SERVICE LAYER
          │
   ┌──────┼───────────┐
   ▼      ▼           ▼
 SQLite  macOS APIs  Sync Engine
                       │
                       ▼
                     HTTPS
                       │
                       ▼
                 Fastify API
                       │
                       ▼
               PostgreSQL Neon
```

---

# 102. START NOW

Begin implementation.

Do not ask broad planning questions.

Make reasonable engineering decisions where unspecified.

Document important assumptions.

Do not rewrite this prompt back to me.

Inspect the repository and start with:

```text
Phase 0
```

Then continue until the initial buildable skeleton and Clipboard MVP foundation exist.

The highest priorities are:

```text
1 buildability
2 privacy
3 native macOS UX
4 architecture clarity
5 maintainability
6 testability
7 visual polish
8 advanced features
```
