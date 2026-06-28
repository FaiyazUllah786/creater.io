# Contributing to Creater.io

Thank you for your interest in contributing! This guide will help you get started.

---

## Development Setup

### Prerequisites

- **Node.js** 18.x or 20.x
- **Flutter** 3.41.3+ (stable channel)
- **MongoDB** (local or Atlas)
- **Redis** (local or cloud)
- **Cloudinary** account (free tier works for development)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/FaiyazUllah786/creater.io.git
cd creater.io

# Backend setup
cd backend
npm install
cp ENV.txt .env
# Edit .env with your values
npm run dev

# Flutter setup (in a new terminal)
cd frontend/flutter
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for full setup details.

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code. All PRs merge here. |
| `feature/<name>` | New features |
| `fix/<name>` | Bug fixes |
| `docs/<name>` | Documentation changes |
| `refactor/<name>` | Code refactoring without behavior change |

**Example**: `feature/image-cropping`, `fix/oauth-redirect-loop`, `docs/api-reference`

---

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`

**Scopes**: `backend`, `flutter`, `ci`, `docs`

**Examples**:
```
feat(backend): add image cropping endpoint
fix(flutter): resolve OAuth redirect on Android
docs: update API reference with new endpoints
test(backend): add unit tests for rate limiter
chore: update dependencies
```

---

## Pull Request Process

1. **Fork** the repository and create your branch from `main`
2. **Make your changes** following the coding standards below
3. **Write/update tests** if applicable
4. **Ensure CI passes**:
   - Backend: `cd backend && npm test`
   - Flutter: `cd frontend/flutter && flutter analyze && flutter test`
5. **Submit a PR** with a clear description of what changed and why
6. **Respond to review feedback** promptly

### PR Template

```markdown
## What does this PR do?
Brief description of the change.

## Why is this change needed?
Context and motivation.

## How was this tested?
- [ ] Unit tests pass
- [ ] Manual testing on [device/browser]
- [ ] CI passes

## Screenshots (if UI change)
```

---

## Code Style

### Backend (Node.js)

The project uses [Prettier](https://prettier.io/) with the following configuration (`.prettierrc`):

| Setting | Value |
|---------|-------|
| Print width | 100 |
| Tab width | 2 |
| Semicolons | Yes |
| Quotes | Double |
| Trailing comma | ES5 |
| Arrow parens | Always |
| End of line | LF |

**Key conventions**:
- ES modules (`import`/`export`, not `require`)
- Async/await over raw Promises
- All async route handlers wrapped in `asyncHandler()`
- Errors thrown as `ApiError` instances with appropriate HTTP status codes
- Responses wrapped in `ApiResponse` instances

### Frontend (Flutter/Dart)

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Format with `dart format .`
- Analyze with `flutter analyze`
- Use `const` constructors wherever possible
- Follow the feature-first directory structure:
  ```
  features/<feature>/
  ├── controller/
  ├── repository/
  ├── screens/
  └── widgets/
  ```

### General

- EditorConfig (`.editorconfig`) enforces:
  - UTF-8 encoding
  - LF line endings
  - 2-space indentation
  - Trailing whitespace trimmed (except Markdown)
  - Final newline inserted

---

## Testing

### Backend

The backend uses [Vitest](https://vitest.dev/) as the test runner with [Supertest](https://github.com/ladjs/supertest) for HTTP assertions and [fast-check](https://github.com/dubzzz/fast-check) for property-based testing.

```bash
cd backend
npm test           # Run all tests
```

**Existing test coverage**:
- Controller tests (auth, image, OAuth collision, Redis failure, cookie handling)
- Middleware tests (JWT verification, rate limiting)
- Route tests (health endpoint)
- Utility tests (environment validation)
- Infrastructure tests (Redis connection)

**Conventions**:
- Test files live in `__tests__/` directories alongside the code they test
- File naming: `<module>.test.js`

### Frontend

```bash
cd frontend/flutter
flutter test       # Run all tests
```

---

## Project Structure

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed architecture documentation.

---

## Need Help?

- Check the [API Reference](docs/API.md) for endpoint documentation
- Read the [Architecture Guide](docs/ARCHITECTURE.md) for system design
- Review the [Security Overview](docs/SECURITY.md) for security practices
- See the [Deployment Guide](docs/DEPLOYMENT.md) for setup and deployment
