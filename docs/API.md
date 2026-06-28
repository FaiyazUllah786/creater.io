# Creater.io — API Reference

> Complete endpoint documentation derived from the actual route definitions.
>
> **Base URL**: `http://localhost:<PORT>` (development) or your deployed server URL.

---

## Response Format

All endpoints return a consistent JSON structure:

**Success:**
```json
{
  "statusCode": 200,
  "data": { ... },
  "message": "Description of result",
  "success": true
}
```

**Error:**
```json
{
  "statusCode": 422,
  "message": "Description of error",
  "success": false,
  "errors": [],
  "data": null
}
```

In development mode (`NODE_ENV=development`), error responses also include a `stack` field.

---

## Authentication

Endpoints marked with 🔒 require a valid JWT access token, provided via:
- **Cookie**: `accessToken` (set automatically on login/OAuth)
- **Header**: `Authorization: Bearer <accessToken>`

---

## Rate Limiting

| Limiter | Window | Max Requests | Applied To |
|---------|--------|-------------|------------|
| `authLimiter` | 5 min | 10 | Authentication endpoints (IP-based) |
| `refreshLimiter` | 15 min | 50 | Token refresh (user/IP-based) |
| `cloudinaryLimiter` | 15 min | 50 | Image operations (user/IP-based) |
| `generalLimiter` | 15 min | 1000 | All routes (user/IP-based) |

Rate limiting is skipped in development mode (`NODE_ENV=development`). Counters are stored in Redis.

---

## Health

### `GET /health`

Returns the health status of MongoDB and Redis.

**Auth**: None  
**Rate Limit**: `generalLimiter`

**Response:**

| Status | HTTP Code | Meaning |
|--------|-----------|---------|
| `ok` | 200 | Both MongoDB and Redis are healthy |
| `degraded` | 200 | MongoDB healthy, Redis unavailable |
| `error` | 503 | MongoDB is down |

```json
{
  "status": "ok",
  "mongodb": true,
  "redis": true
}
```

---

## User Routes (`/user/*`)

### `POST /user/auth/register`

Create a new user account.

**Auth**: None  
**Rate Limit**: `authLimiter`  
**Content-Type**: `multipart/form-data` (if uploading profile photo) or `application/json`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userName` | string | ✅ | Must be unique, stored lowercase |
| `email` | string | ✅ | Must be unique, valid format, not `@github.user` / `@google.user` |
| `password` | string | ✅ | Min 6 characters |
| `firstName` | string | ❌ | |
| `lastName` | string | ❌ | |
| `profilePhoto` | file | ❌ | JPEG, PNG, or WEBP, max 5MB |

**Success**: `201` — Returns user object (without password).

---

### `POST /user/auth/login`

Authenticate with username/email and password.

**Auth**: None  
**Rate Limit**: `authLimiter`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userName` | string | ✅* | Either `userName` or `email` required |
| `email` | string | ✅* | Either `userName` or `email` required |
| `password` | string | ✅ | |

**Success**: `200` — Returns `{ user, accessToken, refreshToken }`. Sets `accessToken` and `refreshToken` cookies.

---

### `POST /user/auth/logout` 🔒

Log out the current user. Clears refresh token from database and removes cookies.

**Auth**: Required  
**Rate Limit**: `generalLimiter`

**Success**: `200` — Clears `accessToken` and `refreshToken` cookies.

---

### `POST /user/auth/refresh-tokens`

Exchange a valid refresh token for a new access/refresh token pair.

**Auth**: None (uses refresh token from cookie or body)  
**Rate Limit**: `refreshLimiter`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `refreshToken` | string | ❌ | If not in cookies, provide in body |

**Success**: `200` — Returns `{ user, accessToken, refreshToken }`. Sets new cookies.

**Errors**:
- `401` — Missing, expired, or invalid refresh token
- `403` — Refresh token has been revoked (token reuse detected)

---

### `GET /user/current-user` 🔒

Get the currently authenticated user's profile.

**Auth**: Required  
**Rate Limit**: `generalLimiter`

**Success**: `200` — Returns user object (without password/refreshToken).

---

### `POST /user/delete-user` 🔒

Permanently delete the current user's account. Cleans up all images from Cloudinary and MongoDB.

**Auth**: Required  
**Rate Limit**: `authLimiter`

**Success**: `200` — Account, images, and profile photo deleted. Cookies cleared.

---

### `POST /user/profile-photo` 🔒

Upload or replace the user's profile photo.

**Auth**: Required  
**Rate Limit**: `generalLimiter`  
**Content-Type**: `multipart/form-data`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `profilePhoto` | file | ✅ | JPEG, PNG, or WEBP, max 5MB |

**Success**: `200` — Returns updated user object. Old profile photo is deleted from Cloudinary.

---

### `POST /user/update-account` 🔒

Update user profile fields.

