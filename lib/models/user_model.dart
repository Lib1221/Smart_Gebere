// In user_model.dart, add a copyWith method
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final DateTime birthDate;
  final String profilePicUrl;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool showOnlineStatus; // Add this field
  final bool enableNotifications; // Add this field

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.birthDate,
    required this.profilePicUrl,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
    this.showOnlineStatus = true, // Default to showing online status
    this.enableNotifications = true, // Default to notifications enabled
  });

  // Add copyWith method
  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    DateTime? birthDate,
    String? profilePicUrl,
    DateTime? createdAt,
    bool? isOnline,
    DateTime? lastSeen,
    bool? showOnlineStatus,
    bool? enableNotifications,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen:
          lastSeen, // Note: passing null explicitly replaces current value
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      enableNotifications: enableNotifications ?? this.enableNotifications,
    );
  }

  // Update toMap method to include new fields
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'birthDate': birthDate.toIso8601String(),
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt.toIso8601String(),
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'showOnlineStatus': showOnlineStatus,
      'enableNotifications': enableNotifications,
    };
  }

  // Update fromMap to handle the new fields
  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseLastSeen(dynamic lastSeenValue) {
      if (lastSeenValue == null) return null;

      if (lastSeenValue is Timestamp) {
        return lastSeenValue.toDate();
      } else if (lastSeenValue is DateTime) {
        return lastSeenValue;
      } else if (lastSeenValue is String) {
        try {
          return DateTime.parse(lastSeenValue);
        } catch (e) {
          print('Error parsing lastSeen string: $e');
          return null;
        }
      }
      return null;
    }

    return UserModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      birthDate:
          map['birthDate'] is Timestamp
              ? (map['birthDate'] as Timestamp).toDate()
              : DateTime.parse(map['birthDate']),
      profilePicUrl: map['profilePicUrl'] ?? '',
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']),
      isOnline: map['isOnline'] ?? false,
      lastSeen: parseLastSeen(map['lastSeen']),
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      enableNotifications: map['enableNotifications'] ?? true,
    );
  }
}
