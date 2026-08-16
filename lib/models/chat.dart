/// Conversa e mensagem 1-para-1.
///
/// Lista de conversas: colecao Firestore `conversations`
/// Mensagens em tempo real: Firebase Realtime Database `messages/{convId}`

import '../utils/time_utils.dart';
class Conversation {
  final String id;
  final String otherUid;
  final String otherName;
  final String otherUsername;
  final String otherPhotoUrl;
  final String lastMessage;
  final String lastMessageType; // text | image | video | audio
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOfficial;
  final bool hasLive; // overlay de live na lista
  final DateTime? liveStartedAt;
  final int liveViewers;
  final String liveGiftValue;

  const Conversation({
    required this.id,
    required this.otherUid,
    this.otherName = '',
    this.otherUsername = '',
    this.otherPhotoUrl = '',
    this.lastMessage = '',
    this.lastMessageType = 'text',
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOfficial = false,
    this.hasLive = false,
    this.liveStartedAt,
    this.liveViewers = 0,
    this.liveGiftValue = '',
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> map) {
    return Conversation(
      id: id,
      otherUid: (map['otherUid'] as String?) ?? '',
      otherName: (map['otherName'] as String?) ?? '',
      otherUsername: (map['otherUsername'] as String?) ?? '',
      otherPhotoUrl: (map['otherPhotoUrl'] as String?) ?? '',
      lastMessage: (map['lastMessage'] as String?) ?? '',
      lastMessageType: (map['lastMessageType'] as String?) ?? 'text',
      lastMessageAt: tsToDateTime(map['lastMessageAt']) ?? DateTime.now(),
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
      isOfficial: (map['isOfficial'] as bool?) ?? false,
      hasLive: (map['hasLive'] as bool?) ?? false,
      liveStartedAt: tsToDateTime(map['liveStartedAt']),
      liveViewers: (map['liveViewers'] as num?)?.toInt() ?? 0,
      liveGiftValue: (map['liveGiftValue'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'otherUid': otherUid,
      'otherName': otherName,
      'otherUsername': otherUsername,
      'otherPhotoUrl': otherPhotoUrl,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageAt': lastMessageAt,
      'unreadCount': unreadCount,
      'isOfficial': isOfficial,
      'hasLive': hasLive,
      'liveStartedAt': liveStartedAt,
      'liveViewers': liveViewers,
      'liveGiftValue': liveGiftValue,
    };
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderUid;
  final String type; // text | image | video | audio
  final String text;
  final String mediaUrl;
  final DateTime sentAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUid,
    this.type = 'text',
    this.text = '',
    this.mediaUrl = '',
    required this.sentAt,
    this.read = false,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      conversationId: (map['conversationId'] as String?) ?? '',
      senderUid: (map['senderUid'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'text',
      text: (map['text'] as String?) ?? '',
      mediaUrl: (map['mediaUrl'] as String?) ?? '',
      sentAt: tsToDateTime(map['sentAt']) ?? DateTime.now(),
      read: (map['read'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderUid': senderUid,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'sentAt': sentAt.toIso8601String(),
      'read': read,
    };
  }
}