**Auth**: Required  
**Rate Limit**: `generalLimiter`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userName` | string | ❌ | Must be unique if changed |
| `email` | string | ❌ | Must be unique, valid format, not reserved domain |
| `firstName` | string | ❌ | |
| `lastName` | string | ❌ | |

**Success**: `200` — Returns updated user object.

---

### `POST /user/update-password` 🔒

Change the current user's password.

**Auth**: Required  
**Rate Limit**: `authLimiter`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `oldPassword` | string | ✅ | Must match current password |
| `newPassword` | string | ✅ | Will be bcrypt-hashed on save |

**Success**: `200`

---

## OAuth Routes (`/auth/*`)

All OAuth routes use `authLimiter`.

### `GET /auth/github`

Initiates GitHub OAuth flow. Redirects the user to GitHub's authorization page.

**Scope**: `user:email`

---

### `GET /auth/github/callback`

GitHub OAuth callback. On success, sets JWT cookies and redirects to `CLIENT_URL/`. On failure, redirects to `CLIENT_URL/auth/failure`.

---

### `GET /auth/google`

Initiates Google OAuth flow. Redirects to Google's consent screen.

**Scope**: `profile`, `email`

---

### `GET /auth/google/callback`

Google OAuth callback. Same behavior as GitHub callback.

---

### `POST /auth/google/mobile`

Google sign-in for mobile apps. The Flutter app obtains an `idToken` from Google Sign-In and sends it for verification.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `idToken` | string | ✅ | Google ID token from native sign-in |

**Success**: `200` — Returns `{ userWithoutPass, accessToken, refreshToken }`.

---

### `POST /auth/github/mobile`

GitHub sign-in for mobile apps. The Flutter app performs the OAuth flow via browser and sends the authorization code.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `code` | string | ✅ | GitHub authorization code |

**Success**: `200` — Returns `{ userWithoutPass, accessToken, refreshToken }`.

---

## Image Routes (`/image/*`)

All image routes use `cloudinaryLimiter`.

### `POST /image/upload` 🔒

Upload one or more images to Cloudinary and save records to MongoDB.

**Content-Type**: `multipart/form-data`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `images` | file[] | ✅ | One or more image files (JPEG, PNG, WEBP), max 5MB each |

**Success**: `201` — Returns array of image documents.

---

### `GET /image/get-images` 🔒

Get paginated list of the current user's images.

| Query Param | Type | Default | Notes |
|-------------|------|---------|-------|
| `page` | number | 1 | Page number |
| `limit` | number | 10 | Images per page |

**Success**: `200` — Returns paginated result with `docs`, `totalDocs`, `totalPages`, `page`, etc.

---

### `POST /image/save-image` 🔒

Save an image from a Cloudinary URL to the user's gallery. Validates that the URL is an `https://res.cloudinary.com` domain.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imageUrl` | string | ✅ | Must be a valid, accessible `res.cloudinary.com` HTTPS URL |

**Success**: `201` — Returns saved image document.

---

### `POST /image/delete-image` 🔒

Delete an image from Cloudinary and MongoDB. Users can only delete their own images.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imageId` | string | ✅ | MongoDB ObjectId of the image |

**Success**: `200`  
**Error**: `403` — If image belongs to another user.

---

### `POST /image/add-transformation` 🔒

Add a transformation to the image's editing stack.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imagePublicId` | string | ✅ | Cloudinary public ID |
| `transformation` | object | ✅ | Must include `effectType` and effect-specific params |

**Success**: `200` — Returns `{ previewUrl, transfomationList }`.

See [ARCHITECTURE.md → AI Transformation Pipeline](ARCHITECTURE.md#ai-transformation-pipeline) for the full list of `effectType` values and their parameters.

---

### `POST /image/update-transformation` 🔒

Update an existing transformation in the stack.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imagePublicId` | string | ✅ | Cloudinary public ID |
| `transformation` | object | ✅ | Updated transformation object |
| `transformationId` | string | ✅ | UUID of the transformation to update |

**Success**: `200` — Returns `{ previewUrl, transfomationList }`.

---

### `POST /image/delete-transformation` 🔒

Remove a single transformation from the stack.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imagePublicId` | string | ✅ | Cloudinary public ID |
| `transformationId` | string | ✅ | UUID of the transformation to remove |

**Success**: `200` — Returns `{ previewUrl, transfomationList }`.

---

### `POST /image/clear-transformation` 🔒

Clear the entire transformation stack for an image.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imagePublicId` | string | ✅ | Cloudinary public ID |

**Success**: `200` — Returns `{ previewUrl, transfomationList: [] }`.

---

### `POST /image/save` 🔒

Compose all stacked transformations into a final image, upload it to Cloudinary, and save it to the user's gallery.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `imagePublicId` | string | ✅ | Cloudinary public ID of the source image |

**Success**: `201` — Returns the saved image document (or `{ finalUrl }` if save to DB fails).

---

## Unsplash Routes (`/unsplash/*`)

All Unsplash routes require JWT authentication and use `generalLimiter`.

### `GET /unsplash/photos` 🔒

Search Unsplash for photos. Results are cached in Redis for 1 hour.

| Query Param | Type | Default | Notes |
|-------------|------|---------|-------|
| `query` | string | `"latest"` | Search query |
| `page` | number | 1 | Page number |
| `perPage` | number | 10 | Results per page |
| `orientation` | string | — | `landscape`, `portrait`, or `squarish` |

**Success**: `200` — Returns Unsplash search results.

---

### `POST /unsplash/photos/:photoId/download` 🔒

Track a photo download with Unsplash (required by their API guidelines).

| Path Param | Type | Required | Notes |
|------------|------|----------|-------|
| `photoId` | string | ✅ | Unsplash photo ID |

**Success**: `200` — Returns `{ url }` with direct download URL.
