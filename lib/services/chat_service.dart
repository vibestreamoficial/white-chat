import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/chat.dart';
import '../utils/time_utils.dart';

/// Chat 1-para-1 em tempo real usando Firebase Realtime Database.
///
/// Estrutura:
///   conversations/{convId}  -> metadados no Firestore
///   messages/{convId}/{msgId} -> mensagens no RTDB
///   typing/{convId}/{uid}   -> status de digitando
class ChatService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Cria (ou reutiliza) a conversa entre dois usuarios.
  Future<String> openConversation(String myUid, String otherUid) async {
    final q = await _db
        .collection('conversations')
        .where('members', arrayContains: myUid)
        .limit(50)
        .get();
    for (final d in q.docs) {
      final members = ((d.data() as Map?)?['members'] as List?) ?? [];
      if (members.contains(otherUid)) {
        return d.id;
      }
    }
    final id = _db.collection('conversations').doc().id;
    await _db.collection('conversations').doc(id).set({
      'id': id,
      'members': [myUid, otherUid],
      'otherUid': otherUid,
      'lastMessage': '',
      'lastMessageType': 'text',
      'lastMessageAt': DateTime.now(),
      'unreadCount': 0,
      'isOfficial': false,
      'hasLive': false,
      'liveViewers': 0,
      'liveGiftValue': '',
    });
    return id;
  }

  DatabaseReference _messagesRef(String convId) =>
      _rtdb.ref('messages').child(convId);

  /// Stream de mensagens da conversa em tempo real.
  Stream<List<ChatMessage>> streamMessages(String convId) {
    return _messagesRef(convId)
        .orderByChild('sentAt')
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data == null) return <ChatMessage>[];
      final list = <ChatMessage>[];
      (data as Map).forEach((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        m['id'] = key;
        m['conversationId'] = convId;
        list.add(ChatMessage.fromMap(key, m));
      });
      list.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return list;
    });
  }

  Future<void> sendText(String convId, String senderUid, String text) async {
    final msgId = _messagesRef(convId).push().key ?? DateTime.now().microsecondsSinceEpoch.toString();
    final msg = ChatMessage(
      id: msgId,
      conversationId: convId,
      senderUid: senderUid,
      type: 'text',
      text: text,
      sentAt: DateTime.now(),
    );
    await _messagesRef(convId).child(msgId).set(msg.toMap());
    await _updateConversationMeta(convId, text, 'text');
  }

  Future<void> sendMedia(String convId, String senderUid, String type, String url) async {
    final msgId = _messagesRef(convId).push().key ?? DateTime.now().microsecondsSinceEpoch.toString();
    final msg = ChatMessage(
      id: msgId,
      conversationId: convId,
      senderUid: senderUid,
      type: type,
      mediaUrl: url,
      sentAt: DateTime.now(),
    );
    await _messagesRef(convId).child(msgId).set(msg.toMap());
    await _updateConversationMeta(convId, type == 'image' ? '🖼️ Foto' : '📎 Mídia', type);
  }

  Future<void> _updateConversationMeta(String convId, String preview, String type) async {
    await _db.collection('conversations').doc(convId).update({
      'lastMessage': preview,
      'lastMessageType': type,
      'lastMessageAt': DateTime.now(),
    });
  }

  // ------------------------------------------------------------- digitando
  DatabaseReference _typingRef(String convId, String uid) =>
      _rtdb.ref('typing').child(convId).child(uid);

  Future<void> setTyping(String convId, String uid, bool typing) {
    return _typingRef(convId, uid).set(typing);
  }

  Stream<bool> streamTyping(String convId, String otherUid) {
    return _typingRef(convId, otherUid).onValue.map((event) {
      return event.snapshot.value == true;
    });
  }

  /// Ultima vez online do usuario (Firestore field `lastSeen`).
  Stream<DateTime?> streamLastSeen(String uid) {
    return _db.collection('profiles').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return tsToDateTime((snap.data() as Map?)?['lastSeen']);
    });
  }

  Future<void> touchLastSeen(String uid) {
    return _db.collection('profiles').doc(uid).update({'lastSeen': DateTime.now()});
  }
}
