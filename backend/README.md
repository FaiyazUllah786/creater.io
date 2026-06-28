# Creater.io — Backend

> Node.js/Express REST API powering the Creater.io AI image editing platform.

---

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment template and configure
cp ENV.txt .env
# Edit .env — see "Environment Variables" below

# Start development server (with hot reload)
npm run dev

# Start production server
npm start

# Run tests
npm test
```

---

## Scripts

| Script | Command | Description |
|--------|---------|-------------|
| `dev` | `nodemon src/index.js` | Development server with auto-restart |
| `start` | `node src/index.js` | Production server |
| `test` | `vitest --run` | Run test suite |

---

## Environment Variables

Copy `ENV.txt` to `.env` and fill in all values. The server will **refuse to start** if required variables are missing or malformed.

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | ✅ | Server port (e.g., `5000`) |
| `NODE_ENV` | ✅ | `development` or `production` |
| `MONGODB_URI` | ✅ | MongoDB connection string |
| `REDIS_URL` | ✅ | Redis connection URL |
| `ACCESS_TOKEN_SECRET` | ✅ | JWT signing secret (min 32 chars) |
| `ACCESS_TOKEN_EXPIRY` | ✅ | Access token TTL (e.g., `1h`) |
| `REFRESH_TOKEN_SECRET` | ✅ | JWT signing secret (min 32 chars) |
| `REFRESH_TOKEN_EXPIRY` | ✅ | Refresh token TTL (e.g., `30d`) |
| `FRONTEND_URL` or `CLIENT_URL` | ✅ | Frontend URL for CORS and redirects |
| `CORS_ORIGIN` | ❌ | Additional allowed origins (comma-separated) |
| `SERVER_URL` | ❌ | Backend URL (used for OAuth callback URLs) |
| `CLOUD_NAME` | ❌* | Cloudinary cloud name |
| `API_KEY` | ❌* | Cloudinary API key |
| `API_SECRET` | ❌* | Cloudinary API secret |
| `GITHUB_CLIENT_ID` | ❌ | GitHub OAuth client ID (web) |
| `GITHUB_CLIENT_SECRET` | ❌ | GitHub OAuth client secret (web) |
| `GOOGLE_CLIENT_ID` | ❌ | Google OAuth client ID (web) |
| `GOOGLE_CLIENT_SECRET` | ❌ | Google OAuth client secret (web) |
| `GOOGLE_ANDROID_CLIENT_ID` | ❌ | Google OAuth client ID (mobile) |
| `GITHUB_ANDROID_CLIENT_ID` | ❌ | GitHub OAuth client ID (mobile) |
| `GITHUB_ANDROID_CLIENT_SECRET` | ❌ | GitHub OAuth client secret (mobile) |
| `UNSPLASH_ACCESS_KEY` | ❌ | Unsplash API access key |

*Required for image features to work.

See [`ENV.txt`](ENV.txt) for the full template.

---

## Project Structure

```
src/
├── index.js                  ← Entry: env validation → DB → Redis → listen
├── app.js                    ← Express setup: middleware chain + route mounting
├── constants.js              ← DB_NAME constant
├── controllers/
│   ├── auth.contrller.js     ← OAuth handlers (GitHub/Google, web + mobile)
│   ├── user.controllers.js   ← Registration, login, logout, profile CRUD
│   ├── image.controller.js   ← Upload, gallery, save, delete
│   ├── transformation.controller.js ← AI transformation stack management
│   └── unsplash.controller.js ← Unsplash search proxy
├── db/
│   └── db.js                 ← MongoDB connection (Mongoose)
├── middlewares/
│   ├── auth.middleware.js    ← JWT verify, token generation, Passport exports
│   ├── errorHandler.js       ← Global error handler
│   ├── multer.middleware.js  ← File upload (disk, 5MB, image-only)
│   └── rateLimit.middleware.js ← Redis-backed rate limiters (4 tiers)
├── models/
│   ├── user.model.js         ← User schema + bcrypt + JWT methods
│   └── image.model.js        ← Image schema + aggregate pagination
├── passport/
│   └── auth.passport.js     ← GitHub/Google Passport strategies
├── redis/
│   └── redis.js              ← ioredis connection + health guard
├── routes/
│   ├── auth.routes.js        ← /auth/* OAuth routes
│   ├── user.routes.js        ← /user/* auth + profile routes
│   ├── image.routes.js       ← /image/* upload + transformation routes
│   ├── unsplash.routes.js    ← /unsplash/* stock photo routes
│   └── health.routes.js      ← /health endpoint
├── services/
│   ├── cloudinary/
│   │   ├── config.js         ← Cloudinary v2 configuration
│   │   ├── cloudinary.js     ← Upload, delete, transform
│   │   ├── transfomationHelper.js ← effectType → function dispatcher
│   │   └── imageTransformations.js ← 10 AI transformation functions
│   ├── redisServices/
│   │   └── transformation.js ← Transformation stack CRUD (2h TTL)
│   └── unsplash.service.js   ← Unsplash API client with Redis caching
└── utils/
    ├── ApiError.js            ← Structured error class
    ├── ApiResponse.js         ← Structured response class
    ├── asyncHandler.js        ← Async middleware wrapper
    ├── cookieOptions.js       ← Cookie configuration
    └── validateEnv.js         ← Startup environment validation
```

---

## Testing

Tests are located in `__tests__/` directories alongside the code they test:

```
controllers/__tests__/    ← Auth, image, OAuth collision, Redis failure, cookies
middlewares/__tests__/    ← JWT verification, rate limiting
routes/__tests__/         ← Health endpoint
utils/__tests__/          ← Environment validation
redis/__tests__/          ← Redis connection
```

Run with:
```bash
npm test
```

---

## API Reference

See [docs/API.md](../docs/API.md) for the complete endpoint documentation.

## Architecture

See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for the system architecture overview.
