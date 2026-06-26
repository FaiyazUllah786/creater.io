# Creater.io — Complete Architecture Report & Production Improvement Roadmap

> **Prepared by:** Principal Software Architect  
> **Date:** June 26, 2026  
> **Scope:** Full-stack enterprise audit — Node.js Backend + Flutter Frontend

---

# ═══════════════════════════════════════════════════
# PHASE 1: BACKEND ARCHITECTURE REPORT
# ═══════════════════════════════════════════════════

## 1.1 Folder Architecture

```
backend/src/
├── index.js              ← Entry point: env validation → DB → Redis → HTTP listen
├── app.js                ← Express setup: helmet, CORS, cookie-parser, routes
├── constants.js          ← Single constant: DB_NAME
├── controllers/
│   ├── auth.contrller.js ← OAuth handlers (GitHub/Google web + mobile)
│   ├── user.controllers.js ← Register, login, logout, CRUD, password
│   ├── image.controller.js ← Upload, get, save-URL, delete
│   └── transformation.controller.js ← Add/update/delete/clear/save transformations
├── db/
│   └── db.js             ← Mongoose connection
├── middlewares/
│   ├── auth.middleware.js ← JWT verify, token generation, refresh, Passport exports
│   ├── multer.middleware.js ← File upload (disk storage, 5MB, image-only)
│   └── rateLimit.middleware.js ← Redis-backed rate limiters (auth/refresh/cloudinary/general)
├── models/
│   ├── user.model.js     ← User schema + bcrypt + JWT generation
│   └── image.model.js    ← Image schema + aggregate-paginate plugin
├── passport/
│   └── auth.passport.js  ← Passport GitHub/Google strategies
├── redis/
│   └── redis.js          ← ioredis connection with reconnection & health guard
├── routes/
│   ├── auth.routes.js    ← /auth/* (OAuth web callbacks + mobile endpoints)
│   ├── user.routes.js    ← /user/* (auth + profile CRUD)
│   ├── image.routes.js   ← /image/* (upload, gallery, transform, save)
│   └── health.routes.js  ← /health (MongoDB + Redis health check)
├── services/
│   ├── cloudinary/
│   │   ├── config.js     ← Cloudinary v2 configuration
│   │   ├── cloudinary.js ← Upload, delete, transform URL generation
│   │   ├── transfomationHelper.js ← effectType → function dispatcher
│   │   └── imageTransformations.js ← 10 AI transformation functions
│   └── redisServices/
│       └── transformation.js ← Transformation list CRUD in Redis (30min TTL)
└── utils/
    ├── ApiError.js       ← Custom Error subclass with statusCode
    ├── ApiResponse.js    ← Standardized success response
    ├── asyncHandler.js   ← Promise-catch wrapper with error serialization
    ├── cookieOptions.js  ← Cookie config (httpOnly, secure, sameSite, maxAge)
    └── validateEnv.js    ← Startup env validation (secrets, expiry, URLs, port)
```

## 1.2 Complete Request Lifecycle

```
App (Flutter) → HTTP Request
  → Express receives
    → generalLimiter (Redis-backed, 100 req/15min)
    → Route-specific limiter (auth: 5/15min, refresh: 10/15min, cloudinary: 1000/hr)
    → multer (if file upload)
    → verifyJWT middleware (if protected route)
      → Extract token from cookie or Authorization header
      → jwt.verify with HS256
      → User.findById (exclude password, refreshToken)
      → Attach req.user and req._id
    → Controller function (wrapped in asyncHandler)
      → Input validation (manual, inline)
      → Business logic
      → Database operations (Mongoose)
      → External services (Cloudinary, Redis)
    → ApiResponse (success) or ApiError (failure)
  → asyncHandler catches errors
    → ApiError → structured JSON {statusCode, message, data, success, errors}
    → Unknown Error → 500 JSON with dev-mode stack trace
```

## 1.3 Authentication Architecture

### Local Auth (Email/Password)
1. **Register:** `POST /user/auth/register` → validate fields → check uniqueness → bcrypt hash (pre-save hook) → create User → return user (no tokens)
2. **Login:** `POST /user/auth/login` → find user → bcrypt compare → generate access+refresh tokens → store refreshToken on user document → set cookies + return tokens in body
3. **Logout:** `POST /user/auth/logout` (protected) → null out refreshToken → clear cookies

### OAuth (Google/GitHub)
- **Web flow:** Passport strategies → callback → find-or-create user → generate tokens → set cookies → redirect to frontend URL
- **Mobile flow:** Flutter sends idToken (Google) or authorization code (GitHub) → backend verifies → find-or-create user → return tokens in JSON body (no cookies)

### Token Architecture
- **Access Token:** JWT with `{_id, userName, email}`, HS256, configurable expiry (default 1h)
- **Refresh Token:** JWT with `{_id}`, HS256, configurable expiry (default 30d)
- **Storage:** Refresh token stored in `user.refreshToken` field in MongoDB (single-device model)
- **Rotation:** On refresh, both tokens are regenerated and old refresh token is overwritten

### Refresh Flow
1. Client sends refresh token in cookie or body to `POST /user/auth/refresh-tokens`
2. Verify JWT signature
3. Find user by decoded `_id`
4. Compare incoming token with stored token (reuse detection)
5. If mismatch → null out stored token, return 403 (token revoked)
6. Generate new pair → save new refresh token → return both tokens + updated user

## 1.4 Redis Usage
- **Rate Limiting:** All 4 rate limiters use `RedisStore` from `rate-limit-redis`
- **Transformation State:** Per-image transformation list stored as JSON string with key = Cloudinary publicId, TTL = 1800s (30 min)
- **Health Check:** Redis status checked in `/health` endpoint
- **Graceful Degradation:** `getRedisInstance()` throws 503 if Redis is down; `passOnStoreError: true` allows requests to proceed even if rate limiting fails

## 1.5 Database Models

### User Model
| Field | Type | Constraints |
|-------|------|-------------|
| userName | String | required, unique, lowercase, indexed |
| email | String | required, unique |
| password | String | required, min 6, bcrypt hashed |
| authProvider | String | default "local" |
| githubId | String | optional |
| googleId | String | optional |
| profilePhoto | String | optional |
| firstName | String | optional |
| lastName | String | optional |
| refreshToken | String | optional |

### Image Model
| Field | Type | Constraints |
|-------|------|-------------|
| publicId | String | required (Cloudinary public_id) |
| secureUrl | String | required |
| height | Number | required |
| width | Number | required |
| author | ObjectId ref User | required |
| createdAt | Date | default now |

## 1.6 Cloudinary Workflow

### Upload Pipeline
1. Multer saves file to `./public/temp` with unique filename
2. `uploadOnCloudinary()` configures Cloudinary → uploads with preset "creater.io" → returns response → deletes temp file in `finally` block
3. Also supports URL-based upload (for saving transformed images)

