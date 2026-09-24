# Architecture

Smart Gebere is a Flutter app for Ethiopian farmers that combines Gemini-powered crop disease detection with task scheduling, localized content, and location-aware features, backed by Firebase.

## Module map (`lib/`)

| Folder | Responsibility |
| ------ | -------------- |
| `main.dart`, `firebase_options.dart` | App bootstrap, Firebase init, theme, localization delegates |
| `splash/`, `onboarding/`, `Loading/` | Launch flow and first-run screens |
| `auth/` | Sign up / sign in with Firebase Authentication |
| `Home/` | Main dashboard and navigation |
| `Disease_page/` | Image capture/upload and Gemini AI diagnosis with treatment advice |
| `scheduling/`, `task_management/` | Farm task planning, reminders, and progress |
| `geo_Location/` | Location permissions and location-based features (weather, region context) |
| `stream/` | Real-time Firestore streams feeding the UI |
| `features/`, `core/`, `controller/`, `models/`, `utils/` | Feature modules, shared services, state controllers, data models, helpers |
| `l10n/` | Localization resources (Amharic, Afaan Oromo, English) |
| `settings/` | Language, notifications, and account settings |

## Data and services

```
Flutter UI -> controllers -> services (Firebase Auth, Cloud Firestore, Storage, Gemini API, Geolocator)
```

- Firestore holds users, tasks, and diagnosis history; Storage holds uploaded images.
- The Gemini API key is read from configuration at build time; never commit it.
- CI lives in `.github/workflows` (analyze and test on push).

See the main README for the full feature list, screenshots, and the CHANGELOG for release history.
