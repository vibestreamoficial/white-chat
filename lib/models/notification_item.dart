/// Notificacao social (colecao Firestore `notifications`).
///
/// type: 1 = Curtidas & Compartilhamentos (degrade rosa)
///       2 = Comentarios e Mencoes   (degrade amarelo)
///       3 = Novos seguidores        (degrade roxo)
import '../utils/time_utils.dart';
class AppNotification {
  final String id;
  final String toUid;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String fromPhotoUrl;
  final int type;
  final String text;
  final DateTime createdAt;
  final bool read;
  final String targetId; // id do post/live relacionado

  const AppNotification({
    required this.id,
    required this.toUid,
    required this.fromUid,
    this.fromName = '',
    this.fromUsername = '',
    this.fromPhotoUrl = '',
    required this.type,
    this.text = '',
    required this.createdAt,
    this.read = false,
    this.targetId = '',
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      toUid: (map['toUid'] as String?) ?? '',
      fromUid: (map['fromUid'] as String?) ?? '',
      fromName: (map['fromName'] as String?) ?? '',
      fromUsername: (map['fromUsername'] as String?) ?? '',
      fromPhotoUrl: (map['fromPhotoUrl'] as String?) ?? '',
      type: (map['type'] as num?)?.toInt() ?? 1,
      text: (map['text'] as String?) ?? '',
      createdAt: tsToDateTime(map['createdAt']) ?? DateTime.now(),
      read: (map['read'] as bool?) ?? false,
      targetId: (map['targetId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toUid': toUid,
      'fromUid': fromUid,
      'fromName': fromName,
      'fromUsername': fromUsername,
      'fromPhotoUrl': fromPhotoUrl,
      'type': type,
      'text': text,
      'createdAt': createdAt,
      'read': read,
      'targetId': targetId,
    };
  }
}
