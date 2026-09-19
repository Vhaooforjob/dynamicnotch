# API

Base path: `/api/v1`

Responses:

```json
{ "data": {}, "meta": {} }
```

Errors:

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Invalid request", "details": {} } }
```

Initial endpoints include health, session lifecycle, current user, devices, settings, boards, and cursor-based sync push/pull.
