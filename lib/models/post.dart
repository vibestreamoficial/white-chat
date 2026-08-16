/// Post de video/imagem do feed (colecao Firestore `posts`).
import '../utils/time_utils.dart';
class VideoPost {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorUsername;
  final String authorPhotoUrl;
  final String mediaUrl; // URL do video ou imagem no Storage
  final String caption;
  final String music;
  final String coverUrl; // thumbnail opcional
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final bool allowComments;
  final bool allowDuet;
  final String status; // 'pendente' | 'aprovado' | 'reprovado'
  final bool pinned;
  final DateTime createdAt;
  final bool isLive; // posts de live ao vivo (dueto estilo print)

  const VideoPost({
    required this.id,
    required this.authorUid,
    this.authorName = '',
    this.authorUsername = '',
    this.authorPhotoUrl = '',
    this.mediaUrl = '',
    this.caption = '',
    this.music = '',
    this.coverUrl = '',
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.views = 0,
    this.allowComments = true,
    this.allowDuet = true,
    this.status = 'pendente',
    this.pinned = false,
    required this.createdAt,
    this.isLive = false,
  });

  factory VideoPost.fromMap(String id, Map<String, dynamic> map) {
    return VideoPost(
      id: id,
      authorUid: (map['authorUid'] as String?) ?? '',
      authorName: (map['authorName'] as String?) ?? '',
      authorUsername: (map['authorUsername'] as String?) ?? '',
      authorPhotoUrl: (map['authorPhotoUrl'] as String?) ?? '',
      mediaUrl: (map['mediaUrl'] as String?) ?? '',
      caption: (map['caption'] as String?) ?? '',
      music: (map['music'] as String?) ?? '',
      coverUrl: (map['coverUrl'] as String?) ?? '',
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as num?)?.toInt() ?? 0,
      shares: (map['shares'] as num?)?.toInt() ?? 0,
      views: (map['views'] as num?)?.toInt() ?? 0,
      allowComments: (map['allowComments'] as bool?) ?? true,
      allowDuet: (map['allowDuet'] as bool?) ?? true,
      status: (map['status'] as String?) ?? 'pendente',
      pinned: (map['pinned'] as bool?) ?? false,
      createdAt: tsToDateTime(map['createdAt']) ?? DateTime.now(),
      isLive: (map['isLive'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'music': music,
      'coverUrl': coverUrl,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'views': views,
      'allowComments': allowComments,
      'allowDuet': allowDuet,
      'status': status,
      'pinned': pinned,
      'createdAt': createdAt,
      'isLive': isLive,
    };
  }

  VideoPost copyWith({
    int? likes,
    int? comments,
    int? shares,
    int? views,
    String? status,
  }) {
    return VideoPost(
      id: id,
      authorUid: authorUid,
      authorName: authorName,
      authorUsername: authorUsername,
      authorPhotoUrl: authorPhotoUrl,
      mediaUrl: mediaUrl,
      caption: caption,
      music: music,
      coverUrl: coverUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      views: views ?? this.views,
      allowComments: allowComments,
      allowDuet: allowDuet,
      status: status ?? this.status,
      pinned: pinned,
      createdAt: createdAt,
      isLive: isLive,
    );
  }
}
