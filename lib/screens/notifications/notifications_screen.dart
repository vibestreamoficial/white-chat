import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notification_item.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Notificacoes sociais filtradas por tipo:
/// 1 = Curtidas & Compartilhamentos | 2 = Comentarios e Mencoes | 3 = Novos seguidores
class NotificationsScreen extends ConsumerWidget {
  final int type;
  const NotificationsScreen({super.key, required this.type});

  String get _title {
    switch (type) {
      case 1:
        return 'Curtidas & Compartilhamentos';
      case 2:
        return 'Comentários e Menções';
      default:
        return 'Novos seguidores';
    }
  }

  IconData get _icon {
    switch (type) {
      case 1:
        return Icons.favorite;
      case 2:
        return Icons.comment;
      default:
        return Icons.person_add_alt;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final list = (notifications.value ?? const <AppNotification>[])
        .where((n) => n.type == type)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: notifications.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pink),
          ),
          error: (e, _) => Center(
            child: Text('Erro: $e',
                style: const TextStyle(color: Colors.black54)),
          ),
          data: (_) {
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon,
                        color: const Color(0xFFD0D0D0), size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'Nada por aqui ainda',
                      style: TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 76, endIndent: 16),
              itemBuilder: (_, i) => _NotificationTile(n: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification n;
  const _NotificationTile({required this.n});

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () {
        ref.read(databaseServiceProvider).markNotificationRead(n.id);
      },
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8E8E8),
            backgroundImage: n.fromPhotoUrl.isNotEmpty
                ? NetworkImage(n.fromPhotoUrl)
                : null,
            child: n.fromPhotoUrl.isEmpty
                ? const Icon(Icons.person, color: AppColors.textGrey)
                : null,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: notificationGradient(n.type)),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                n.type == 1
                    ? Icons.favorite
                    : n.type == 2
                        ? Icons.comment
                        : Icons.person_add,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              n.fromName.isEmpty ? n.fromUsername : n.fromName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(width: 6),
          if (!n.read)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.badgeRed,
              ),
            ),
        ],
      ),
      subtitle: Text(n.text,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
      trailing: Text(_timeLabel(n.createdAt),
          style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
    );
  }
}
