# Creater.io — Flutter Frontend

> Cross-platform mobile app (Android, iOS, Web) for the Creater.io AI image editing platform.

---

## Features

- **AI Image Editor** — 10 AI-powered transformations (background replace, object remove, recolor, upscale, etc.)
- **Non-destructive editing** — Stack and preview transformations before committing
- **Image Gallery** — Paginated gallery with staggered grid layout
- **Unsplash Integration** — Search and import stock photos
- **OAuth Authentication** — Google and GitHub sign-in (native mobile flow)
- **Profile Management** — Update profile, photo, and password
- **Dark/Light Theme** — System-aware with manual override
- **Firebase Integration** — Crashlytics and Analytics

---

## Architecture

The app follows a **feature-first** directory structure with **Provider** for state management and a **Repository** pattern for data access.

```
lib/
├── main.dart                     ← App entry, Firebase init, provider setup
├── app_launcher.dart             ← Auth check → route to home or login
├── router.dart                   ← Named route definitions
├── splash_screen.dart            ← Animated splash
├── home_screen.dart              ← Bottom navigation (gallery, editor, account)
├── common/
│   ├── theme/                    ← AppTheme, colors, ThemeProvider
│   ├── provider/                 ← UnsplashProvider
│   ├── widgets/                  ← Shared widgets (snackbar, shimmer, image viewer, etc.)
│   ├── storage.dart              ← FlutterSecureStorage wrapper
│   ├── message.dart              ← Snackbar utilities
│   ├── navigator_key.dart        ← Global navigator key
│   └── utils.dart                ← General utilities
├── core/
│   ├── config/app_config.dart    ← Compile-time environment variables
│   ├── network/
│   │   ├── dio_client.dart       ← Singleton Dio HTTP client
│   │   ├── auth_interceptor.dart ← Auto-attach tokens, auto-refresh on 401
│   │   ├── retry_interceptor.dart← Network retry logic
│   │   ├── auth_service.dart     ← OAuth service (Google/GitHub)
│   │   ├── auth_bootstrap.dart   ← Initial auth state check
│   │   └── token_manager.dart    ← Secure token storage
│   ├── models/                   ← API response/error models
│   ├── exceptions/               ← Custom exception classes
│   ├── services/                 ← Analytics, update checker
│   └── utils/                    ← Error handler, validators
├── model/
│   ├── user_model.dart           ← User data model
│   └── image_model.dart          ← Image data model
└── features/
    ├── auth/
    │   ├── controller/           ← AuthController, ProfileController
    │   ├── repository/           ← IUserRepository, UserRepository
    │   ├── screens/              ← Login, Signup, Account, UpdateProfile, UpdatePassword
    │   └── widgets/
    └── image/
        ├── controller/           ← ImageController
        ├── repository/           ← IImageRepository, ImageRepository
        ├── screens/              ← ImageGallery, ImageEditor
        └── widgets/              ← Transformation UI (gen_fill, gen_replace, gen_remove, etc.)
```

---

## Setup

### Prerequisites

- Flutter 3.41.3+ (stable channel)
- Android Studio or Xcode (for device/emulator)
- A running Creater.io backend (see [backend README](../../backend/README.md))

### Quick Start

```bash
# Install dependencies
flutter pub get

# Create config (do NOT commit)
mkdir -p config
# Create config/dev.json with your values (see below)

# Run
flutter run --dart-define-from-file=config/dev.json
```

### Configuration

Create `config/dev.json`:

```json
{
  "SERVER_URL": "http://localhost:5000",
  "UNSPLASH_ACCESS_KEY": "your-unsplash-access-key",
  "UNSPLASH_SECRET_KEY": "your-unsplash-secret-key",
  "GITHUB_CLIENT_ID": "your-github-client-id"
}
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for VS Code integration, build commands, and troubleshooting.

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `provider` | State management |
| `dio` | HTTP client |
| `flutter_secure_storage` | Secure token storage |
| `cached_network_image` | Image caching and loading |
| `google_sign_in` | Google OAuth |
| `flutter_web_auth_2` | GitHub OAuth (browser flow) |
| `image_picker` | Camera/gallery image selection |
| `image_cropper` | Image cropping |
| `flex_color_picker` | Color picker for recolor transformation |
| `firebase_core` | Firebase initialization |
| `firebase_crashlytics` | Crash reporting |
| `firebase_analytics` | Usage analytics |
| `rive` | Animated illustrations |
| `lottie` | Lottie animations |
| `shimmer` | Loading skeleton UI |
| `google_fonts` | Typography |

---

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| Splash | `/splash` | Animated splash with Rive animation |
| Login | `/login` | Email/username + password, OAuth buttons |
| Signup | `/signup` | Registration with profile photo upload |
| Home | `/home` | Bottom nav: Gallery, Editor, Account |
| Account | `/account` | Profile view, theme toggle, logout |
| Update Profile | `/update-profile` | Edit name, username, email |
| Update Password | `/update-password` | Change password |
| Unsplash | `/unsplash` | Stock photo search and import |
| Update Required | `/update-required` | Force update screen |

---

## Further Reading

- [Development Guide](docs/DEVELOPMENT.md) — Build configuration, VS Code setup
- [Architecture](../../docs/ARCHITECTURE.md) — System architecture overview
- [API Reference](../../docs/API.md) — Backend endpoint documentation
