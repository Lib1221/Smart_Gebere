import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // User IDs of chat participants
  final DateTime createdAt;
  final DateTime? lastMessageTime;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // Map of userId -> unread count
  final Map<String, bool> hiddenBy; // Map of userId -> hidden
  // Group chat specific
  final bool isGroupChat;
  final String? groupName;
  final String? groupCreatorId;
  final DateTime? groupCreatedAt;
  final List<String> groupAdmins;

  ChatModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.hiddenBy = const {},
    this.isGroupChat = false,
    this.groupName,
    this.groupCreatorId,
    this.groupCreatedAt,
    this.groupAdmins = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'hiddenBy': hiddenBy,
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'groupCreatorId': groupCreatorId,
      'groupCreatedAt': groupCreatedAt,
      'groupAdmins': groupAdmins,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      return ChatModel(
        id: documentId,
        participants: List<String>.from(map['participants'] ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastMessageTime:
            map['lastMessageTime'] != null
                ? (map['lastMessageTime'] as Timestamp).toDate()
                : null,
        lastMessageText: map['lastMessageText'],
        lastMessageSenderId: map['lastMessageSenderId'],
        unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
        hiddenBy: Map<String, bool>.from(map['hiddenBy'] ?? {}),
        isGroupChat: (map['isGroupChat'] as bool?) ?? false,
        groupName: map['groupName'] as String?,
        groupCreatorId: map['groupCreatorId'] as String?,
        groupCreatedAt:
            (map['groupCreatedAt'] is Timestamp)
                ? (map['groupCreatedAt'] as Timestamp).toDate()
                : null,
        groupAdmins: List<String>.from(map['groupAdmins'] ?? const <String>[]),
      );
    } catch (e) {
      print('Error parsing ChatModel from map: $e');
      // Return a fallback model
      return ChatModel(
        id: documentId,
        participants: [],
        createdAt: DateTime.now(),
        unreadCount: {},
      );
    }
  }
}
