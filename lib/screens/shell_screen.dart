import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'feed/create_post_screen.dart';
import 'feed/feed_screen.dart';
import 'live/live_screen.dart';
import 'messages/messages_screen.dart';
import 'profile/profile_screen.dart';

/// Estrutura principal com Bottom Navigation estilo Kwai:
/// [Início] [Jogo] [+] [Mensagens] [Perfil]
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          FeedScreen(),
          _GamePlaceholder(),
          SizedBox.shrink(), // botão + abre modal
          MessagesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0A0A0A),
        elevation: 0,
        height: 62,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_filled,
              label: 'Início',
              active: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.sports_esports_rounded,
              label: 'Jogo',
              active: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // Botão + central com efeito glitch rosa/ciano
            GestureDetector(
              onTap: _openCreateModal,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.pink, Color(0xFF25F4EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x5525F4EE),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 34),
              ),
            ),
            _NavItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Mensagens',
              active: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              active: _index == 4,
              onTap: () => setState(() => _index = 4),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: AppColors.pink),
              title: const Text('Postar vídeo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: const Text('Grave até 5 min e apareça no feed',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sensors_rounded, color: Color(0xFF25F4EE)),
              title: const Text('Iniciar Live',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: const Text('Transmita ao vivo com chat e gifts',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? AppColors.pink : const Color(0xFF9A9A9A),
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.pink : const Color(0xFF9A9A9A),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GamePlaceholder extends StatelessWidget {
  const _GamePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, color: AppColors.pink, size: 64),
            SizedBox(height: 12),
            Text('Jogo',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Em breve: jogos e missões do WHITE CHAT',
                style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
