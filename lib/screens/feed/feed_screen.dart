import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/post.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import 'video_feed_item.dart';

/// Tela Feed "Para você" / "Seguindo" com abas e scroll vertical.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const _tabs = ['Motivação', 'Live', 'Shop', 'Local', 'Seguindo', 'Para você'];
  int _tabIndex = 5; // "Para você" ativo por padrao

  @override
  Widget build(BuildContext context) {
    final isFollowingTab = _tabIndex == 4;

    return Scaffold(
      backgroundColor: AppColors.feedBackground,
      body: SafeArea(
        child: Column(
          children: [
            _TopTabs(
              tabs: _tabs,
              activeIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
            Expanded(
              child: isFollowingTab
                  ? _buildFollowingFeed()
                  : _buildForYouFeed(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouFeed() {
    final feed = ref.watch(feedProvider);
    return feed.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      ),
      error: (e, _) => _EmptyFeed(message: 'Erro ao carregar: $e'),
      data: (posts) => _FeedPageView(posts: posts),
    );
  }

  Widget _buildFollowingFeed() {
    final feed = ref.watch(followingFeedProvider);
    return feed.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pink),
      ),
      error: (e, _) => _EmptyFeed(message: 'Erro ao carregar: $e'),
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyFeed(
            message: 'Siga alguém para ver os vídeos deles aqui 👀',
          );
        }
        return _FeedPageView(posts: posts);
      },
    );
  }
}

class _FeedPageView extends StatelessWidget {
  final List<VideoPost> posts;
  const _FeedPageView({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyFeed(
        message: 'Nenhum vídeo por aqui ainda. Poste o primeiro com o botão + 🎬',
      );
    }
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return VideoFeedItem(
          post: post,
          isFirst: index == 0,
        );
      },
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final String message;
  const _EmptyFeed({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined,
                color: Colors.white38, size: 64),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abas do topo: Motivação | Live | Shop | Local | Seguindo | Para você
class _TopTabs extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _TopTabs({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: AppColors.feedBackground,
      alignment: Alignment.center,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: active ? 26 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
