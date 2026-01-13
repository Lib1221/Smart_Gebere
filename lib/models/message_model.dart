import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered; // delivery/seen indicators
  final bool isDeleted; // soft delete flag
  final bool isEdited; // edited flag
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.isDelivered = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.deletedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'sentAt': sentAt,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'deletedAt': deletedAt,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? _tsToDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
      return false;
    }

    // Be forgiving about legacy data that may store dates as strings or DateTime
    final DateTime? sentAt = _tsToDate(
      map['sentAt'] ?? map['createdAt'] ?? map['timestamp'],
    );

    return MessageModel(
      id: documentId,
      chatId: (map['chatId'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      sentAt: sentAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      isRead: _toBool(map['isRead']),
      isDelivered: _toBool(map['isDelivered']),
      isDeleted: _toBool(map['isDeleted']),
      isEdited: _toBool(map['isEdited']),
      editedAt: _tsToDate(map['editedAt']),
      deletedAt: _tsToDate(map['deletedAt']),
      metadata:
          map['metadata'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
    );
  }
}
