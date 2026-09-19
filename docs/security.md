# Security Threat Model

Primary risks:

- Clipboard leakage through logs, analytics, sync, or crash reports.
- Malicious clipboard payloads rendered in UI.
- Screenshot and OCR privacy exposure.
- API token theft.
- Database credential exposure.
- Accessibility permission abuse.
- Sync leakage between devices.
- AI-agent command approval abuse.

Controls:

- No clipboard/screenshot contents in logs.
- Clipboard sync disabled by default.
- Server-only database credentials.
- Keychain for client tokens.
- Zod validation and Fastify request limits.
- Explicit permission prompts with graceful denial behavior.
