# Changelog

All notable changes to **Smart Gebere** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2025-01-01

### 🎉 Major Release - Advanced Features

This release introduces powerful AI-driven features and comprehensive farm management tools.

### Added

#### AI Crop Doctor 🩺
- Real-time chat interface with Gemini AI
- Photo-based plant disease diagnosis
- Quick suggestion prompts for common questions
- Multi-language support in chat responses
- Conversation history with refresh option

#### Yield Prediction 📊
- AI-powered harvest yield estimation
- Market value predictions in ETB
- Confidence scoring
- Harvest quality prediction
- Recommendations and factors analysis
- Analytics dashboard with charts

#### GPS Field Mapping 🗺️
- Walk-the-boundary field mapping
- Automatic area calculation (hectares/acres)
- Soil type selection
- Save and manage multiple fields
- Integration with crop recommendations

#### Task Completion System ✅
- Interactive to-do lists in Expected Events
- Tap-to-complete task functionality
- Automatic progress calculation
- Firebase sync for task completion
- Visual progress indicators

### Changed

#### Crop Creation Flow
- Added field selection before getting recommendations
- AI now considers field size and soil type
- Field data saved with crop plans
- Enhanced crop cards with suitability colors

#### Home Dashboard
- Added 3 new quick action buttons (AI Doctor, Yield, Field Map)
- Updated navigation drawer with advanced features section
- Beautiful animated header with farm patterns

#### Expected Events
- Complete redesign with slideable cards
- Task progress circles on each card
- Modal bottom sheet for task management
- "Complete All" bulk action

### Fixed

- Widget lifecycle issues with `mounted` checks
- JSON type casting errors in AI responses
- Web compatibility for `shared_preferences`
- Web compatibility for `connectivity_plus`
- Firestore permission errors

---

## [1.5.0] - 2024-12-15

### 🌐 Localization & UI Enhancement Release

### Added

#### Multi-Language Support
- Amharic (አማርኛ) translation
- Afaan Oromo translation
- Language switcher in settings
- Persistent language preference

#### Enhanced UI
- Beautiful login page with animations
- Multi-step signup wizard
- Password strength indicator
- Splash screen
- Onboarding flow

#### Advanced Features
- Offline storage with Hive
- Connectivity monitoring
- Farm profile management
- Market prices page
- Weather advisor
- Farm records
- Knowledge base
- Privacy settings

### Changed

- Redesigned Home page with gradient header
- Enhanced Created Tasks with progress tracking
- Improved navigation drawer
- Better error handling throughout

### Fixed

- Locale fallback for unsupported languages
- Material localizations for Oromo locale
- Firestore security rules deployment

---

## [1.0.0] - 2024-11-01

### 🚀 Initial Release

### Core Features

#### Authentication
- Email/password login
- User registration
- Firebase Auth integration

#### Crop Recommendations
- GPS-based location detection
- Elevation data integration
- Weather data integration
- AI-powered crop suggestions
- Suitability scoring

#### Disease Detection
- Camera image capture
- Gallery image upload
- AI-based disease analysis
- Treatment recommendations

#### Crop Planning
- Week-by-week farming guides
- Stage-based task organization
- Save plans to Firebase
- View and manage saved crops

#### Task Management
- View created crop plans
- Track expected events
- Delete unwanted plans

### Technical Foundation

- Flutter 3.x framework
- Firebase backend
- Gemini AI integration
- Provider state management
- Cross-platform support (Android, iOS, Web)

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 2.0.0 | 2025-01-01 | AI Doctor, Yield Prediction, Field Mapping |
| 1.5.0 | 2024-12-15 | Localization, UI Enhancement |
| 1.0.0 | 2024-11-01 | Initial Release |

---

## Upcoming Features

### Version 2.1.0 (Planned)
- Push notifications for task reminders
- Voice input for AI Doctor chat
- Offline-first mode improvements
- Community forums

### Version 2.2.0 (Planned)
- IoT sensor integration
- Advanced analytics dashboard
- Export reports (PDF/Excel)
- Government scheme information

---

## Migration Notes

### Upgrading from 1.x to 2.0

No database migration required. Existing user data is fully compatible.

**Recommended steps:**
1. Update dependencies: `flutter pub get`
2. Deploy updated Firestore rules
3. Clear app cache and restart

### New Environment Variables (2.0)

No new environment variables required. Existing `.env` configuration works.

---

## Contributors

Thank you to all contributors who made these releases possible!

---

*For detailed technical documentation, see [README.md](README.md)*

