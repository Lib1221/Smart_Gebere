import 'dart:convert';

/// Input validation and sanitization utility.
/// Prevents prompt injection and ensures data integrity.
class InputValidator {
  // Singleton
  static final InputValidator _instance = InputValidator._internal();
  factory InputValidator() => _instance;
  InputValidator._internal();

  // ═══════════════════════════════════════════════════════════════════════════
  // Email Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Returns error message for invalid email, null if valid
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Password Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates password strength
  PasswordStrength getPasswordStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Returns error message for invalid password, null if valid
  String? validatePassword(String? password, {int minLength = 6}) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates password confirmation
  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phone Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates Ethiopian phone number
  bool isValidEthiopianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    // Ethiopian format: +251XXXXXXXXX or 0XXXXXXXXX
    final regex = RegExp(r'^(\+251|0)?[79]\d{8}$');
    return regex.hasMatch(cleaned);
  }

  /// Formats phone to standard format
  String formatEthiopianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('0')) {
      return '+251${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+251')) {
      return '+251$cleaned';
    }
    return cleaned;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Coordinate Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates latitude
  bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }

  /// Validates longitude
  bool isValidLongitude(double lon) {
    return lon >= -180 && lon <= 180;
  }

  /// Validates coordinate pair
  bool isValidCoordinate(double lat, double lon) {
    return isValidLatitude(lat) && isValidLongitude(lon);
  }

  /// Validates if coordinates are within Ethiopia
  bool isInEthiopia(double lat, double lon) {
    // Approximate bounds of Ethiopia
    return lat >= 3.4 && lat <= 14.9 && lon >= 33.0 && lon <= 48.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI Input Sanitization
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sanitizes text before sending to AI to prevent prompt injection
  String sanitizeForAI(String input) {
    if (input.isEmpty) return input;
    
    // Remove potential prompt injection patterns
    String sanitized = input;
    
    // Remove instruction override attempts
    final dangerousPatterns = [
      RegExp(r'(?:ignore|forget|disregard|override|bypass).*(?:instructions?|prompt|rules?|guidelines?)', caseSensitive: false),
      RegExp(r'(?:system|admin|root)\s*(?:prompt|command|instruction)', caseSensitive: false),
      RegExp(r'you\s+are\s+now', caseSensitive: false),
      RegExp(r'pretend\s+(?:to\s+be|you\s+are)', caseSensitive: false),
      RegExp(r'act\s+as\s+(?:if|a)', caseSensitive: false),
      RegExp(r'\[\[.*\]\]', caseSensitive: false), // Remove [[...]] blocks
      RegExp(r'\{\{.*\}\}', caseSensitive: false), // Remove {{...}} blocks
    ];
    
    for (final pattern in dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '[removed]');
    }
    
    // Limit length
    if (sanitized.length > 10000) {
      sanitized = sanitized.substring(0, 10000);
    }
    
    // Escape special characters that could be interpreted as markdown
    sanitized = sanitized
        .replaceAll('```', '\'\'\'')
        .replaceAll('---', '- - -');
    
    return sanitized.trim();
  }

  /// Sanitizes filename
  String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'\.+'), '.')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JSON Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates if string is valid JSON
  bool isValidJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to parse JSON, returns null on failure
  T? tryParseJson<T>(String str) {
    try {
      final decoded = jsonDecode(str);
      if (decoded is T) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // General Text Validation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Validates required field
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length
  String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validates maximum length
  String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validates numeric value
  String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }

  /// Validates positive number
  String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }
    return null;
  }
}

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
  
  double get percentage {
    switch (this) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
  
  int get colorValue {
    switch (this) {
      case PasswordStrength.weak:
        return 0xFFF44336; // Red
      case PasswordStrength.medium:
        return 0xFFFF9800; // Orange
      case PasswordStrength.strong:
        return 0xFF4CAF50; // Green
    }
  }
}

