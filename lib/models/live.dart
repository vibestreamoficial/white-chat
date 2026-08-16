/// Sala de live (colecao Firestore `lives`).
import '../utils/time_utils.dart';
class LiveRoom {
  final String id;
  final String hostUid;
  final String hostName;
  final String hostUsername;
  final String hostPhotoUrl;
  final String channel; // canal ex.: "canal1"
  final String title;
  final DateTime startedAt;
  final int viewers;
  final int totalGifts;
  final bool active;
  final String agoraToken; // opcional (token gerado no servidor)

  const LiveRoom({
    required this.id,
    required this.hostUid,
    this.hostName = '',
    this.hostUsername = '',
    this.hostPhotoUrl = '',
    this.channel = '',
    this.title = '',
    required this.startedAt,
    this.viewers = 0,
    this.totalGifts = 0,
    this.active = true,
    this.agoraToken = '',
  });

  factory LiveRoom.fromMap(String id, Map<String, dynamic> map) {
    return LiveRoom(
      id: id,
      hostUid: (map['hostUid'] as String?) ?? '',
      hostName: (map['hostName'] as String?) ?? '',
      hostUsername: (map['hostUsername'] as String?) ?? '',
      hostPhotoUrl: (map['hostPhotoUrl'] as String?) ?? '',
      channel: (map['channel'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      startedAt: tsToDateTime(map['startedAt']) ?? DateTime.now(),
      viewers: (map['viewers'] as num?)?.toInt() ?? 0,
      totalGifts: (map['totalGifts'] as num?)?.toInt() ?? 0,
      active: (map['active'] as bool?) ?? true,
      agoraToken: (map['agoraToken'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostUid': hostUid,
      'hostName': hostName,
      'hostUsername': hostUsername,
      'hostPhotoUrl': hostPhotoUrl,
      'channel': channel,
      'title': title,
      'startedAt': startedAt,
      'viewers': viewers,
      'totalGifts': totalGifts,
      'active': active,
      'agoraToken': agoraToken,
    };
  }
}

/// Mensagem do chat da live (Realtime Database `liveChat/{channel}`).
class LiveChatMessage {
  final String id;
  final String userUid;
  final String userName;
  final String text;
  final DateTime sentAt;

  const LiveChatMessage({
    required this.id,
    required this.userUid,
    this.userName = '',
    this.text = '',
    required this.sentAt,
  });

  factory LiveChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return LiveChatMessage(
      id: id,
      userUid: (map['userUid'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      sentAt: tsToDateTime(map['sentAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'userName': userName,
      'text': text,
      'sentAt': sentAt,
    };
  }
}
