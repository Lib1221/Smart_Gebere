# Setup

## Prerequisites

- Flutter 3.x and Dart SDK
- A Firebase project (Auth, Firestore, Storage enabled)
- A Google AI Studio (Gemini) API key

## Steps

```bash
git clone https://github.com/Lib1221/Smart_Gebere.git
cd Smart_Gebere
flutter pub get
flutterfire configure          # regenerates lib/firebase_options.dart
flutter run
```

Provide the Gemini key through `--dart-define=GEMINI_API_KEY=...` or the config file the app reads (see `lib/core`), depending on the current implementation.

## Quality checks

```bash
flutter analyze
flutter test
```

## Release builds

```bash
flutter build apk --release
flutter build appbundle --release
```
