import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../config.dart';
import '../../models/gift.dart';
import '../../models/notification_item.dart';
import '../../models/post.dart';
import '../../services/database_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Item do feed em tela cheia (9:16) com overlays do Kwai:
/// like, comentario, compartilhar, disco de musica, gifts com timer,
/// dueto/live, e indicador "Deslize para cima".
class VideoFeedItem extends ConsumerStatefulWidget {
  final VideoPost post;
  final bool isFirst;

  const VideoFeedItem({super.key, required this.post, this.isFirst = false});

  @override
  ConsumerState<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<VideoFeedItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _liked = false;
  bool _showBigHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  Timer? _giftTicker;
  int _giftIndex = 0;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _checkLiked();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);

    // Rotaciona os gifts do carrossel "coletar x3" com timer.
    _giftTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _giftIndex = (_giftIndex + 1) % kGiftCarousel.length;
      });
    });
  }

  Future<void> _initVideo() async {
    final url = widget.post.mediaUrl;
    if (url.isEmpty || widget.post.isLive) return; // placeholder/live simulada
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(1);
      _videoController!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // sem rede/video invalido: mostra o placeholder gradiente
    }
  }

  Future<void> _checkLiked() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    try {
      final liked = await ref
          .read(databaseServiceProvider)
          .isLiked(widget.post.id, uid);
      if (mounted) setState(() => _liked = liked);
    } catch (_) {}
  }

  void _doubleTapLike() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    setState(() {
      _liked = !_liked;
      _showBigHeart = true;
    });
    _heartController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 750));
    if (mounted) setState(() => _showBigHeart = false);
    try {
      await ref
          .read(databaseServiceProvider)
          .toggleLike(widget.post, uid);
    } catch (_) {}
  }

  Future<void> _share() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    try {
      final post = widget.post;
      await ref.read(databaseServiceProvider).updatePost(
            post.id,
            {'shares': post.shares + 1},
          );
      // notificacao "Curtidas & Compartilhamentos" (type 1)
      final db = ref.read(databaseServiceProvider);
      final me = await db.getProfile(uid);
      if (me != null) {
        await db.addNotification(AppNotification(
          id: 'share_${post.id}_$uid',
          toUid: post.authorUid,
          fromUid: uid,
          fromName: me.name,
          fromUsername: me.username,
          fromPhotoUrl: me.photoUrl,
          type: 1,
          text: 'compartilhou seu vídeo',
          createdAt: DateTime.now(),
          targetId: post.id,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vídeo compartilhado ✅')),
        );
      }
    } catch (_) {}
  }

  Future<void> _download() async {
    if (widget.post.mediaUrl.isEmpty) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final res = await http.get(Uri.parse(widget.post.mediaUrl));
      final file = File('${dir.path}/whitechat_${widget.post.id}.mp4');
      await file.writeAsBytes(res.bodyBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Salvo em: ${file.path}')),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _giftTicker?.cancel();
    _heartController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoLayer(),
          // gradiente inferior para legibilidade
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.55, 1.0],
              ),
            ),
          ),
          _buildRightActions(post),
          _buildBottomInfo(post),
          if (_showBigHeart) _buildBigHeart(),
          if (post.isLive) _buildLiveDuetOverlay(),
          if (widget.isFirst) const _SwipeHint(),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_videoReady && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    // Placeholder animado estilo "video" quando nao ha midia
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF3D1B4E),
            Color(0xFF0A0A2A),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.movie_filter_outlined, color: Colors.white24, size: 72),
      ),
    );
  }

  Widget _buildRightActions(VideoPost post) {
    return Positioned(
      right: 8,
      bottom: 150,
      child: Column(
        children: [
          _avatarWithFollow(post),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: _liked ? AppColors.pink : Colors.white,
            count: _formatCount(post.likes + (_liked ? 1 : 0)),
            onTap: _doubleTapLike,
          ),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: Icons.mode_comment_outlined,
            count: _formatCount(post.comments),
            onTap: () => _openComments(post),
          ),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: Icons.share_outlined,
            count: _formatCount(post.shares),
            onTap: _share,
          ),
          const SizedBox(height: 16),
          _ActionIcon(
            icon: Icons.download_outlined,
            count: '',
            onTap: _download,
          ),
          const SizedBox(height: 16),
          _SpinningDisc(),
        ],
      ),
    );
  }

  Widget _avatarWithFollow(VideoPost post) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pink, width: 2),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: post.authorPhotoUrl.isNotEmpty
                ? NetworkImage(post.authorPhotoUrl)
                : null,
            child: post.authorPhotoUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white70)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.pink,
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 16),
        ),
      ],
    );
  }

  Widget _buildBottomInfo(VideoPost post) {
    return Positioned(
      left: 12,
      right: 64,
      bottom: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.authorUsername.isEmpty ? '${post.authorName}' : '@${post.authorUsername}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          _hashtagCaption(post.caption),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  post.music.isEmpty ? 'som original' : post.music,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GiftCarousel(
            gifts: kGiftCarousel,
            activeIndex: _giftIndex,
          ),
        ],
      ),
    );
  }

  Widget _hashtagCaption(String caption) {
    final parts = caption.split(RegExp(r'(\s+)'));
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
        children: parts.map((p) {
          if (p.startsWith('#')) {
            return TextSpan(
              text: p,
              style: const TextStyle(color: Color(0xFF25F4EE), fontWeight: FontWeight.w700),
            );
          }
          return TextSpan(text: p);
        }).toList(),
      ),
    );
  }

  Widget _buildBigHeart() {
    return Center(
      child: ScaleTransition(
        scale: _heartScale,
        child: const Icon(Icons.favorite, color: AppColors.pink, size: 110),
      ),
    );
  }

  Widget _buildLiveDuetOverlay() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.giftOverlay.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors, color: AppColors.pink, size: 16),
            SizedBox(width: 6),
            Text(
              'Ao vivo · Dueto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openComments(VideoPost post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _CommentsSheet(post: post),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String count;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.count,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (count.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 2),
          gradient: const LinearGradient(
            colors: [Color(0xFF222222), Color(0xFF000000)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: AppColors.pink, size: 16),
        ),
      ),
    );
  }
}

