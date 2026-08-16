import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';

import '../models/chat.dart';
import '../models/live.dart';
import '../models/notification_item.dart';
import '../models/post.dart';
import '../models/user_profile.dart';

/// Camada de dados sociais no Cloud Firestore:
/// profiles, posts, likes, follows, comments, notifications, lives, conversations.
class DatabaseService {
  FirebaseFirestore? _dbInstance;

  bool get _demoMode => !DefaultFirebaseOptions.configured;

  FirebaseFirestore get _db {
    if (_demoMode) {
      throw StateError('Firebase nao configurado (modo demonstracao).');
    }
    return _dbInstance ??= FirebaseFirestore.instance;
  }

/// Converte o snapshot em Map (compativel com cloud_firestore 5.x e 6.x).
Map<String, dynamic> _snapData(dynamic snap) =>
    Map<String, dynamic>.from((snap.data() as Map?) ?? const {});

  // ---------------------------------------------------------------- perfis
  Future<UserProfile?> getProfile(String uid) async {
    if (_demoMode) return null;
    final snap = await _db.collection('profiles').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(uid, _snapData(snap));
  }

  Stream<UserProfile?> streamProfile(String uid) {
    if (_demoMode) return Stream.value(null);
    return _db.collection('profiles').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromMap(uid, _snapData(snap));
    });
  }

  Future<void> saveProfile(UserProfile profile) {
    if (_demoMode) return Future.value();
    return _db.collection('profiles').doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> getProfileByUsername(String username) async {
    if (_demoMode) return null;
    final q = await _db
        .collection('profiles')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return UserProfile.fromMap(d.id, _snapData(d));
  }

  Future<bool> usernameTaken(String username, String selfUid) async {
    if (_demoMode) return false;
    final q = await _db
        .collection('profiles')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return false;
    return q.docs.first.id != selfUid;
  }

  // ----------------------------------------------------------------- posts
  Future<void> createPost(VideoPost post) {
    if (_demoMode) return Future.value();
    return _db.collection('posts').doc(post.id).set(post.toMap());
  }

  Stream<List<VideoPost>> streamFeed({bool onlyFollowing = false, List<String>? followingUids}) {
    if (_demoMode) return Stream.value(_samplePosts());
    Query query = _db
        .collection('posts')
        .where('status', isEqualTo: 'aprovado')
        .orderBy('createdAt', descending: true)
        .limit(100);
    if (onlyFollowing && followingUids != null && followingUids.isNotEmpty) {
      query = query.where('authorUid', whereIn: followingUids);
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((d) => VideoPost.fromMap(d.id, _snapData(d))).toList();
    });
  }

  Stream<List<VideoPost>> streamUserPosts(String uid) {
    if (_demoMode) return Stream.value(_samplePosts());
    return _db
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => VideoPost.fromMap(d.id, _snapData(d))).toList();
    });
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) {
    if (_demoMode) return Future.value();
    return _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId) {
    if (_demoMode) return Future.value();
    return _db.collection('posts').doc(postId).delete();
  }

  Stream<List<VideoPost>> streamModerationQueue() {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'pendente')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => VideoPost.fromMap(d.id, _snapData(d))).toList());
  }

  // -------------------------------------------------------------- likes
  Future<bool> isLiked(String postId, String uid) async {
    if (_demoMode) return false;
    final snap = await _db.collection('postLikes').doc('${postId}_$uid').get();
    return snap.exists;
  }

  Future<void> toggleLike(VideoPost post, String uid) async {
    if (_demoMode) return Future.value();
    final doc = _db.collection('postLikes').doc('${post.id}_$uid');
    final snap = await doc.get();
    if (snap.exists) {
      await doc.delete();
      await updatePost(post.id, {'likes': (post.likes - 1).clamp(0, 1 << 31)});
    } else {
      await doc.set({'postId': post.id, 'uid': uid, 'at': DateTime.now()});
      await updatePost(post.id, {'likes': post.likes + 1});
    }
  }

  // ------------------------------------------------------------ follows
  Stream<List<UserProfile>> streamFollowing(String uid) {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = _snapData(d);
              return UserProfile(
                uid: (data['targetUid'] as String?) ?? '',
                name: (data['targetName'] as String?) ?? '',
                username: (data['targetUsername'] as String?) ?? '',
                photoUrl: (data['targetPhotoUrl'] as String?) ?? '',
                createdAt: DateTime.now(),
              );
            }).toList());
  }

  Stream<List<String>> streamFollowingUids(String uid) {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => (_snapData(d)['targetUid'] as String?) ?? '').toList());
  }

  Future<bool> isFollowing(String targetUid, String uid) async {
    if (_demoMode) return false;
    final snap = await _db.collection('follows').doc('${uid}_$targetUid').get();
    return snap.exists;
  }

  Future<void> toggleFollow(UserProfile target, UserProfile me, String myUid) async {
    if (_demoMode) return Future.value();
    final doc = _db.collection('follows').doc('${myUid}_${target.uid}');
    final snap = await doc.get();
    if (snap.exists) {
      await doc.delete();
      await _db.collection('profiles').doc(target.uid).update({
        'followers': (target.followers - 1).clamp(0, 1 << 31),
      });
      await _db.collection('profiles').doc(myUid).update({
        'following': (me.following - 1).clamp(0, 1 << 31),
      });
    } else {
      await doc.set({
        'followerUid': myUid,
        'targetUid': target.uid,
        'targetName': target.name,
        'targetUsername': target.username,
        'targetPhotoUrl': target.photoUrl,
        'at': DateTime.now(),
      });
      await _db.collection('profiles').doc(target.uid).update({
        'followers': target.followers + 1,
      });
      await _db.collection('profiles').doc(myUid).update({
        'following': me.following + 1,
      });
      // notificacao "Novos seguidores" (type 3)
      await addNotification(AppNotification(
        id: _db.collection('notifications').doc().id,
        toUid: target.uid,
        fromUid: myUid,
        fromName: me.name,
        fromUsername: me.username,
        fromPhotoUrl: me.photoUrl,
        type: 3,
        text: 'começou a seguir você',
        createdAt: DateTime.now(),
      ));
    }
  }

  // ------------------------------------------------------------- comments
  Future<void> addComment(String postId, String uid, String userName, String text) {
    if (_demoMode) return Future.value();
    final id = _db.collection('comments').doc().id;
    return _db.collection('comments').doc(id).set({
      'postId': postId,
      'uid': uid,
      'userName': userName,
      'text': text,
      'at': DateTime.now(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamComments(String postId) {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('at')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = _snapData(d);
              m['id'] = d.id;
              return m;
            }).toList());
  }

  // -------------------------------------------------------- notifications
  Future<void> addNotification(AppNotification n) {
    if (_demoMode) return Future.value();
    return _db.collection('notifications').doc(n.id).set(n.toMap());
  }

  Stream<List<AppNotification>> streamNotifications(String uid) {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, _snapData(d)))
            .toList());
  }

  Future<void> markNotificationRead(String id) {
    if (_demoMode) return Future.value();
    return _db.collection('notifications').doc(id).update({'read': true});
  }

  // ----------------------------------------------------------------- lives
  Future<void> createLive(LiveRoom room) {
    if (_demoMode) return Future.value();
    return _db.collection('lives').doc(room.id).set(room.toMap());
  }

  Stream<List<LiveRoom>> streamLives() {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('lives')
        .where('active', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LiveRoom.fromMap(d.id, _snapData(d))).toList());
  }

  Future<void> endLive(String id) {
    if (_demoMode) return Future.value();
    return _db.collection('lives').doc(id).update({'active': false});
  }

  Future<void> bumpLiveViewers(String id, int viewers) {
    if (_demoMode) return Future.value();
    return _db.collection('lives').doc(id).update({'viewers': viewers});
  }

  // --------------------------------------------------------- conversations
  Stream<List<Conversation>> streamConversations(String uid) {
    if (_demoMode) return Stream.value([]);
    return _db
        .collection('conversations')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = _snapData(d);
              final otherUid = (data['members'] as List).firstWhere(
                    (m) => m != uid,
                    orElse: () => uid,
                  ) as String;
              final m = Map<String, dynamic>.from(data);
              m['otherUid'] = otherUid;
              return Conversation.fromMap(d.id, m);
            }).toList());
  }

  /// Posts de exemplo exibidos no feed em modo demonstracao (sem Firebase).
  List<VideoPost> _samplePosts() {
    final agora = DateTime.now();
    return [
      VideoPost(
        id: 'demo1',
        authorUid: 'demo_whitechat',
        authorName: 'WHITE CHAT',
        authorUsername: 'whitechat',
        caption: 'Bem-vindo ao WHITE CHAT 🎉 #demo #kwai',
        music: 'som demo',
        likes: 128,
        comments: 12,
        shares: 5,
        views: 3400,
        status: 'aprovado',
        createdAt: agora,
      ),
      VideoPost(
        id: 'demo2',
        authorUid: 'demo_whitechat',
        authorName: 'WHITE CHAT',
        authorUsername: 'whitechat',
        caption: 'Modo demonstracao: login local ativo 🔒 #demo',
        music: 'som demo 2',
        likes: 89,
        comments: 7,
        shares: 3,
        views: 2100,
        status: 'aprovado',
        createdAt: agora.subtract(const Duration(hours: 1)),
      ),
      VideoPost(
        id: 'demo3',
        authorUid: 'demo_whitechat',
        authorName: 'WHITE CHAT',
        authorUsername: 'whitechat',
        caption: 'Configure o Firebase para postar e conversar 💬 #demo',
        music: 'som demo 3',
        isLive: true,
        likes: 210,
        comments: 20,
        shares: 9,
        views: 5600,
        status: 'aprovado',
        createdAt: agora.subtract(const Duration(hours: 2)),
      ),
    ];
  }
}
