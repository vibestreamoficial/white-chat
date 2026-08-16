import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import '../../models/post.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Criar post: grava ate 5 minutos (botao +), adiciona legenda e publica.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  CameraController? _camera;
  List<CameraDescription>? _cameras;
  XFile? _recordedVideo;
  XFile? _pickedImage;
  final _caption = TextEditingController();
  final _music = TextEditingController();
  bool _allowComments = true;
  bool _allowDuet = true;
  bool _recording = false;
  bool _publishing = false;
  int _elapsed = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;
      _camera = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _camera!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      // camera indisponivel: usuario pode escolher da galeria
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _recordedVideo = video;
        _pickedImage = null;
      });
      return;
    }
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _recordedVideo = null;
      });
    }
  }

  Future<void> _toggleRecording() async {
    final camera = _camera;
    if (camera == null) return;
    if (_recording) {
      final file = await camera.stopVideoRecording();
      setState(() {
        _recordedVideo = file;
        _recording = false;
        _elapsed = 0;
      });
    } else {
      await camera.startVideoRecording();
      setState(() => _recording = true);
      _tick();
    }
  }

  Future<void> _tick() async {
    while (_recording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= AppConfig.maxVideoSeconds) {
        await _toggleRecording();
        return;
      }
    }
  }

  Future<void> _publish() async {
    if ((_recordedVideo == null && _pickedImage == null) || _publishing) return;
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final db = ref.read(databaseServiceProvider);
      final me = await db.getProfile(uid);

      String mediaUrl = '';
      final file = _recordedVideo != null
          ? File(_recordedVideo!.path)
          : File(_pickedImage!.path);
      if (file.existsSync()) {
        mediaUrl = await StorageService().uploadFile(
              file: file,
              folder: _recordedVideo != null ? 'videos' : 'images',
              uid: uid,
              ext: _recordedVideo != null ? 'mp4' : 'jpg',
            );
      }

      final post = VideoPost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        authorUid: uid,
        authorName: me?.name ?? '',
        authorUsername: me?.username ?? '',
        authorPhotoUrl: me?.photoUrl ?? '',
        mediaUrl: mediaUrl,
        caption: _caption.text.trim(),
        music: _music.text.trim(),
        allowComments: _allowComments,
        allowDuet: _allowDuet,
        status: 'pendente', // entra na fila de moderacao
        createdAt: DateTime.now(),
      );
      await db.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post enviado! Aguardando aprovação 📤')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _caption.dispose();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        title: const Text('Criar post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPreviewArea(),
              const SizedBox(height: 16),
              TextField(
                controller: _caption,
                maxLength: AppConfig.maxCaptionLength,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Legenda (use #hashtags)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _music,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Música / som'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _allowComments,
                onChanged: (v) => setState(() => _allowComments = v),
                title: const Text('Permitir comentários',
                    style: TextStyle(color: Colors.white)),
                activeColor: AppColors.pink,
              ),
              SwitchListTile(
                value: _allowDuet,
                onChanged: (v) => setState(() => _allowDuet = v),
                title: const Text('Permitir dueto',
                    style: TextStyle(color: Colors.white)),
                activeColor: AppColors.pink,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _publishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('PUBLICAR',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    final hasMedia = _recordedVideo != null || _pickedImage != null;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasMedia
            ? (_pickedImage != null
                ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                : _recordedVideo == null
                    ? const SizedBox.shrink()
                    : _camera != null
                        ? CameraPreview(_camera!)
                        : const Center(
                            child: Text('Vídeo gravado ✅',
                                style: TextStyle(color: Colors.white70))))
            : _camera != null && _camera!.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_camera!),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              _recording
                                  ? '⏺ Gravando ${_elapsed}s / ${AppConfig.maxVideoSeconds}s'
                                  : 'Toque para gravar (máx. 5 min)',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _toggleRecording,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _recording
                                      ? Colors.redAccent
                                      : AppColors.pink,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                                child: Icon(
                                  _recording ? Icons.stop : Icons.videocam,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off,
                            color: Colors.white38, size: 48),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _pickFromGallery,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: const Text('Escolher da galeria'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickFromGallery,
                          child: const Text('Galeria',
                              style: TextStyle(color: AppColors.pink)),
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
      counterStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
