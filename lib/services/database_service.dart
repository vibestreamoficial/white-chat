import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live.dart';
import '../models/notification_item.dart';
import '../models/post.dart';
import '../models/user_profile.dart';

/// Camada de dados sociais no Cloud Firestore:
/// profiles, posts, likes, follows, comments, notifications, lives, conversations.
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------- perfis
  Future<UserProfile?> getProfile(String uid) async {
    final snap = await _db.collection('profiles').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(uid, snap.data()!);
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _db.collection('profiles').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserProfile.fromMap(uid, snap.data()!);
    });
  }

  Future<void> saveProfile(UserProfile profile) {
    return _db.collection('profiles').doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> getProfileByUsername(String username) async {
    final q = await _db
        .collection('profiles')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final d = q.docs.first;
    return UserProfile.fromMap(d.id, d.data());
  }

  Future<bool> usernameTaken(String username, String selfUid) async {
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
    return _db.collection('posts').doc(post.id).set(post.toMap());
  }

  Stream<List<VideoPost>> streamFeed({bool onlyFollowing = false, List<String>? followingUids}) {
    Query query = _db
        .collection('posts')
        .where('status', isEqualTo: 'aprovado')
        .orderBy('createdAt', descending: true)
        .limit(100);
    if (onlyFollowing && followingUids != null && followingUids.isNotEmpty) {
      query = query.where('authorUid', whereIn: followingUids);
    }
    return query.snapshots().map((snap) {
      return snap.docs.map((d) => VideoPost.fromMap(d.id, d.data())).toList();
    });
  }

  Stream<List<VideoPost>> streamUserPosts(String uid) {
    return _db
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => VideoPost.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) {
    return _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId) {
    return _db.collection('posts').doc(postId).delete();
  }

  Stream<List<VideoPost>> streamModerationQueue() {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'pendente')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => VideoPost.fromMap(d.id, d.data())).toList());
  }

  // -------------------------------------------------------------- likes
  Future<bool> isLiked(String postId, String uid) async {
    final snap = await _db.collection('postLikes').doc('${postId}_$uid').get();
    return snap.exists;
  }

  Future<void> toggleLike(VideoPost post, String uid) async {
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
    return _db
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
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
    return _db
        .collection('follows')
        .where('followerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => (d.data()['targetUid'] as String?) ?? '').toList());
  }

  Future<bool> isFollowing(String targetUid, String uid) async {
    final snap = await _db.collection('follows').doc('${uid}_$targetUid').get();
    return snap.exists;
  }

  Future<void> toggleFollow(UserProfile target, UserProfile me, String myUid) async {
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
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('at')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }

  // -------------------------------------------------------- notifications
  Future<void> addNotification(AppNotification n) {
    return _db.collection('notifications').doc(n.id).set(n.toMap());
  }

  Stream<List<AppNotification>> streamNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> markNotificationRead(String id) {
    return _db.collection('notifications').doc(id).update({'read': true});
  }

  // ----------------------------------------------------------------- lives
  Future<void> createLive(LiveRoom room) {
    return _db.collection('lives').doc(room.id).set(room.toMap());
  }

  Stream<List<LiveRoom>> streamLives() {
    return _db
        .collection('lives')
        .where('active', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LiveRoom.fromMap(d.id, d.data())).toList());
  }

  Future<void> endLive(String id) {
    return _db.collection('lives').doc(id).update({'active': false});
  }

  Future<void> bumpLiveViewers(String id, int viewers) {
    return _db.collection('lives').doc(id).update({'viewers': viewers});
  }

  // --------------------------------------------------------- conversations
  Stream<List<Conversation>> streamConversations(String uid) {
    return _db
        .collection('conversations')
        .where('members', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              final otherUid = (data['members'] as List).firstWhere(
                    (m) => m != uid,
                    orElse: () => uid,
                  ) as String;
              final m = Map<String, dynamic>.from(data);
              m['otherUid'] = otherUid;
              return Conversation.fromMap(d.id, m);
            }).toList());
  }
}
