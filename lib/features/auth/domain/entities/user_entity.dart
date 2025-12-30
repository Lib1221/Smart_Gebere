import 'package:flutter/foundation.dart';

/// User entity representing an authenticated user.
/// This is the domain layer representation, independent of data sources.
@immutable
class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Check if user has a display name set
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Get display name or email prefix as fallback
  String get displayNameOrEmail {
    if (hasDisplayName) return displayName!;
    final atIndex = email.indexOf('@');
    return atIndex > 0 ? email.substring(0, atIndex) : email;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, email: $email)';

  /// Create a copy with optional new values
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