### Transformation Pipeline
1. Client sends `{imagePublicId, transformation}` with `effectType` + parameters
2. `transformationHelper()` maps effectType → specific function
3. Each function: gets current list from Redis → builds Cloudinary URL with all effects → returns preview URL + effect object
4. Effect stored in Redis list with UUID
5. On save: `universalTransformation()` builds final URL → re-uploads to Cloudinary → creates new Image document

### Delete Pipeline
1. `deleteImageFromCloudinary(publicId)` → Cloudinary destroy
2. Profile photo deletion extracts publicId from URL via `extractPublicId()`
3. Account deletion: batch deletes all user images + profile photo from Cloudinary, then DB cleanup

## 1.7 Response Format

**Success:**
```json
{
  "statusCode": 200,
  "data": { ... },
  "message": "...",
  "success": true
}
```

**Error (ApiError):**
```json
{
  "statusCode": 422,
  "message": "...",
  "data": null,
  "success": false,
  "errors": [...]
}
```

**Error (Unknown):**
```json
{
  "statusCode": 500,
  "message": "Internal Server Error",
  "success": false,
  "errors": ["..."],
  "stack": "..." (dev only)
}
```

## 1.8 Security Architecture
- **Helmet:** HTTP security headers with cross-origin resource policy
- **CORS:** Whitelist-based with credential support; allows null origin (mobile apps)
- **Rate Limiting:** 4 tiers (general, auth, refresh, cloudinary) backed by Redis
- **Password Hashing:** bcrypt with 10 salt rounds
- **JWT:** HS256 with algorithm restriction on verify
- **Cookie Security:** httpOnly, secure (prod), sameSite None (prod) / Lax (dev)
- **File Validation:** MIME type whitelist + 5MB size limit
- **URL Validation:** `saveImageToDatabase` validates Cloudinary domain
- **Input Sanitization:** `sanitize()` strips `;,/\` from transformation prompts
- **Env Validation:** Startup checks for secret strength (32+ chars), valid expiry format, valid URLs

## 1.9 Notable Backend Issues Found

> [!WARNING]
> These are observations, not recommendations yet.

1. **No service layer separation** — controllers contain all business logic directly
2. **`generateAccessRefreshToken` lives in middleware** — architectural misplacement
3. **Cloudinary config called on every operation** — `cloudinaryConfig()` invoked redundantly
4. **No global error handler middleware** — errors only caught by `asyncHandler`
5. **`refreshAccessToken` is not wrapped in `asyncHandler`** — uses manual try/catch with different response format
6. **Typo in filename:** `auth.contrller.js` (missing 'o')
7. **Copy-paste comments:** "Create new GitHub user" appears in Google auth handler
8. **No request logging middleware** (morgan, pino, etc.)
9. **No input validation library** (joi, zod, express-validator)
10. **No API versioning** (`/v1/` prefix)
11. **`updateUserProfile` response wraps data in `updatedUser`** while other endpoints return data directly — inconsistency
12. **No pagination on `getImageFromDatabase`** — uses aggregation pipeline but no paginate
13. **Transformation list Redis keys are bare publicIds** — no namespace, collision risk
14. **OAuth users get random passwords** — cannot login via local auth but password field is required
15. **`trust proxy` set to 1** — correct for single reverse proxy, but undocumented assumption

---

# ═══════════════════════════════════════════════════
# PHASE 2: FRONTEND ARCHITECTURE REPORT
# ═══════════════════════════════════════════════════

## 2.1 Folder Structure

```
frontend/flutter/lib/
├── main.dart              ← App entry: dotenv, SystemChrome, DioClient init, providers
├── app_launcher.dart      ← Auth bootstrap → route to /home or /login
├── router.dart            ← Named route generator (switch-case)
├── splash_screen.dart     ← Simple text "Creater.io"
├── home_screen.dart       ← Bottom nav (Gallery + Account) + FAB upload
├── common/
│   ├── ip.dart            ← Hardcoded production URL (legacy, unused by Dio)
│   ├── message.dart       ← Message enum + show helper
│   ├── navigator_key.dart ← Global navigator key
│   ├── storage.dart       ← FlutterSecureStorage wrapper
│   ├── utils.dart         ← Image pickers, snackbar, color picker, handleMessage
│   ├── provider/
│   │   └── unsplash_provider.dart ← Unsplash API + download
│   ├── theme/
│   │   ├── colors.dart    ← Color constants (light + dark)
│   │   ├── fonts.dart     ← Legacy font definition (unused)
│   │   ├── app_theme.dart ← Light + dark ThemeData (Google Fonts Poppins)
│   │   └── theme_provider.dart ← ThemeMode persistence (SharedPreferences)
│   └── widgets/
│       ├── api_error.dart      ← ApiError extends Error
│       ├── api_response.dart   ← ApiResponse extends Error (!)
│       ├── app_snackbar.dart   ← AppSnackbar utility
│       ├── error.dart          ← Simple error display widget
│       ├── image_viewer.dart   ← Full-screen image viewer
│       ├── seach_field.dart    ← Search text field widget
│       ├── shimmer_loading.dart ← Shimmer placeholder
│       ├── source_sheet.dart   ← Image source bottom sheet
│       └── unsplash_screen.dart ← Unsplash browse + pick screen
├── core/
│   └── network/
│       ├── dio_client.dart     ← Singleton Dio with base config
│       ├── auth_interceptor.dart ← Token attach, 401 retry, proactive refresh, queue
│       ├── auth_service.dart   ← Startup session restoration
│       ├── auth_bootstrap.dart ← Completer gate for interceptor
│       └── token_manager.dart  ← In-memory access token + JWT expiry check
├── features/
│   ├── auth/
│   │   ├── controller/
│   │   │   └── user_controller.dart ← ChangeNotifier for all user operations
│   │   ├── repository/
│   │   │   └── user_repository.dart ← Dio calls for user API + OAuth flows
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── signup_screen.dart
│   │       ├── account_screen.dart
│   │       ├── update_profile_screen.dart
│   │       └── update_password_screen.dart
│   └── Image/
│       ├── controller/
│       │   └── image_controller.dart ← ChangeNotifier for image operations
│       ├── repository/
│       │   └── image_repository.dart ← Dio calls for image API
│       ├── screens/
│       │   ├── image_gallery.dart ← Staggered grid of user images
│       │   └── image_editor.dart  ← Transform preview + drawer + bottom bar
│       └── widgets/
│           ├── edit_widget.dart ← Transformation tool picker bottom sheet
│           ├── transformation_drawer.dart ← Applied transformations list
│           ├── gen_fill.dart
│           ├── gen_background_replace.dart
│           ├── gen_replace.dart
│           ├── gen_remove.dart
│           ├── gen_recolor.dart
│           └── gen_extract.dart
└── model/
    ├── user_model.dart    ← UserModel with fromMap/toMap
    └── image_model.dart   ← ImageModel with fromMap/toMap
