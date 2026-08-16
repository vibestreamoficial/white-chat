/// Perfil publico do usuario (colecao Firestore `profiles`).
import '../utils/time_utils.dart';
class UserProfile {
  final String uid;
  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final String gender;
  final String birthday;
  final String instagram;
  final String frame; // moldura de perfil selecionada
  final int followers;
  final int following;
  final int totalLikes;
  final DateTime createdAt;
  final bool isOfficial;

  const UserProfile({
    required this.uid,
    this.name = '',
    this.username = '',
    this.bio = '',
    this.photoUrl = '',
    this.gender = '',
    this.birthday = '',
    this.instagram = '',
    this.frame = '',
    this.followers = 0,
    this.following = 0,
    this.totalLikes = 0,
    required this.createdAt,
    this.isOfficial = false,
  });

  String get displayName => name.isEmpty ? '@$username' : name;
  String get handle => username.isEmpty ? uid : '@$username';

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      gender: (map['gender'] as String?) ?? '',
      birthday: (map['birthday'] as String?) ?? '',
      instagram: (map['instagram'] as String?) ?? '',
      frame: (map['frame'] as String?) ?? '',
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      following: (map['following'] as num?)?.toInt() ?? 0,
      totalLikes: (map['totalLikes'] as num?)?.toInt() ?? 0,
      createdAt: tsToDateTime(map['createdAt']) ?? DateTime.now(),
      isOfficial: (map['isOfficial'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'gender': gender,
      'birthday': birthday,
      'instagram': instagram,
      'frame': frame,
      'followers': followers,
      'following': following,
      'totalLikes': totalLikes,
      'createdAt': createdAt,
      'isOfficial': isOfficial,
    };
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? photoUrl,
    String? gender,
    String? birthday,
    String? instagram,
    String? frame,
    int? followers,
    int? following,
    int? totalLikes,
    bool? isOfficial,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      instagram: instagram ?? this.instagram,
      frame: frame ?? this.frame,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      totalLikes: totalLikes ?? this.totalLikes,
      createdAt: createdAt,
      isOfficial: isOfficial ?? this.isOfficial,
    );
  }
}
