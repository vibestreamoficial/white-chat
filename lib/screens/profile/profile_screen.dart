import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../messages/chat_screen.dart';
import 'edit_profile_screen.dart';

/// Perfil: avatar grande centralizado, contadores, botao Editar/Seguir,
/// grid 3x de videos e modal de edicao. Se [uid] for null, mostra o meu perfil.
class ProfileScreen extends ConsumerWidget {
  final String? uid;
  const ProfileScreen({super.key, this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value;
    final targetUid = uid ?? myUid;
    if (targetUid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }

    final isMe = uid == null || uid == myUid;
    final profile = ref.watch(publicProfileProvider(targetUid));
    final posts = ref.watch(userPostsProvider(targetUid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pink),
          ),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (p) {
            if (p == null) {
              return const Center(child: Text('Perfil não encontrado'));
            }
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textDark,
                  title: Text(
                    p.username.isEmpty ? 'Perfil' : '@${p.username}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _openChat(context, ref, p),
                      icon: const Icon(Icons.chat_bubble_outline),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    profile: p,
                    isMe: isMe,
                    myUid: myUid,
                  ),
                ),
                SliverToBoxAdapter(child: _ProfileStats(profile: p, isMe: isMe)),
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 0.6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PostThumb(post: posts.value?[i]),
                      childCount: (posts.value ?? const []).length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, UserProfile p) {
    final myUid = ref.read(authStateProvider).value;
    if (myUid == null || p.uid == myUid) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: Conversation(
            id: '',
            otherUid: p.uid,
            otherName: p.name,
            otherUsername: p.username,
            otherPhotoUrl: p.photoUrl,
            lastMessageAt: DateTime.now(),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerStatefulWidget {
  final UserProfile profile;
  final bool isMe;
  final String? myUid;

  const _ProfileHeader({
    required this.profile,
    required this.isMe,
    this.myUid,
  });

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool? _isFollowing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final myUid = widget.myUid;
    if (myUid == null || widget.profile.uid == myUid) return;
    try {
      final f = await ref
          .read(databaseServiceProvider)
          .isFollowing(widget.profile.uid, myUid);
      if (mounted) setState(() => _isFollowing = f);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final myUid = widget.myUid;
    if (myUid == null) return;
    final db = ref.read(databaseServiceProvider);
    final me = await db.getProfile(myUid);
    if (me == null) return;
    setState(() => _isFollowing = !(_isFollowing ?? false));
    try {
      await db.toggleFollow(widget.profile, me, myUid);
    } catch (_) {
      setState(() => _isFollowing = !(_isFollowing ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.pinkStart, AppColors.purpleEnd],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage:
                      p.photoUrl.isNotEmpty ? NetworkImage(p.photoUrl) : null,
                  child: p.photoUrl.isEmpty
                      ? const Icon(Icons.person,
                          size: 48, color: AppColors.textGrey)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.username.isEmpty ? 'Sem username' : '@${p.username}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            p.name,
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 6),
          if (p.bio.isNotEmpty)
            Text(
              p.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          if (p.instagram.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Text(
                  'Instagram: ${p.instagram}',
                  style: const TextStyle(
                      color: AppColors.pink, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (widget.isMe)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Editar Perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing == true
                        ? const Color(0xFFE8E8E8)
                        : AppColors.pink,
                    foregroundColor:
                        _isFollowing == true ? AppColors.textDark : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _isFollowing == true ? 'Seguindo' : 'Seguir',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  final UserProfile profile;
  final bool isMe;
  const _ProfileStats({required this.profile, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(label: 'Seguindo', value: profile.following),
          _Stat(label: 'Seguidores', value: profile.followers),
          _Stat(label: 'Curtidas', value: profile.totalLikes),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_fmt(value),
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 12)),
      ],
    );
  }
}

class _PostThumb extends StatelessWidget {
  final VideoPost? post;
  const _PostThumb({this.post});

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(6),
        image: post!.coverUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(post!.coverUrl), fit: BoxFit.cover)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (post!.coverUrl.isEmpty)
            const Center(
              child: Icon(Icons.play_circle_fill,
                  color: Colors.white38, size: 28),
            ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${post!.likes}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.visibility, color: Colors.white, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${post!.views}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
