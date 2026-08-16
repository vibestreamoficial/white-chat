import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Chat 1-para-1 em tempo real (Firebase Realtime Database).
class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _convId;
  bool _typing = false;
  Timer? _typingDebounce;
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final chat = ref.read(chatServiceProvider);
    final convId = await chat.openConversation(uid, widget.conversation.otherUid);
    if (!mounted) return;
    setState(() => _convId = convId);
    chat.touchLastSeen(uid);
  }

  Future<void> _send() async {
    final uid = ref.read(authStateProvider).value;
    final text = _input.text.trim();
    final convId = _convId;
    if (uid == null || convId == null || text.isEmpty) return;
    _input.clear();
    await ref.read(chatServiceProvider).sendText(convId, uid, text);
    _scrollToBottom();
  }

  Future<void> _sendMedia(String type) async {
    final uid = ref.read(authStateProvider).value;
    final convId = _convId;
    if (uid == null || convId == null) return;
    final picker = ImagePicker();
    try {
      String? path;
      if (type == 'image') {
        final f = await picker.pickImage(source: ImageSource.gallery);
        path = f?.path;
      } else if (type == 'video') {
        final f = await picker.pickVideo(source: ImageSource.gallery);
        path = f?.path;
      } else if (type == 'audio') {
        // gravador externo; aqui apenas demonstra o envio de arquivo
        final f = await picker.pickVideo(source: ImageSource.gallery);
        path = f?.path;
      }
      if (path == null) return;
      final url = await StorageService().uploadFile(
        file: File(path),
        folder: 'chat',
        uid: uid,
        ext: type == 'image' ? 'jpg' : (type == 'video' ? 'mp4' : 'm4a'),
      );
      await ref.read(chatServiceProvider).sendMedia(convId, uid, type, url);
    } catch (_) {}
  }

  void _onTypingChanged(String value) {
    final uid = ref.read(authStateProvider).value;
    final convId = _convId;
    if (uid == null || convId == null) return;
    final chat = ref.read(chatServiceProvider);
    final nowTyping = value.isNotEmpty;
    if (nowTyping != _typing) {
      _typing = nowTyping;
      chat.setTyping(convId, uid, nowTyping);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (_typing) {
        _typing = false;
        chat.setTyping(convId, uid, false);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.conversation;
    final uid = ref.watch(authStateProvider).value;
    final chat = ref.watch(chatServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.otherName.isEmpty ? c.otherUsername : c.otherName,
              style: const TextStyle(fontSize: 16),
            ),
            _buildPresence(c.otherUid),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: AppColors.textDark),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _convId == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pink),
                    )
                  : StreamBuilder<List<ChatMessage>>(
                      stream: chat.streamMessages(_convId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Erro: ${snapshot.error}',
                                style: const TextStyle(color: Colors.black54)),
                          );
                        }
                        final messages = snapshot.data ?? const <ChatMessage>[];
                        if (messages.isEmpty) {
                          return const Center(
                            child: Text('Diga olá 👋',
                                style: TextStyle(
                                    color: AppColors.textGrey, fontSize: 14)),
                          );
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scroll.hasClients) {
                            _scroll.jumpTo(_scroll.position.maxScrollExtent);
                          }
                        });
                        return ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (_, i) => _MessageBubble(
                            message: messages[i],
                            mine: messages[i].senderUid == uid,
                          ),
                        );
                      },
                    ),
            ),
            // status "digitando..." em tempo real
            StreamBuilder<bool>(
              stream: _convId == null
                  ? Stream<bool>.value(false)
                  : chat.streamTyping(_convId!, c.otherUid),
              builder: (context, snapshot) {
                final typing = snapshot.data ?? false;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: typing ? 18 : 0,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'digitando...',
                    style: TextStyle(
                        color: AppColors.pink,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                );
              },
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresence(String otherUid) {
    final convId = _convId;
    final typingState = convId == null
        ? AsyncValue<bool>.data(false)
        : ref.watch(chatTypingProvider(ChatTypingKey(convId, otherUid)));
    final lastSeen = ref.watch(lastSeenProvider(otherUid));
    final isTyping = typingState.value ?? false;
    final last = lastSeen.value;

    String text;
    if (isTyping) {
      text = 'digitando...';
    } else if (last == null) {
      text = 'offline';
    } else {
      final diff = DateTime.now().difference(last);
      if (diff.inMinutes < 1) {
        text = 'ativo agora';
      } else if (diff.inMinutes < 60) {
        text = 'Ativo há ${diff.inMinutes} minutos atrás';
      } else if (diff.inHours < 24) {
        text = 'Ativo há ${diff.inHours} horas atrás';
      } else {
        text = 'Ativo há ${diff.inDays} dias atrás';
      }
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: isTyping ? AppColors.pink : AppColors.textGrey,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          _MediaIcon(Icons.add_circle_outline, () => _showMediaMenu()),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _input,
              onChanged: _onTypingChanged,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Mensagem',
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.pinkStart, AppColors.pinkEnd],
                ),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.pink),
              title: const Text('Enviar imagem'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMedia('image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: AppColors.pink),
              title: const Text('Enviar vídeo'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMedia('video');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_outlined, color: AppColors.pink),
              title: const Text('Enviar áudio'),
              onTap: () {
                Navigator.pop(ctx);
                _sendMedia('audio');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final time = '${message.sentAt.hour.toString().padLeft(2, '0')}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.pink : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == 'image' && message.mediaUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(message.mediaUrl,
                    width: 180, fit: BoxFit.cover),
              )
            else if (message.type == 'video' && message.mediaUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 180,
                  height: 110,
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white.withOpacity(0.9),
                      size: 40,
                    ),
                  ),
                ),
              )
            else if (message.type == 'audio' && message.mediaUrl.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: mine ? Colors.white : AppColors.textDark),
                  const SizedBox(width: 6),
                  Text('Áudio',
                      style: TextStyle(
                          color: mine ? Colors.white : AppColors.textDark)),
                ],
              )
            else
              Text(
                message.text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.textDark,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: mine ? Colors.white70 : AppColors.textGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MediaIcon(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textGrey, size: 26),
    );
  }
}
