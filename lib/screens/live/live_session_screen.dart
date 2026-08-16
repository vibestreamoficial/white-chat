import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../models/gift.dart';
import '../../models/live.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Sessao de live: timer, viewers em tempo real, chat e gifts na tela.
class LiveSessionScreen extends ConsumerStatefulWidget {
  final LiveRoom room;
  final bool isHost;

  const LiveSessionScreen({
    super.key,
    required this.room,
    required this.isHost,
  });

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final _chatController = TextEditingController();
  int _remoteUid = 0;
  RtcSurfaceView? _localView;
  RtcSurfaceView? _remoteView;
  bool _agoraReady = false;
  String? _agoraWarning;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _setupAgora();
  }

  Future<void> _setupAgora() async {
    final liveService = ref.read(liveServiceProvider);
    final ok = await liveService.init(uid: 0);
    if (!ok) {
      setState(() {
        _agoraWarning =
            'Agora não configurado: cole o App ID em lib/config.dart '
            '(AppConfig.agoraAppId) para transmissão real. '
            'O modo demonstração segue funcionando (timer, chat, gifts).';
      });
      return;
    }
    final uid = ref.read(authStateProvider).value;
    _localView = RtcSurfaceView();
    _remoteView = RtcSurfaceView();
    setState(() => _agoraReady = true);

    liveService.listen(
      onJoined: () {
        if (widget.isHost) {
          liveService.setupLocalVideo(_localView!);
        }
      },
      onUserJoined: (remoteUid) {
        setState(() => _remoteUid = remoteUid);
        liveService.setupRemoteVideo(remoteUid, _remoteView!);
      },
      onUserOffline: (uid) {
        if (uid == _remoteUid) setState(() => _remoteUid = 0);
      },
      onError: (msg) => debugPrint('Agora error: $msg'),
    );

    if (widget.isHost) {
      await liveService.startHost(widget.room.channel);
    } else {
      await liveService.joinAudience(widget.room.channel);
    }
    _bumpViewers();
  }

  Future<void> _bumpViewers() async {
    final db = ref.read(databaseServiceProvider);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.room.id)
          .get();
      final current = (snap.data()?['viewers'] as num?)?.toInt() ?? 0;
      await db.bumpLiveViewers(widget.room.id, current + 1);
    } catch (_) {}
  }

  DatabaseReference get _chatRef =>
      FirebaseDatabase.instance.ref('liveChat').child(widget.room.channel);

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final uid = ref.read(authStateProvider).value;
    _chatController.clear();
    await _chatRef.push().set({
      'userUid': uid ?? '',
      'userName': 'viewer',
      'text': text,
      'sentAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _sendGift(Gift gift) async {
    // Gift aparece na tela + soma no total da live
    try {
      await FirebaseFirestore.instance
          .collection('lives')
          .doc(widget.room.id)
          .update({'totalGifts': FieldValue.increment(1)});
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _floatingGifts.add(gift);
    });
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _floatingGifts.remove(gift));
    });
  }

  final List<Gift> _floatingGifts = [];

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    ref.read(liveServiceProvider).leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoArea(),
          // gradiente
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.giftOverlay.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                color: Colors.redAccent, size: 10),
                            const SizedBox(width: 6),
                            Text(
                              '${formatLiveClock(_elapsed)} · K ${room.viewers} · R\$15',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_agoraWarning != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _agoraWarning!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 11),
                      ),
                    ),
                  ),
                // Carrossel de gifts "coletar"
                _GiftBar(
                  onGift: (g) => _sendGift(g),
                ),
                const SizedBox(height: 8),
                _LiveChat(
                  chatRef: _chatRef,
                  onSend: _sendChat,
                  controller: _chatController,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // gifts flutuantes
          for (final g in _floatingGifts)
            Positioned(
              top: 120,
              left: 24,
              child: _FloatingGift(gift: g),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_agoraReady && widget.isHost && _localView != null) {
      return _localView!;
    }
    if (_agoraReady && !widget.isHost && _remoteView != null) {
      return _remoteView!;
    }
    // Demonstracao: gradiente no lugar da camera
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF3D1B4E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, color: Colors.white38, size: 64),
            const SizedBox(height: 8),
            Text(
              widget.isHost ? 'Você está transmitindo' : 'Assistindo ${widget.room.channel}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat da live em tempo real (Realtime Database).
class _LiveChat extends StatelessWidget {
  final DatabaseReference chatRef;
  final VoidCallback onSend;
  final TextEditingController controller;

  const _LiveChat({
    required this.chatRef,
    required this.onSend,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: chatRef.orderByChild('sentAt').limitToLast(50).onValue,
              builder: (context, snapshot) {
                final data = snapshot.data?.snapshot.value;
                if (data == null) {
                  return const Center(
                    child: Text('Chat da live',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                final messages = <LiveChatMessage>[];
                (data as Map).forEach((key, value) {
                  final m = Map<String, dynamic>.from(value as Map);
                  messages.add(LiveChatMessage.fromMap(key, m));
                });
                messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[messages.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${msg.userName}: ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: msg.text,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Diga algo...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send, color: AppColors.pink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GiftBar extends StatelessWidget {
  final ValueChanged<Gift> onGift;
  const _GiftBar({required this.onGift});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kGiftCarousel.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = kGiftCarousel[i];
          return GestureDetector(
            onTap: () => onGift(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.giftOverlay.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pink, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(g.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${g.name} x${g.multiplier}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingGift extends StatelessWidget {
  final Gift gift;
  const _FloatingGift({required this.gift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.giftOverlay.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(gift.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            'Ganhou ${gift.multiplier}x!',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