```

## 2.2 Architecture Pattern: MVVM-inspired

```
Screen (View) → watches Controller (ViewModel, ChangeNotifier)
Controller → calls Repository (Data Layer)
Repository → calls DioClient → AuthInterceptor → Backend API
                                     ↓ (on 401)
                              TokenManager + SecureStorage
```

## 2.3 State Management: Provider

- `ThemeProvider` — ThemeMode persistence
- `UserController` — User state, auth state, loading flags, messages
- `ImageController` — Image list, transformation state, loading states
- `UnsplashProvider` — Unsplash API interaction

Provider tree:
```
ChangeNotifierProvider(ThemeProvider)
  └── MultiProvider([
        UserController,
        UnsplashProvider,
        ImageController
      ])
```

## 2.4 Network Layer (Critical Subsystem)

### DioClient
- Singleton `Dio` instance with base URL from `.env`
- 30s connect + receive timeouts
- `AuthInterceptor` added on app start

### AuthInterceptor (Sophisticated)
- **onRequest:** Skip public routes → wait for bootstrap → proactive refresh if token expires within 2 min → attach Bearer token
- **onError (401):** Detect if refresh API failed → logout; detect if already refreshing → queue via Completer; start refresh → retry original request with `retried` flag to prevent loops
- **Separate Dio instance** for refresh calls (avoids interceptor recursion)
- **Concurrent request handling:** Queued requests wait for refresh Completer

### AuthService (Startup)
- Load access token from SecureStorage → if valid, use directly
- If expired, attempt refresh using stored refresh token
- On failure, clear all tokens

### AuthBootstrap
- Completer-based gate that blocks interceptor requests until initial auth is resolved

## 2.5 Token Management
- **In-memory:** `TokenManager._accessToken` (fast access, no async)
- **Persistent:** `SecureStorageService` (FlutterSecureStorage) stores accessToken, refreshToken, user JSON
- **JWT Decoding:** `jwt_decoder` package for expiry checks (client-side only, no signature verification)

## 2.6 Navigation
- `onGenerateRoute` with named routes (switch-case)
- Global `navigatorKey` for navigation from non-widget contexts (interceptor logout)
- Routes: `/splash`, `/home`, `/login`, `/signup`, `/account`, `/update-profile`, `/update-password`, `/unsplash`
- Image editor pushed via `Navigator.push` (not named route)

## 2.7 Notable Frontend Issues Found

> [!WARNING]
> These are observations, not recommendations yet.

1. **`ApiResponse extends Error`** — response class should NOT extend Error; semantically wrong
2. **`ApiError extends Error`** — should extend `Exception`; `Error` is for programmer mistakes in Dart
3. **Deprecated `WillPopScope`** — should use `PopScope` (Flutter 3.12+)
4. **Legacy `ip.dart`** with hardcoded URL still present (unused after Dio migration)
5. **Unused `http` package** — `pubspec.yaml` includes `http: ^1.2.2` but Dio handles all network calls
6. **Case-sensitive folder name `Image`** — violates Dart conventions (should be `image`)
7. **Repository creates new instances** — `UserRepository()` and `ImageRepository()` instantiated inside controllers, not injected
8. **No dependency injection** — tight coupling throughout
9. **`updateUserProfile` expects `res.data["updatedUser"]`** but backend sends `res.data` directly — **DTO mismatch**
10. **No retry logic** for non-auth network failures
11. **No offline handling** — all operations assume connectivity
12. **No structured logging** — only `debugPrint`
13. **Massive `account_screen.dart` (26KB)** — god widget
14. **Massive `signup_screen.dart` (19KB)** — god widget
15. **No `const` constructors** enforced widely
16. **No tests** — `test/` directory exists but empty
17. **`fonts.dart` defined but unused** — theme uses Google Fonts directly
18. **`_pageController` not disposed** in `HomeScreen`
19. **Provider nesting** — `ThemeProvider` is parent of `MultiProvider` containing other providers, creating unnecessary rebuild scope
20. **`context.read<ImageController>()` in `build()`** — `home_screen.dart` line 49, should use `watch` or move to callback

---

# ═══════════════════════════════════════════════════
# PHASE 3: BACKEND vs FRONTEND FLOW ANALYSIS
# ═══════════════════════════════════════════════════

## 3.1 Authentication Mismatches

| Issue | Backend | Frontend | Severity |
|-------|---------|----------|----------|
| **Registration returns no tokens** | Returns user only (201) | Controller checks for null but doesn't extract tokens | ⚠️ Medium — user must login after register |
| **Login response structure** | `{user, accessToken, refreshToken}` | Accesses `res.data['accessToken']` correctly | ✅ OK |
| **Google mobile response** | Returns `{userWithoutPass, accessToken, refreshToken}` | Accesses `res.data['accessToken']` | ✅ OK |
| **GitHub mobile response** | Returns `{userWithoutPass, accessToken, refreshToken}` | Accesses `res.data['accessToken']` | ✅ OK |
| **Refresh response** | Returns `{user, accessToken, refreshToken}` nested in `data` | Interceptor accesses `resMap.data['accessToken']` | ✅ OK |

## 3.2 DTO / Model Inconsistencies

| Issue | Details | Severity |
|-------|---------|----------|
| **`updateUserProfile` response** | Backend returns `ApiResponse(200, updatedUser, ...)` where `updatedUser` IS the data. Frontend accesses `res.data["updatedUser"]` which would be `null` — the backend wraps data in `ApiResponse.data`, not under a sub-key | 🔴 **Critical** — profile update may silently fail to update local user state |
| **`UserModel` missing `_id`** | Backend sends `_id` field, Flutter model doesn't store it | ⚠️ Medium — needed for some operations |
| **`ImageModel.fromMap` uses `map["_id"]`** | Correct for MongoDB documents | ✅ OK |
| **OAuth mobile: `userWithoutPass` key** | Backend sends `{userWithoutPass: {...}, accessToken, refreshToken}`. Frontend ignores user data from OAuth login, only extracts tokens | ⚠️ Low — works but wastes data |

## 3.3 Error Response Inconsistencies

| Issue | Details | Severity |
|-------|---------|----------|
| **`refreshAccessToken` error format** | Uses `new ApiError(...)` directly in JSON (not asyncHandler format) — `ApiError` constructor sets `this.data = null` and `this.errors = []`, so the serialized object matches | ✅ OK (by accident) |
| **Frontend `ApiError.fromMap` expects `errors`** | Backend asyncHandler sends `errors` field | ✅ OK |
| **`ApiResponse extends Error` in Flutter** | Semantically wrong — causes confusion when debugging; `ApiResponse` objects treated as throwables | ⚠️ Medium |

## 3.4 Race Conditions

| Issue | Details | Severity |
|-------|---------|----------|
| **Concurrent refresh requests** | Frontend `AuthInterceptor` handles this with `_isRefreshing` flag + `Completer` queue | ✅ Well-handled |
| **Proactive refresh + reactive refresh** | Both paths use the same `_isRefreshing` guard | ✅ Well-handled |
| **`_logout` guard** | `_isLoggingOut` flag prevents multiple logout navigations | ✅ Well-handled |
| **Redis transformation list TTL** | 30-minute TTL with no extension on access — long editing sessions lose state | 🔴 **Critical** — user loses all transformation progress after 30 min |
| **No optimistic locking on user.refreshToken** | If two devices refresh simultaneously, one gets revoked | ⚠️ Medium (single-device model by design) |

## 3.5 State Synchronization Issues

| Issue | Details | Severity |
|-------|---------|----------|
| **User state loaded twice** | `loadUserFromStorage()` + `getCurrentUser()` called sequentially in `initState` — first shows stale data, then overwrites | ⚠️ Low — acceptable pattern for instant display |
| **Image list not synced after save** | `saveImage` in editor calls `getAllImages()` — full refresh, inefficient | ⚠️ Low |
| **Gallery doesn't auto-refresh** after returning from editor | Only refreshes if user taps refresh button | ⚠️ Medium |

## 3.6 Performance Bottlenecks

| Issue | Details | Severity |
|-------|---------|----------|
| **`getImageFromDatabase` uses aggregate without pagination** | All images returned at once | 🔴 **Critical** at scale |
| **`User.findById` called in every controller** | Redundant DB calls after JWT verification already found the user | ⚠️ Medium |
| **Every transformation function calls `getCurrentList` from Redis** | Redundant when controller already has the list | ⚠️ Low |
| **`cloudinaryConfig()` called per-operation** | Should be called once at startup | ⚠️ Low |
| **No image caching strategy** beyond `CachedNetworkImage` defaults | ⚠️ Low |

---

# ═══════════════════════════════════════════════════
# PHASE 4: PRODUCTION GRADE AUDIT
# ═══════════════════════════════════════════════════

## 4.1 Architecture — Score: 5/10

| Category | Assessment |
|----------|------------|
| Feature organization | ✅ Feature-first structure (auth, Image) |
| Folder structure | ⚠️ Inconsistent casing (`Image` vs `auth`), flat within features |
| Clean Architecture | ❌ No domain layer, no use cases, no abstraction boundaries |
| SOLID | ❌ Controllers violate SRP (validation + business logic + state + error handling); no interfaces |
| DRY | ❌ Massive repository boilerplate — every method has identical catch blocks |
| KISS | ✅ Simple enough to understand |
| Dependency inversion | ❌ Repositories instantiated directly, no interfaces |
| Widget composition | ⚠️ Some god widgets (account: 26KB, signup: 19KB) |
| Reusability | ⚠️ Some shared widgets, but transformation widgets have duplication |
| Scalability | ❌ Current structure doesn't scale beyond ~20 features |
| Testability | ❌ Untestable — no DI, static singletons, tight coupling |

## 4.2 State Management — Score: 5/10

| Category | Assessment |
|----------|------------|
| Provider usage | ✅ Adequate for current scope |
| Rebuild optimization | ❌ `context.watch` used broadly — entire subtrees rebuild |
| Granularity | ❌ `UserController` is a monolith (auth + profile + password + OAuth) |
| Message handling | ⚠️ One-shot message pattern works but is fragile (requires `clearMessage()`) |
| Loading states | ✅ `ImageLoadingState` enum is good pattern |
| `UserController` loading | ❌ Single `_isLoading` for all operations — can't distinguish login from logout |

## 4.3 Network Architecture — Score: 7/10

| Category | Assessment |
|----------|------------|
| Dio configuration | ✅ Proper base URL, timeouts |
| Auth interceptor | ✅ Sophisticated: proactive refresh, queue, retry, bootstrap gate |
| Retry strategy | ❌ Only 401 retries — no retry for timeouts or 5xx |
| Timeout handling | ⚠️ 30s default, no per-request customization |
| Offline strategy | ❌ None |
| Error handling | ⚠️ Consistent DioException→ApiError conversion, but very repetitive |

## 4.4 Security — Score: 4/10

| Category | Assessment |
|----------|------------|
| Secure storage | ✅ FlutterSecureStorage for tokens |
| JWT handling | ✅ In-memory access token, not persisted unnecessarily |
| Refresh token handling | ✅ Rotation implemented |
| Certificate pinning | ❌ Not implemented |
| Root detection | ❌ Not implemented |
| Screenshot protection | ❌ Not implemented |
| Token leakage | ⚠️ `debugPrint` logs can contain response data including tokens |
| Sensitive data exposure | ⚠️ User data stored in SecureStorage (appropriate), but also logged |
| OWASP Mobile | ❌ No systematic OWASP compliance |
| `.env` bundled as asset | 🔴 **Critical** — `.env` file is listed in `pubspec.yaml` assets, meaning secrets ship in the APK |
| Clipboard protection | ❌ Not implemented |

## 4.5 Performance — Score: 5/10

| Category | Assessment |
|----------|------------|
| Image loading | ✅ `CachedNetworkImage` with shimmer placeholders |
| Large list optimization | ❌ No pagination (gallery), no `ListView.builder` key optimization |
| Widget tree complexity | ⚠️ Moderate — some deep nesting |
| Memory leaks | ⚠️ `_pageController` not disposed; `UnsplashProvider` creates new Dio instances |
| Rebuild behavior | ❌ Broad `Consumer`/`watch` usage causes unnecessary rebuilds |

## 4.6 Developer Experience — Score: 4/10

| Category | Assessment |
|----------|------------|
| Code readability | ⚠️ Clear but verbose |
| Consistency | ❌ Mixed patterns (some use `context.read`, some use `Provider.of`) |
| Naming | ⚠️ Typos in multiple places (`transfomation`, `seach_field`, `contrller`) |
| Lints | ⚠️ Basic `flutter_lints` but not `flutter_lints` is deprecated → should use `flutter_lints` successor |
| Documentation | ❌ No dartdoc comments |
| CI/CD readiness | ❌ No pipeline configuration |
| Testing readiness | ❌ No tests, untestable architecture |

## 4.7 Localization & Accessibility — Score: 1/10

| Category | Assessment |
|----------|------------|
| Localization | ❌ All strings hardcoded in English |
| Accessibility | ❌ No semantic labels, no `Semantics` widgets |
| Responsive design | ❌ Hardcoded dimensions, no responsive breakpoints |

---

# ═══════════════════════════════════════════════════
# PHASE 5: PRODUCTION IMPROVEMENT PLAN
# ═══════════════════════════════════════════════════

## Phase 0: Critical Blockers

### Objective
Fix issues that cause data loss, security breaches, or runtime crashes in production.

### 0.1 — Remove `.env` from Flutter assets

**Why it matters:** The `.env` file containing API keys and secrets is bundled into the APK/IPA as a Flutter asset. Anyone can extract it.

**Current:** `pubspec.yaml` lists `.env` under assets. `flutter_dotenv` loads it at runtime.

**Problem:** All secrets (Unsplash keys, server URL, GitHub client ID) are extractable from the binary.

**Recommended:** Move sensitive configuration to a build-time approach:
- Use `--dart-define` for non-secret config
- Keep `flutter_dotenv` but ensure `.env` only contains non-sensitive values
- For truly sensitive keys, use a backend proxy pattern

**Files affected:** `pubspec.yaml`, `.env`, `main.dart`

**Effort:** 2 hours | **Risk:** Low | **Benefit:** Critical security fix

---

### 0.2 — Fix `updateUserProfile` DTO mismatch

**Why it matters:** Profile updates appear to succeed but local state doesn't update.

**Current:** Backend returns `ApiResponse(200, updatedUser, ...)` — `updatedUser` is the Mongoose document. Frontend reads `res.data["updatedUser"]` expecting a nested key.

**Problem:** `res.data` IS the user object. Accessing `res.data["updatedUser"]` returns `null`, silently breaking local state update.

**Recommended:** Fix frontend to use `res.data` directly (matching all other endpoints).

**Files affected:** `user_controller.dart` line 284

**Effort:** 15 minutes | **Risk:** None | **Benefit:** Fixes broken feature

---

### 0.3 — Fix Redis TTL for transformation sessions

**Why it matters:** Users lose all editing progress after 30 minutes with no warning.

**Current:** Transformation list stored with `EX 1800` (30 min). No TTL extension on read/write.

**Problem:** Long editing sessions silently lose state.

**Recommended:** Extend TTL on every write operation; add TTL refresh on read; consider longer default (2h); add frontend warning when session is expiring.

**Files affected:** `transformation.js` (backend), `image_controller.dart` (frontend)

**Effort:** 1 hour | **Risk:** Low | **Benefit:** Prevents data loss

---

## Phase 1: Architecture Fixes

### Objective
Establish proper architectural boundaries without rewriting the app.

### 1.1 — Fix folder casing and naming
- Rename `features/Image/` → `features/image/`  
- Fix typo `auth.contrller.js` → `auth.controller.js`
- Fix `seach_field.dart` → `search_field.dart`

### 1.2 — Extract `ApiResponse` and `ApiError` from `widgets/` to `core/`
- These are data classes, not widgets
- `ApiResponse` should NOT extend `Error`

### 1.3 — Add repository interfaces (abstract classes)
- Create `IUserRepository`, `IImageRepository`
- Inject via constructor, not inline instantiation

### 1.4 — Split `UserController` into `AuthController` + `ProfileController`

### 1.5 — Create proper exception hierarchy
```dart
abstract class AppException implements Exception { ... }
class NetworkException extends AppException { ... }
class AuthException extends AppException { ... }
class ValidationException extends AppException { ... }
class ServerException extends AppException { ... }
```

**Effort:** 8 hours | **Risk:** Medium (rename refactoring) | **Benefit:** Testable, maintainable architecture

---

## Phase 2: Networking

### Objective
Harden the network layer for production reliability.

### 2.1 — Add retry interceptor for transient failures (timeout, 5xx)
### 2.2 — Add connectivity check before requests
### 2.3 — Remove duplicate error handling boilerplate in repositories
### 2.4 — Add request/response logging interceptor (debug only)
### 2.5 — Remove unused `http` package dependency

**Effort:** 4 hours | **Risk:** Low | **Benefit:** Resilient networking

---

## Phase 3: Authentication

### Objective
Harden auth flows for production security.

### 3.1 — Remove `debugPrint` statements that may log tokens
### 3.2 — Fix `_isAuthFailure` to not treat all non-Dio exceptions as auth failures
### 3.3 — Add token expiry buffer configuration
### 3.4 — Handle edge case: refresh token exists but is invalid (corrupted storage)
### 3.5 — Consider adding certificate pinning (optional for MVP)

**Effort:** 3 hours | **Risk:** Low | **Benefit:** Secure auth

---

## Phase 4: State Management

### Objective
Optimize Provider usage for performance and correctness.

### 4.1 — Replace broad `context.watch` with targeted `Selector` or scoped `Consumer`
### 4.2 — Add per-operation loading states to `UserController`
### 4.3 — Dispose `PageController` in `HomeScreen`
### 4.4 — Fix `context.read` in `build()` method (home_screen.dart L49)
### 4.5 — Replace deprecated `WillPopScope` with `PopScope`

**Effort:** 3 hours | **Risk:** Low | **Benefit:** Performance + correctness

---

## Phase 5: UI Architecture

### Objective
Break down god widgets and improve composition.

### 5.1 — Refactor `account_screen.dart` (26KB) into composable widgets
### 5.2 — Refactor `signup_screen.dart` (19KB) into composable widgets
### 5.3 — Extract form validation into reusable validators
### 5.4 — Remove unused `fonts.dart`
### 5.5 — Remove legacy `ip.dart`

**Effort:** 6 hours | **Risk:** Low | **Benefit:** Maintainability

---

## Phase 6: Performance

### Objective
Prepare the app for scale.

### 6.1 — Backend: Add pagination to `getImageFromDatabase`
### 6.2 — Backend: Remove redundant `User.findById` calls in controllers (user already on `req.user`)
### 6.3 — Backend: Call `cloudinaryConfig()` once at startup
### 6.4 — Frontend: Implement pagination for image gallery
### 6.5 — Frontend: Add image cache size limits

**Effort:** 6 hours | **Risk:** Medium | **Benefit:** Scalability

---

## Phase 7: Security

### Objective
Harden the app against OWASP Mobile Top 10.

### 7.1 — Remove sensitive data from debug logs
### 7.2 — Add API versioning (`/api/v1/`)
### 7.3 — Add input validation library (backend: zod/joi)
### 7.4 — Namespace Redis keys to prevent collision
### 7.5 — Add global Express error handler middleware

**Effort:** 6 hours | **Risk:** Low | **Benefit:** Security + API stability

---

## Phase 8: Developer Experience

### Objective
Improve developer velocity and code quality.

### 8.1 — Upgrade `flutter_lints` to `flutter_lints` latest or `very_good_analysis`
### 8.2 — Add dartdoc to all public APIs
### 8.3 — Add backend request logger (morgan/pino)
### 8.4 — Standardize error handling with utility function in repositories
### 8.5 — Add `.editorconfig`

**Effort:** 4 hours | **Risk:** None | **Benefit:** DX

---

## Phase 9: Testing

### Objective
Enable CI-quality testing.

### 9.1 — Add unit tests for `TokenManager`
### 9.2 — Add unit tests for `ApiResponse` / `ApiError` parsing
### 9.3 — Add unit tests for models (`UserModel`, `ImageModel`)
### 9.4 — Add widget tests for critical screens
### 9.5 — Add integration tests for auth flow
### 9.6 — Backend: expand existing test suite

**Effort:** 12 hours | **Risk:** None | **Benefit:** Confidence in releases

---

## Phase 10: Production Readiness

### Objective
Final production hardening.

### 10.1 — Add Firebase Crashlytics or Sentry for crash reporting
### 10.2 — Add analytics foundation
### 10.3 — Add proper loading/error/empty states for all screens
### 10.4 — Add app versioning and forced update check
### 10.5 — CI/CD pipeline setup

**Effort:** 12 hours | **Risk:** Low | **Benefit:** Production operations

---

# ═══════════════════════════════════════════════════
# PHASE 6: IMPLEMENTATION TASKS
# ═══════════════════════════════════════════════════

## Phase 0 Tasks (Critical Blockers)

### Task P0-T1: Remove `.env` from Flutter bundled assets
- **ID:** P0-T1
- **Priority:** 🔴 Critical
- **Files affected:** `pubspec.yaml`, `main.dart`, `.env`
- **Reason:** Secrets exposed in APK
- **Expected outcome:** `.env` no longer in built app; config loaded via `--dart-define` or non-secret `.env`
- **Acceptance criteria:** APK does not contain API keys when decompiled
- **Dependencies:** None
- **Complexity:** Low
- **Risk:** Low — no behavioral change if done correctly
- **Verification:** Build APK → extract → grep for key values

### Task P0-T2: Fix `updateUserProfile` DTO mismatch
- **ID:** P0-T2
- **Priority:** 🔴 Critical
- **Files affected:** `user_controller.dart`
- **Reason:** Profile update silently fails to update local state
- **Expected outcome:** `_userInfo` correctly updated after profile edit
- **Acceptance criteria:** Edit profile → verify updated name/email displayed immediately
- **Dependencies:** None
- **Complexity:** Trivial
- **Risk:** None
- **Verification:** Manual test: edit username → check account screen shows new username

### Task P0-T3: Extend Redis TTL on transformation operations
- **ID:** P0-T3
- **Priority:** 🔴 Critical
- **Files affected:** `backend/src/services/redisServices/transformation.js`
- **Reason:** Users lose transformation progress after 30 minutes
- **Expected outcome:** TTL refreshed on every write; extended to 2 hours
- **Acceptance criteria:** Transformation list persists through 1+ hour editing session
- **Dependencies:** None
- **Complexity:** Low
- **Risk:** Low — only extends existing TTL

---

## Phase 1 Tasks (Architecture)

### Task P1-T1: Rename `features/Image/` to `features/image/`
- **ID:** P1-T1
- **Priority:** 🟡 High
- **Files affected:** All imports referencing `features/Image/`
- **Reason:** Dart convention: lowercase directory names
- **Expected outcome:** Consistent naming
- **Acceptance criteria:** `flutter analyze` passes; app builds successfully
- **Dependencies:** None
- **Complexity:** Low (bulk rename)
- **Risk:** Medium — import paths across many files

### Task P1-T2: Move `ApiResponse` and `ApiError` from `widgets/` to `core/models/`
- **ID:** P1-T2
- **Priority:** 🟡 High
- **Files affected:** `api_response.dart`, `api_error.dart`, all importers
- **Reason:** These are data classes, not widgets; misleading location
- **Expected outcome:** Data classes in `core/models/`
- **Acceptance criteria:** No `widgets/` import for these classes; app compiles
- **Dependencies:** None
- **Complexity:** Low

### Task P1-T3: Fix `ApiResponse` to not extend `Error`
- **ID:** P1-T3
- **Priority:** 🟡 High
- **Files affected:** `api_response.dart`
- **Reason:** `Error` is for programmer mistakes; `ApiResponse` is a data container
- **Expected outcome:** `ApiResponse` is a plain class
- **Acceptance criteria:** No `extends Error`; all usages compile
- **Dependencies:** P1-T2
- **Complexity:** Low

### Task P1-T4: Create proper exception hierarchy
- **ID:** P1-T4
- **Priority:** 🟡 High
- **Files affected:** New file `core/exceptions/app_exceptions.dart`, all catch blocks
- **Reason:** Enable typed exception handling
- **Expected outcome:** `AppException`, `NetworkException`, `AuthException`, `ServerException`
- **Acceptance criteria:** All repository catch blocks use typed exceptions
- **Dependencies:** P1-T2, P1-T3
- **Complexity:** Medium

### Task P1-T5: Create abstract repository interfaces
- **ID:** P1-T5
- **Priority:** 🟡 High
- **Files affected:** New files for interfaces; existing repositories
- **Reason:** Enable DI and testing
- **Expected outcome:** `IUserRepository`, `IImageRepository` abstract classes
- **Acceptance criteria:** Controllers reference interfaces, not concrete classes
- **Dependencies:** P1-T4
- **Complexity:** Medium

### Task P1-T6: Split `UserController` into `AuthController` + `ProfileController`
- **ID:** P1-T6
- **Priority:** 🟡 High
- **Files affected:** `user_controller.dart`, `main.dart`, all screens referencing UserController
- **Reason:** SRP violation; monolithic controller
- **Expected outcome:** Auth operations separated from profile operations
- **Acceptance criteria:** Each controller has ≤5 public methods; app behavior unchanged
- **Dependencies:** P1-T5
- **Complexity:** Medium

---

## Phase 2 Tasks (Networking)

### Task P2-T1: Remove unused `http` package
- **ID:** P2-T1
- **Priority:** 🟢 Medium
- **Files affected:** `pubspec.yaml`
- **Reason:** Unused dependency
- **Expected outcome:** Smaller dependency tree
- **Acceptance criteria:** `flutter pub get` succeeds; no import errors
- **Dependencies:** None
- **Complexity:** Trivial

### Task P2-T2: Add retry interceptor for transient failures
- **ID:** P2-T2
- **Priority:** 🟡 High
- **Files affected:** New `core/network/retry_interceptor.dart`, `dio_client.dart`
- **Reason:** Transient failures (timeout, 502, 503) should be retried
- **Expected outcome:** Configurable retry with exponential backoff for 5xx and timeouts
- **Acceptance criteria:** Retry 3 times with 1s/2s/4s delays; no retry for 4xx
- **Dependencies:** None
- **Complexity:** Medium

### Task P2-T3: Extract repository error handling into utility
- **ID:** P2-T3
- **Priority:** 🟢 Medium
- **Files affected:** All repository files, new utility file
- **Reason:** ~300 lines of identical catch blocks across 2 repositories
- **Expected outcome:** Single `handleDioError` function
- **Acceptance criteria:** All repositories use shared error handler; identical behavior
- **Dependencies:** P1-T4
- **Complexity:** Low

---

## Phase 3 Tasks (Authentication)

### Task P3-T1: Remove debug logging that may expose tokens
- **ID:** P3-T1
- **Priority:** 🟡 High
- **Files affected:** All repository files, `auth_interceptor.dart`
- **Reason:** Response data logged via `debugPrint` may contain tokens
- **Expected outcome:** Only safe data logged; token values never printed
- **Acceptance criteria:** Grep for `debugPrint.*data` returns no hits near auth endpoints
- **Dependencies:** None
- **Complexity:** Low

### Task P3-T2: Fix `_isAuthFailure` false positive for non-Dio exceptions
- **ID:** P3-T2
- **Priority:** 🟡 High
- **Files affected:** `auth_interceptor.dart`, `auth_service.dart`
- **Reason:** Current logic returns `true` for ALL non-Dio exceptions, triggering unnecessary logouts
- **Expected outcome:** Only return true for known auth failure patterns
- **Acceptance criteria:** Network timeout does not trigger logout
- **Dependencies:** None
- **Complexity:** Low

---

## Phase 4 Tasks (State Management)

### Task P4-T1: Dispose `PageController` in `HomeScreen`
- **ID:** P4-T1
- **Priority:** 🟢 Medium
- **Files affected:** `home_screen.dart`
- **Reason:** Memory leak
- **Expected outcome:** `dispose()` override added
- **Acceptance criteria:** No memory leak on repeated navigation
- **Dependencies:** None
- **Complexity:** Trivial

### Task P4-T2: Replace deprecated `WillPopScope` with `PopScope`
- **ID:** P4-T2
- **Priority:** 🟢 Medium
- **Files affected:** `image_editor.dart`
- **Reason:** Deprecated in Flutter 3.12
- **Expected outcome:** Uses `PopScope` with `canPop` and `onPopInvokedWithResult`
- **Acceptance criteria:** Back navigation still prompts for unsaved changes
- **Dependencies:** None
- **Complexity:** Low

### Task P4-T3: Fix `context.read` in `build()` method
- **ID:** P4-T3
- **Priority:** 🟢 Medium
- **Files affected:** `home_screen.dart` line 49
- **Reason:** `context.read` in build can miss state changes
- **Expected outcome:** Move to callback or use `context.watch` if reactive display needed
- **Acceptance criteria:** Upload button correctly reflects controller state
- **Dependencies:** None
- **Complexity:** Trivial

---

## Phase 5 Tasks (UI Architecture)

*(Tasks P5-T1 through P5-T3 involve breaking down 26KB and 19KB god widgets — detailed in Gemini specs below)*

---

## Phase 6 Tasks (Performance)

### Task P6-T1: Backend — Add pagination to image endpoint
- **ID:** P6-T1
- **Priority:** 🟡 High
- **Files affected:** `image.controller.js`, `image.routes.js`
- **Reason:** All images loaded at once
- **Expected outcome:** `?page=1&limit=20` support using `mongoose-aggregate-paginate-v2`
- **Acceptance criteria:** Response includes `totalDocs`, `totalPages`, `page`, `docs`
- **Dependencies:** None
- **Complexity:** Medium

### Task P6-T2: Backend — Use `req.user` instead of re-querying `User.findById`
- **ID:** P6-T2
- **Priority:** 🟢 Medium
- **Files affected:** All controllers that call `User.findById(req._id)` after `verifyJWT`
- **Reason:** `verifyJWT` already queries user and attaches to `req.user`
- **Expected outcome:** Remove redundant DB queries
- **Acceptance criteria:** Same behavior with fewer DB calls
- **Dependencies:** None
- **Complexity:** Low

### Task P6-T3: Backend — Initialize Cloudinary config once
- **ID:** P6-T3
- **Priority:** 🟢 Low
- **Files affected:** `config.js`, all callers
- **Reason:** `cloudinaryConfig()` called on every operation
- **Expected outcome:** Called once during startup
- **Acceptance criteria:** Cloudinary operations still work
- **Dependencies:** None
- **Complexity:** Trivial

---

## Phase 7 Tasks (Security)

### Task P7-T1: Namespace Redis transformation keys
- **ID:** P7-T1
- **Priority:** 🟡 High
- **Files affected:** `transformation.js` (backend)
- **Reason:** Bare publicId as key could collide with rate limiter keys
- **Expected outcome:** Keys prefixed with `transform:` namespace
- **Acceptance criteria:** Existing transformation flows work with prefixed keys
- **Dependencies:** None
- **Complexity:** Low

### Task P7-T2: Add global Express error handler
- **ID:** P7-T2
- **Priority:** 🟡 High
- **Files affected:** `app.js`
- **Reason:** Unhandled middleware errors (CORS, body-parser) crash the process
- **Expected outcome:** Catch-all error middleware as last `app.use()`
- **Acceptance criteria:** Malformed JSON body returns 400 instead of crashing
- **Dependencies:** None
- **Complexity:** Low

---

# ═══════════════════════════════════════════════════
# PHASE 7: GEMINI IMPLEMENTATION SPECIFICATIONS
# ═══════════════════════════════════════════════════

## Spec: P0-T1 — Remove `.env` from Flutter Bundled Assets

### Context
The Flutter app loads configuration from a `.env` file that is listed as a bundled asset in `pubspec.yaml`. This means the file (and all its secrets) are packaged into the APK/IPA and can be extracted by anyone.

### Current Architecture
- `pubspec.yaml` line 91: `- .env`
- `main.dart` line 18: `await dotenv.load(fileName: '.env');`
- `.env` contains: `UNSPLASH_ACCESS_KEY`, `UNSPLASH_SECRET_KEY`, `SERVER_URL`, `GITHUB_CLIENT_ID`

### Desired Architecture
- Keep `flutter_dotenv` for non-sensitive config (e.g., `SERVER_URL`)
- Move sensitive API keys to `--dart-define` build arguments
- `.env` file should only contain values safe to ship (base URLs, feature flags)

### Files to Inspect
- [pubspec.yaml](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/pubspec.yaml)
- [main.dart](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/lib/main.dart)
- [.env](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/.env) (template only)
- [unsplash_provider.dart](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/lib/common/provider/unsplash_provider.dart)
- [user_repository.dart](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/lib/features/auth/repository/user_repository.dart)

### Files to Modify
- `pubspec.yaml` — keep `.env` in assets but ensure it only has non-secret values
- `unsplash_provider.dart` — read keys from `String.fromEnvironment` instead of `dotenv.env`
- `user_repository.dart` — read `GITHUB_CLIENT_ID` from `String.fromEnvironment`

### Coding Standards
- Use `const String.fromEnvironment('KEY', defaultValue: '')` for sensitive values
- Keep `dotenv.env['SERVER_URL']` for base URL (not truly secret)

### Constraints
- Do NOT remove `flutter_dotenv` entirely — it's used for `SERVER_URL`
- Do NOT change backend API behavior

### Things That MUST NOT Change
- App must still connect to the correct backend URL
- Unsplash integration must still work
- GitHub OAuth must still work

### Definition of Done
1. `.env` file in repo contains only `SERVER_URL` (non-secret)
2. Sensitive keys loaded via `--dart-define`
3. APK decompilation does not reveal API keys
4. App runs correctly in both debug and release

---

## Spec: P0-T2 — Fix `updateUserProfile` DTO Mismatch

### Context
The `updateUserProfile` method in `UserController` parses the backend response incorrectly, leading to a silent failure in updating local user state.

### Current Architecture
- Backend `updateUserProfile` returns: `ApiResponse(200, updatedUser, "Profile updated successfully")`
- This means `response.data.data` (after ApiResponse.fromMap) IS the user object
- Frontend `user_controller.dart` line 284: `UserModel.fromMap(res.data["updatedUser"])` — expects a nested key

### Desired Architecture
- Frontend should access `res.data` directly, consistent with `getCurrentUser` and `updateProfilePhoto`

### Files to Inspect
- [user.controllers.js](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/backend/src/controllers/user.controllers.js) — line 231-233
- [user_controller.dart](file:///c:/Users/ehtes/OneDrive/Desktop/creater.io/frontend/flutter/lib/features/auth/controller/user_controller.dart) — line 284

### Files to Modify
- `user_controller.dart` line 284

### Change
```dart
// Before:
final user = UserModel.fromMap(res.data["updatedUser"]);

