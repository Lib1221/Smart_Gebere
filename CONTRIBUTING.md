# Contributing to Smart Gebere

Thank you for your interest in contributing to Smart Gebere! This document provides guidelines and instructions for contributing.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Making Changes](#making-changes)
5. [Coding Standards](#coding-standards)
6. [Testing](#testing)
7. [Submitting Changes](#submitting-changes)
8. [Review Process](#review-process)
9. [Community](#community)

---

## Code of Conduct

### Our Pledge

We are committed to making participation in this project a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience, nationality
- Personal appearance, race, religion
- Sexual identity and orientation

### Our Standards

**Positive behaviors:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors:**
- Trolling, insulting/derogatory comments
- Public or private harassment
- Publishing others' private information
- Other conduct which could be considered inappropriate

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Git
- A code editor (VS Code, Android Studio, or IntelliJ)
- Firebase CLI (for testing backend changes)

### First-Time Setup

1. **Fork the repository**
   ```bash
   # On GitHub, click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/smart-gebere.git
   cd smart-gebere/Smart_Gebere
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/original-org/smart-gebere.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## Development Setup

### Environment Variables

Create a `.env` file with:

```env
# Required
API_KEY=your_gemini_api_key
GEMINI_API_KEY=your_gemini_api_key
OPENWEATHER_API_KEY=your_openweather_api_key

# Optional
GEMINI_MODEL=gemini-1.5-flash
```

### Firebase Setup

For backend changes, you'll need:

1. Create a Firebase project
2. Download config files
3. Deploy Firestore rules

See [README.md](README.md) for detailed instructions.

### IDE Setup

#### VS Code

Recommended extensions:
- Dart
- Flutter
- Awesome Flutter Snippets
- Error Lens

Settings (`.vscode/settings.json`):
```json
{
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

#### Android Studio

- Install Flutter and Dart plugins
- Enable "Format code on save"
- Configure import organization

---

## Making Changes

### Branch Naming

Use descriptive branch names:

```
feature/add-voice-input
fix/login-error-handling
docs/update-api-reference
refactor/simplify-location-service
test/add-crop-card-tests
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting (no code change)
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```bash
feat(ai-doctor): add voice input support

fix(auth): resolve login error on iOS devices

docs(readme): add API documentation section

refactor(location): simplify getCurrentLocation method
```

### Keeping Up to Date

Regularly sync with upstream:

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

---

## Coding Standards

### Dart/Flutter Style Guide

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

#### Naming Conventions

```dart
// Classes: UpperCamelCase
class CropRecommendation {}

// Variables/functions: lowerCamelCase
int cropCount = 0;
void fetchCrops() {}

// Constants: lowerCamelCase
const defaultTimeout = Duration(seconds: 30);

// Private members: prefix with underscore
String _privateField;
void _privateMethod() {}

// File names: lowercase_with_underscores
// crop_recommendation_page.dart
```

#### Code Formatting

```dart
// Use trailing commas for multi-line
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Hello'),
        Text('World'),
      ],  // trailing comma
    ),
  );
}

// Maximum line length: 80 characters
// Run formatter: dart format .
```

#### Documentation

```dart
/// A service that fetches crop recommendations based on location.
///
/// Uses GPS coordinates, weather data, and elevation to provide
/// personalized crop suggestions via Gemini AI.
///
/// Example:
/// ```dart
/// final service = LocationService();
/// final recommendations = await service.generateCropSuggestions(locationData);
/// ```
class LocationService {
  /// Fetches the current GPS location with weather and elevation.
  ///
  /// Throws [LocationException] if GPS is disabled or permission denied.
  Future<Map<String, dynamic>> getCurrentLocation() async {
    // implementation
  }
}
```

### Widget Structure

```dart
class MyWidget extends StatefulWidget {
  // 1. Constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  // 2. Properties
  final String title;
  final VoidCallback? onTap;

  // 3. Create state
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. State variables
  bool _isLoading = false;

  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 3. Private methods
  Future<void> _loadData() async {
    // ...
  }

  // 4. Build method (always last)
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Error Handling

```dart
// Always handle errors gracefully
try {
  final data = await fetchData();
  if (mounted) {
    setState(() => _data = data);
  }
} catch (e) {
  debugPrint('Error fetching data: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load data')),
    );
  }
}

// Check mounted before setState in async methods
Future<void> _loadData() async {
  final data = await service.getData();
  if (mounted) {
    setState(() => _data = data);
  }
}
```

### Localization

```dart
// Always use localized strings
final l10n = AppLocalizations.of(context);

// Good
Text(l10n.welcomeMessage)

// Bad
Text('Welcome')

// Adding new strings:
// 1. Add to app_en.arb
// 2. Add to app_am.arb
// 3. Add to app_om.arb
// 4. Add getter to AppLocalizations class
```

---

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/location_service_test.dart

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### Writing Tests

#### Unit Tests

```dart
// test/unit/services/location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_gebere/geo_Location/location.dart';

void main() {
  group('LocationService', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    test('should calculate area correctly', () {
      final points = [
        LatLng(0, 0),
        LatLng(0, 1),
        LatLng(1, 1),
        LatLng(1, 0),
      ];
      
      final area = service.calculateArea(points);
      
      expect(area, closeTo(12345, 100));
    });
  });
}
```

#### Widget Tests

```dart
// test/widget/crop_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_gebere/task_management/list_suggestion.dart';

void main() {
  testWidgets('CropCard displays crop name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CropCard(
            name: 'Teff',
            description: 'A grain crop',
            suitability: 85,
            details: 'Details here',
            crop: 'Teff',
          ),
        ),
      ),
    );

    expect(find.text('Teff'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
  });
}
```

### Test Coverage Requirements

- New features should include tests
- Bug fixes should include regression tests
- Aim for 70%+ coverage on new code

---

## Submitting Changes

### Pull Request Process

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make changes**
   - Follow coding standards
   - Add tests if applicable
   - Update documentation

3. **Test locally**
   ```bash
   flutter test
   flutter analyze
   dart format --set-exit-if-changed .
   ```

4. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature
   ```

6. **Create Pull Request**
   - Go to GitHub and click "New Pull Request"
   - Fill out the PR template
   - Link related issues

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring

## Related Issues
Fixes #123

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Add screenshots here]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
```

---

## Review Process

### What to Expect

1. **Automated Checks**
   - CI runs tests and linting
   - Must pass before review

2. **Code Review**
   - At least one maintainer reviews
   - Feedback provided within 3-5 days

3. **Requested Changes**
   - Address all feedback
   - Push additional commits to same branch

4. **Approval & Merge**
   - Once approved, maintainer merges
   - Branch is deleted

### Review Criteria

- Code quality and readability
- Test coverage
- Documentation completeness
- Compatibility with existing code
- Performance implications
- Security considerations

---

## Community

### Getting Help

- **Issues**: For bug reports and feature requests
- **Discussions**: For questions and ideas
- **Discord/Slack**: [Link to community chat]

### Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes
- Annual contributor highlights

### Maintainers

For questions, contact:
- Lead maintainer: [Name] (@username)
- Core team: [Names]

---

## Thank You!

Your contributions make Smart Gebere better for Ethiopian farmers. Every improvement, no matter how small, makes a difference.

**Happy coding! 🌾**

