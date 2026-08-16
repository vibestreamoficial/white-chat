import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/live.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import 'live_session_screen.dart';

/// Tela de Lives (estilo Kwai Live):
/// grid 2 colunas de salas + inputs Canal/Nome + botoes TRANSMITIR/ASSISTIR/PARAR.
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final _channel = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _channel.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _startLive() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final channel = _channel.text.trim();
    if (channel.isEmpty) {
      _toast('Digite um canal para transmitir');
      return;
    }
    final db = ref.read(databaseServiceProvider);
    final me = await db.getProfile(uid);
    final room = LiveRoom(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hostUid: uid,
      hostName: me?.name ?? '',
      hostUsername: me?.username ?? '',
      hostPhotoUrl: me?.photoUrl ?? '',
      channel: channel,
      title: _name.text.trim().isEmpty ? 'Ao vivo' : _name.text.trim(),
      startedAt: DateTime.now(),
    );
    await db.createLive(room);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveSessionScreen(room: room, isHost: true),
      ),
    );
  }

  void _watchLive(LiveRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveSessionScreen(room: room, isHost: false),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final lives = ref.watch(livesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text('Lives',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Inputs Canal / Seu nome (fundo #1e1e1e, sem underline)
              TextField(
                controller: _channel,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Canal (ex.: canal1)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Seu nome'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'TRANSMITIR',
                      color: AppColors.pink,
                      icon: Icons.sensors,
                      onTap: _startLive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'PARAR',
                      color: Colors.grey.shade700,
                      icon: Icons.stop,
                      onTap: () {
                        for (final room in lives.value ?? const <LiveRoom>[]) {
                          ref
                              .read(databaseServiceProvider)
                              .endLive(room.id);
                        }
                        _toast('Lives encerradas');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Ao vivo agora',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 12),
              lives.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.pink),
                  ),
                ),
                error: (e, _) => Text('Erro: $e',
                    style: const TextStyle(color: Colors.white54)),
                data: (list) => list.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.sensors_off,
                                color: Colors.white38, size: 40),
                            SizedBox(height: 8),
                            Text('Nenhuma live no momento.\nSeja o primeiro!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _LiveCard(
                          room: list[i],
                          onTap: () => _watchLive(list[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Card de live: thumbnail, badge AO VIVO pulsando, canal, nome, viewers.
class _LiveCard extends StatefulWidget {
  final LiveRoom room;
  final VoidCallback onTap;

  const _LiveCard({required this.room, required this.onTap});

  @override
  State<_LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<_LiveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          image: room.hostPhotoUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(room.hostPhotoUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: FadeTransition(
                opacity: _pulse,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('AO VIVO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${room.viewers >= 1000 ? '${(room.viewers / 1000).toStringAsFixed(1)}k' : room.viewers}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canal: ${room.channel}',
                    style: const TextStyle(
                        color: Color(0xFF25F4EE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.hostName.isEmpty ? '@${room.hostUsername}' : room.hostName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
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
