# Security

Report vulnerabilities privately. Do not include clipboard contents, screenshots, tokens, or personal data in reports unless explicitly necessary and redacted.

Core rules:

- Store server secrets only in environment variables.
- Store client tokens in Keychain.
- Validate all API inputs with Zod.
- Use parameterized queries through Drizzle.
- Do not upload clipboard data unless the user explicitly enables sync.
