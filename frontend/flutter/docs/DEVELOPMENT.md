# Creater.io Development Guide

This document outlines the environment configuration and build process for the Creater.io Flutter frontend.

## Environment Variables & Security

Historically, the project used `flutter_dotenv` to load a `.env` file bundled inside the application assets. This posed a severe security risk, as anyone could decompile the APK/IPA and extract API keys. 

To resolve this, the project has migrated to using `String.fromEnvironment()` and `--dart-define`. Environment variables are now injected at compile-time directly into the Dart compilation process. This prevents raw configuration files from being bundled and allows us to easily switch between development and production configurations.

**⚠️ Security Note:** While `--dart-define` prevents shipping a plain-text `.env` file, the compiled values can still be extracted from the binary via reverse engineering. Ensure that only public API keys (like OAuth client IDs) and URLs are stored in the Flutter app. Highly sensitive secrets must remain strictly on the backend.

---

## Required Configuration Variables

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `SERVER_URL` | Base URL for the Creater.io backend API. | `https://creater-io.onrender.com` or `http://localhost:5000` |
| `UNSPLASH_ACCESS_KEY` | Public access key for the Unsplash API. | `RmH-5i7v7fSE...` |
| `UNSPLASH_SECRET_KEY` | Secret key for Unsplash API limits. | `CcXDwJ9s5SBl...` |
| `GITHUB_CLIENT_ID` | OAuth Client ID for GitHub Sign-In. | `Ov23lijSn...` |

---

## Running the Project

### Command Line
To run the app in debug mode with inline variables:

```bash
flutter run \
  --dart-define=SERVER_URL=https://creater-io.onrender.com \
  --dart-define=UNSPLASH_ACCESS_KEY=your_unsplash_access_key \
  --dart-define=UNSPLASH_SECRET_KEY=your_unsplash_secret_key \
  --dart-define=GITHUB_CLIENT_ID=your_github_client_id
```

### JSON Configuration Files (Recommended)
Passing long strings of `--dart-define` is cumbersome. Flutter supports passing a JSON file using `--dart-define-from-file`.

1. Create a `config/` directory at the root of the Flutter project.
2. Create `config/dev.json` and `config/prod.json`. **Do not commit these files to version control.**

*Example `config/dev.json`:*
```json
{
  "SERVER_URL": "http://localhost:5000",
  "UNSPLASH_ACCESS_KEY": "dev_key",
  "UNSPLASH_SECRET_KEY": "dev_secret",
  "GITHUB_CLIENT_ID": "dev_client_id"
}
```

Run using the configuration file:
```bash
flutter run --dart-define-from-file=config/dev.json
```

---

## VS Code Integration

To avoid typing the compile flags every time you launch the debugger, update your `.vscode/launch.json` file.

*`.vscode/launch.json`:*
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Creater.io (Development)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define-from-file",
        "config/dev.json"
      ]
    },
    {
      "name": "Creater.io (Production)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define-from-file",
        "config/prod.json"
      ]
    }
  ]
}
```

---

## Building for Release

When building for production, use the production JSON configuration:

**Android App Bundle (AAB):**
```bash
flutter build appbundle --dart-define-from-file=config/prod.json
```

**Android APK:**
```bash
flutter build apk --dart-define-from-file=config/prod.json
```

**iOS:**
```bash
flutter build ios --dart-define-from-file=config/prod.json
```

---

## Troubleshooting

- **App fails to connect to backend / Unsplash images don't load:**
  Verify that you are passing the correct `--dart-define` arguments or using the correct JSON config file. If the variables are missing, the app defaults to empty strings which will cause network requests to fail cleanly.

- **"Could not read config file" error:**
  Ensure the path to your `--dart-define-from-file` is relative to where you are executing the `flutter` command, and ensure it is valid JSON (e.g., no trailing commas).
