import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat.dart';
import '../../models/gift.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'chat_screen.dart';

/// Tela Mensagens (clone do Kwai):
/// header "Mensagens" + lupa, 3 botoes de atividade (degrade), lista de chats
/// com avatar, nome, preview, hora, badge vermelho, tag "Oficial" e overlay
/// de live com timer + viewers + valor de gift.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final unreadTotal = (conversations.value ?? const <Conversation>[])
        .fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mensagens'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.textDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ActivityButtons(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Mensagens',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (unreadTotal > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.badgeRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadTotal',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: conversations.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                ),
                error: (e, _) => Center(
                  child: Text('Erro: $e',
                      style: const TextStyle(color: Colors.black54)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const _EmptyChats();
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 76, endIndent: 16),
                    itemBuilder: (_, i) => _ChatTile(conversation: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3 botoes: Curtidas & Compartilhamentos / Comentários e Menções / Novos seguidores
class _ActivityButtons extends StatelessWidget {
  const _ActivityButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActivityButton(
              icon: Icons.favorite,
              label: 'Curtidas & Compartilhamentos',
              colors: const [AppColors.pinkStart, AppColors.pinkEnd],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(type: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActivityButton(
              icon: Icons.comment,
              label: 'Comentários e Menções',
              colors: const [AppColors.yellowStart, AppColors.yellowEnd],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(type: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActivityButton(
              icon: Icons.person_add_alt,
              label: 'Novos seguidores',
              colors: const [AppColors.purpleStart, AppColors.purpleEnd],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(type: 3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ActivityButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de conversa com todos os elementos do print.
class _ChatTile extends StatelessWidget {
  final Conversation conversation;

  const _ChatTile({required this.conversation});

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour < 12 ? 'AM' : 'PM';
      return '$h:$m $ampm';
    }
    if (diff == 1) return 'Ontem';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: c),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar (com overlay de live se houver: timer + K viewers + valor)
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: c.otherPhotoUrl.isNotEmpty
                      ? NetworkImage(c.otherPhotoUrl)
                      : null,
                  child: c.otherPhotoUrl.isEmpty
                      ? const Icon(Icons.person,
                          color: AppColors.textGrey, size: 28)
                      : null,
                ),
                if (c.hasLive)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.sensors,
                          color: Colors.white, size: 12),
                    ),
                  ),
                if (c.hasLive)
                  Positioned(
                    left: -26,
                    bottom: 14,
                    child: LiveOverlayBadge(
                      startedAt: c.liveStartedAt ?? DateTime.now(),
                      viewers: c.liveViewers,
                      giftValue: c.liveGiftValue.isEmpty ? 'R\$15' : c.liveGiftValue,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.otherName.isEmpty ? c.otherUsername : c.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (c.isOfficial)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Oficial',
                            style: TextStyle(
                              color: Color(0xFF0080FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage.isEmpty ? 'Iniciar conversa' : c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.unreadCount > 0
                                ? AppColors.textDark
                                : AppColors.textGrey,
                            fontSize: 13,
                            fontWeight: c.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeLabel(c.lastMessageAt),
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (c.unreadCount > 0)
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.badgeRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${c.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlay de live na conversa: timer 03:14 + K 98 + R$15.
class LiveOverlayBadge extends StatelessWidget {
  final DateTime startedAt;
  final int viewers;
  final String giftValue;

  const LiveOverlayBadge({
    super.key,
    required this.startedAt,
    required this.viewers,
    this.giftValue = 'R\$15',
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(startedAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.giftOverlay.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${formatLiveClock(elapsed)} · K ${viewers >= 1000 ? (viewers / 1000).toStringAsFixed(1) : viewers} · $giftValue',
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: Color(0xFFD0D0D0), size: 56),
          SizedBox(height: 12),
          Text('Nenhuma conversa ainda',
              style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Toque em um perfil para começar a conversar',
              style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}
