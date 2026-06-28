# Creater.io — Security Overview

> Documentation of the security measures implemented across the backend and frontend.

---

## HTTP Security Headers

[Helmet](https://helmetjs.github.io/) is applied globally to set secure HTTP headers:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `Strict-Transport-Security` (HSTS)
- `X-XSS-Protection`
- Content Security Policy (default Helmet configuration)
- Cross-Origin-Resource-Policy set to `cross-origin` to allow Cloudinary image loading

**Source**: [`app.js`](../backend/src/app.js) — `app.use(helmet(...))`

---

## CORS

CORS is configured with an allowlist derived from environment variables:

- `FRONTEND_URL`
- `CLIENT_URL`
- `CORS_ORIGIN` (comma-separated for multiple origins)

Origins are normalized (trailing slashes stripped). Requests with no `Origin` header (mobile apps, server-to-server) are permitted. Credentials (`cookies`) are enabled.

**Source**: [`app.js`](../backend/src/app.js) — `app.use(cors(...))`

---

## Authentication

### JWT Strategy

- **Algorithm**: HS256 (HMAC-SHA256)
- **Access Token**: Short-lived (default `1h`), carries `_id`, `userName`, `email`
- **Refresh Token**: Long-lived (default `30d`), carries only `_id`
- Tokens are delivered via **httpOnly cookies** (web) and **JSON response body** (mobile)
- Refresh tokens are stored on the `User` document — only one valid refresh token per user at any time
- Token reuse detection: if the incoming refresh token doesn't match the stored one, the stored token is invalidated

### Password Security

- Passwords are hashed with **bcrypt** (10 salt rounds) via a Mongoose `pre('save')` hook
- Passwords are never returned in API responses (`select("-password")`)
- OAuth users receive a cryptographically random 32-byte password (never used for login)

**Source**: [`user.model.js`](../backend/src/models/user.model.js), [`auth.middleware.js`](../backend/src/middlewares/auth.middleware.js)

---

## Cookie Security

| Property | Development | Production |
|----------|-------------|------------|
| `httpOnly` | `true` | `true` |
| `secure` | `false` | `true` |
| `sameSite` | `Lax` | `None` |
| `maxAge` (access) | Matches `ACCESS_TOKEN_EXPIRY` | Same |
| `maxAge` (refresh) | Matches `REFRESH_TOKEN_EXPIRY` | Same |

**Source**: [`cookieOptions.js`](../backend/src/utils/cookieOptions.js)

---

## Rate Limiting

Four tiers of rate limiting are implemented using `express-rate-limit` with a **Redis-backed store** (`rate-limit-redis`):

| Tier | Window | Max Requests | Key | Applied To |
|------|--------|-------------|-----|------------|
| **Auth** | 5 min | 10 | IP address | Login, register, OAuth, password change, account deletion |
| **Refresh** | 15 min | 50 | User ID or IP | Token refresh endpoint |
| **Cloudinary** | 15 min | 50 | User ID or IP | All `/image/*` routes |
| **General** | 15 min | 1000 | User ID or IP | All routes (global) |

Rate limiting is **skipped in development** (`NODE_ENV=development`). If Redis is unavailable, requests are allowed through (`passOnStoreError: true`).

**Source**: [`rateLimit.middleware.js`](../backend/src/middlewares/rateLimit.middleware.js)

---

## File Upload Validation

Multer middleware enforces:

- **Allowed MIME types**: `image/jpeg`, `image/jpg`, `image/png`, `image/webp`
- **Max file size**: 5 MB
- **Storage**: Temporary disk storage in `./public/temp`, deleted after Cloudinary upload
- **Filename**: Unique suffix (`Date.now() + random`) to prevent collisions

**Source**: [`multer.middleware.js`](../backend/src/middlewares/multer.middleware.js)

---

## Input Sanitization

### Transformation Prompts

All user-provided text prompts for AI transformations are sanitized before being embedded into Cloudinary effect strings:

```javascript
const sanitize = (str) => typeof str === "string" ? str.replace(/[;,/\\]/g, "").trim() : "";
```

This prevents injection of additional Cloudinary parameters via semicolons or slashes.

**Source**: [`imageTransformations.js`](../backend/src/services/cloudinary/imageTransformations.js)

### Image URL Validation

When saving an image from a URL, the backend validates:
1. The URL is well-formed (parsed with `new URL()`)
2. The protocol is `https:`
3. The hostname is exactly `res.cloudinary.com`
4. The URL returns HTTP 200 (accessibility check)

**Source**: [`image.controller.js`](../backend/src/controllers/image.controller.js) — `saveImageToDatabase`

### Email Validation

- Basic format regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
- Reserved domain blocklist: `github.user`, `google.user` (synthetic domains used by OAuth)

**Source**: [`user.controllers.js`](../backend/src/controllers/user.controllers.js) — `validateEmailFormatAndDomain`

---

## Environment Variable Validation

At startup, `validateEnv()` enforces:

| Variable | Validation |
|----------|------------|
| `ACCESS_TOKEN_SECRET` | Required, not a placeholder, min 32 characters |
| `REFRESH_TOKEN_SECRET` | Required, not a placeholder, min 32 characters |
| `ACCESS_TOKEN_EXPIRY` | Required, valid `ms()` time format |
| `REFRESH_TOKEN_EXPIRY` | Required, valid `ms()` time format |
| `FRONTEND_URL` or `CLIENT_URL` | At least one required, must be valid URL |
| `MONGODB_URI` | Required, must start with `mongodb://` or `mongodb+srv://` |
| `PORT` | Required, numeric, 1–65535 |

Blocked placeholder values: `your_secret`, `changeme`, `secret`, `test`, `password`, `123456`

If any validation fails, the server exits with a descriptive error listing all failures.

**Source**: [`validateEnv.js`](../backend/src/utils/validateEnv.js)

---

## Error Handling

### ApiError Class

All application errors are thrown as `ApiError` instances with:
- `statusCode` — HTTP status code
- `message` — Human-readable error description
- `errors` — Array of detailed error objects (optional)
- `success` — Always `false`

### Global Error Handler

The `errorHandler` middleware (registered last in the Express middleware chain) catches all errors:
- `ApiError` instances are returned as-is
- Unknown errors are wrapped in a generic `ApiError(500)`
- Stack traces are only included in `development` mode

**Source**: [`ApiError.js`](../backend/src/utils/ApiError.js), [`errorHandler.js`](../backend/src/middlewares/errorHandler.js)

---

## Frontend Security

### Token Storage

- Tokens are stored in **Flutter Secure Storage** (Keychain on iOS, encrypted SharedPreferences on Android)
- The `TokenManager` class handles read/write/delete operations
- On token expiry, the `AuthInterceptor` automatically attempts a refresh before failing the request

### Compile-Time Configuration

- Environment variables are injected via `--dart-define` at compile time
- No `.env` file is bundled in the app binary
- Only public-facing values (API URLs, OAuth client IDs) are stored in the app — secrets remain on the backend

**Source**: [`app_config.dart`](../frontend/flutter/lib/core/config/app_config.dart), [`token_manager.dart`](../frontend/flutter/lib/core/network/token_manager.dart)

---

## Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly. Do **not** open a public GitHub issue. Contact the maintainers directly.
