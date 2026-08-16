import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/live.dart';
import '../models/notification_item.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/database_service.dart';
import '../services/live_service.dart';

/// Providers globais (Riverpod) do WHITE CHAT.

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final liveServiceProvider = Provider<LiveService>((ref) => LiveService());

/// Sessao atual (null = deslogado).
final authStateProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges.map((user) => user?.uid);
});

/// Perfil do usuario logado.
final myProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) {
    yield null;
    return;
  }
  yield* ref.watch(databaseServiceProvider).streamProfile(uid);
});

/// Feed "Para você" (videos aprovados de todos).
final feedProvider = StreamProvider<List<VideoPost>>((ref) {
  return ref.watch(databaseServiceProvider).streamFeed();
});

/// Feed "Seguindo" (so de quem o usuario segue).
final followingFeedProvider = StreamProvider<List<VideoPost>>((ref) async* {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) {
    yield const [];
    return;
  }
  final following = await ref
      .watch(databaseServiceProvider)
      .streamFollowingUids(uid)
      .first;
  yield* ref
      .watch(databaseServiceProvider)
      .streamFeed(onlyFollowing: true, followingUids: following);
});

/// UIDs de quem o usuario segue (para o botao seguir no perfil).
final followingUidsProvider = StreamProvider<List<String>>((ref) async* {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) {
    yield const [];
    return;
  }
  yield* ref.watch(databaseServiceProvider).streamFollowingUids(uid);
});

/// Lista de conversas (tela Mensagens).
final conversationsProvider = StreamProvider<List<Conversation>>((ref) async* {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) {
    yield const [];
    return;
  }
  yield* ref.watch(databaseServiceProvider).streamConversations(uid);
});

/// Notificacoes sociais.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) {
    yield const [];
    return;
  }
  yield* ref.watch(databaseServiceProvider).streamNotifications(uid);
});

/// Lives ativas.
final livesProvider = StreamProvider<List<LiveRoom>>((ref) {
  return ref.watch(databaseServiceProvider).streamLives();
});

/// Posts do perfil de um usuario especifico (tela Perfil).
final userPostsProvider =
    StreamProvider.family<List<VideoPost>, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).streamUserPosts(uid);
});

/// Perfil publico de outro usuario (tela Perfil).
final publicProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(databaseServiceProvider).streamProfile(uid);
});

/// Comentarios de um post (usado na folha de comentarios do feed).
final commentsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, postId) {
  return ref.watch(databaseServiceProvider).streamComments(postId);
});

/// Chave para o status de "digitando..." de uma conversa.
class ChatTypingKey {
  final String convId;
  final String otherUid;
  const ChatTypingKey(this.convId, this.otherUid);

  @override
  bool operator ==(Object other) =>
      other is ChatTypingKey &&
      other.convId == convId &&
      other.otherUid == otherUid;

  @override
  int get hashCode => Object.hash(convId, otherUid);
}

/// Status "digitando..." em tempo real.
final chatTypingProvider =
    StreamProvider.family<bool, ChatTypingKey>((ref, key) {
  return ref.watch(chatServiceProvider).streamTyping(key.convId, key.otherUid);
});

/// Ultima vez que o usuario esteve online.
final lastSeenProvider = StreamProvider.family<DateTime?, String>((ref, uid) {
  return ref.watch(chatServiceProvider).streamLastSeen(uid);
});