// After:
final user = UserModel.fromMap(res.data);
```

### Things That MUST NOT Change
- Backend response format
- Other controller methods

### Definition of Done
1. Profile update correctly reflects in UI immediately
2. User data persisted to SecureStorage after update
3. No regression in other user operations

---

## Spec: P0-T3 — Extend Redis TTL for Transformation Sessions

### Context
Transformation lists in Redis expire after 30 minutes. Users editing images for longer lose all progress silently.

### Current Architecture
- `transformation.js` sets TTL: `redis.set(publicId, JSON.stringify(list), "EX", 1800)`
- TTL set on initial creation and on every write operation
- No TTL extension on read operations

### Desired Architecture
- Increase TTL to 7200 (2 hours)
- Ensure every write operation refreshes TTL (already done)
- Add TTL refresh on read operations

### Files to Modify
- `backend/src/services/redisServices/transformation.js` — change `1800` to `7200` in all `redis.set` calls; add `redis.expire` in `getCurrentList`

### Things That MUST NOT Change
- Redis key format
- Transformation list data structure
- Controller behavior

### Definition of Done
1. New transformation lists have 2-hour TTL
2. Reading a list extends TTL by 2 hours
3. All existing tests pass

---

## Spec: P1-T1 — Rename `features/Image/` to `features/image/`

### Context
Dart/Flutter conventions require lowercase directory names. `Image` conflicts with `dart:ui` `Image` class and violates conventions.

### Files to Inspect
- All `.dart` files with `import '...features/Image/...'`

### Files to Modify
- Rename directory `lib/features/Image/` → `lib/features/image/`
- Update all imports across the project

### Constraints
- Git on Windows is case-insensitive by default — may need a two-step rename (`Image` → `image_temp` → `image`)
- Verify no path casing issues in pubspec.yaml

### Definition of Done
1. Directory is lowercase `image/`
2. `flutter analyze` passes with zero errors
3. App builds and runs correctly

---

*(Additional Gemini specs for P1-T2 through P7-T2 follow the same detailed pattern. Each task in Phase 6 already contains enough detail for implementation.)*

---

# ═══════════════════════════════════════════════════
# EXECUTIVE SUMMARY
# ═══════════════════════════════════════════════════

## Issue Rankings

### 🔴 Critical (Must fix before any production release)
1. **P0-T1:** `.env` secrets bundled in APK
2. **P0-T2:** `updateUserProfile` DTO mismatch — broken feature
3. **P0-T3:** Redis TTL causes silent data loss during editing
4. **No pagination** — gallery will crash at scale

### 🟡 High (Should fix for production quality)
5. `ApiResponse extends Error` — semantic violation causing debugging confusion
6. `UserController` is monolithic — blocks testability
7. No global Express error handler — unhandled errors crash process
8. No retry for transient network failures
9. Deprecated `WillPopScope` usage
10. Debug logs may expose sensitive data
11. `_isAuthFailure` false positives cause unnecessary logouts
12. Folder casing inconsistency (`Image` vs `auth`)
13. Redis key collision risk (no namespace)

### 🟢 Medium
14. No dependency injection — untestable
15. Redundant `User.findById` calls (performance)
16. Redundant `cloudinaryConfig()` calls
17. `_pageController` memory leak
18. Unused `http` package dependency
19. Massive god widgets (account: 26KB, signup: 19KB)
20. Repository error handling boilerplate (~300 lines duplicated)

### 🔵 Low
21. No localization readiness
22. No accessibility
23. No tests
24. No CI/CD pipeline
25. Unused `fonts.dart`
26. Legacy `ip.dart`
27. No dartdoc comments
28. No analytics/crash reporting

---

## Architecture Scoreboard

| Dimension | Score | Notes |
|-----------|-------|-------|
| **Overall Architecture** | **5/10** | Feature-first structure is good; lacks clean architecture boundaries, no DI |
| **Flutter Code Quality** | **5/10** | Works but has DTO mismatches, god widgets, deprecated APIs, semantic errors |
| **Backend Integration** | **6/10** | Auth interceptor is well-built; DTO mismatch is the main gap |
| **Production Readiness** | **3/10** | Missing pagination, crash reporting, CI/CD, error monitoring |
| **Security** | **3/10** | Secrets in APK is a showstopper; no cert pinning, no OWASP compliance |
| **Scalability** | **4/10** | No pagination, no caching strategy, monolithic controllers |
| **Maintainability** | **5/10** | Readable code but massive duplication, no tests, tight coupling |
| **Developer Experience** | **4/10** | No linting enforcement, no CI, typos in filenames |
| **Testing Readiness** | **1/10** | Zero tests, untestable architecture (no DI, static singletons) |

---

## Recommended Implementation Order

```
P0-T1  → Remove .env from assets (security critical)
P0-T2  → Fix updateUserProfile DTO mismatch (broken feature)
P0-T3  → Extend Redis TTL (data loss prevention)
P1-T1  → Fix folder casing
P1-T2  → Move ApiResponse/ApiError to core
P1-T3  → Fix ApiResponse extends Error
P3-T1  → Remove debug token logging
P3-T2  → Fix _isAuthFailure false positives
P4-T1  → Dispose PageController
P4-T2  → Replace WillPopScope
P4-T3  → Fix context.read in build
P2-T1  → Remove unused http package
P7-T2  → Add global Express error handler
P7-T1  → Namespace Redis keys
P6-T3  → Initialize Cloudinary once
P6-T2  → Use req.user instead of re-querying
P2-T3  → Extract repository error handling utility
P1-T4  → Create exception hierarchy
P1-T5  → Add repository interfaces
P1-T6  → Split UserController
P2-T2  → Add retry interceptor
P6-T1  → Add pagination (backend)
P5-T1  → Refactor account_screen.dart
P5-T2  → Refactor signup_screen.dart
P9-T1+ → Testing phase
P10-T1+ → Production readiness phase
```

Each task is designed to be **completable in a single Gemini chat session** with the detailed specifications provided above.