/// Carrossel "Aquecimento grátis para o streamer!" com gifts x3 e timers.
class _GiftCarousel extends StatelessWidget {
  final List<Gift> gifts;
  final int activeIndex;

  const _GiftCarousel({required this.gifts, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final active = gifts[activeIndex % gifts.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.giftOverlay.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '🔥 Aquecimento grátis para o streamer!',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Row(
                  key: ValueKey(active.id),
                  children: [
                    Text(active.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '${active.name} · coletar x${active.multiplier}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⏱ ${formatGiftTimer(active.remaining)}',
                      style: const TextStyle(
                        color: Color(0xFFFFD166),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Ir coletar',
                style: TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      bottom: 6,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Deslize para cima para ver mais vídeos ↑',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
    );
  }
}

/// Folha de comentarios em tempo real.
class _CommentsSheet extends ConsumerStatefulWidget {
  final VideoPost post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  String _firstLetter(String s) => s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final db = ref.read(databaseServiceProvider);
    final me = await db.getProfile(uid);
    await db.addComment(widget.post.id, uid, me?.name ?? 'Anônimo', text);
    await db.updatePost(widget.post.id, {'comments': widget.post.comments + 1});
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.post.id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Comentários (${widget.post.comments})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              child: comments.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                ),
                error: (e, _) => Center(
                  child: Text('Erro: $e', style: const TextStyle(color: Colors.white54)),
                ),
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Text('Sem comentários ainda. Seja o primeiro!',
                            style: TextStyle(color: Colors.white54)),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.pink,
                              child: Text(
                                _firstLetter(c['userName'] as String? ?? '?'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              c['userName'] as String? ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              c['text'] as String? ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Adicione um comentário...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: AppColors.pink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
