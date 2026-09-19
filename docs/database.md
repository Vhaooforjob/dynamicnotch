# Database

## Local SQLite

The macOS app owns operational data:

- `clipboard_items`
- `boards`
- `board_items`
- `settings`
- `sync_metadata`
- `recent_searches`
- `agent_sessions`

Large images and screenshots are files in Application Support, with only paths and metadata in SQLite.

## PostgreSQL/Neon

The API owns cloud account and optional sync metadata:

- `users`
- `devices`
- `sessions`
- `user_settings`
- `boards`
- `board_items`
- `sync_records`
- `sync_cursors`
- `licenses`
- `subscriptions`
- `feature_entitlements`
