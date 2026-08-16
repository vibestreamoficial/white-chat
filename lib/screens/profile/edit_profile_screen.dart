import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Tela Editar Perfil (clone do Kwai):
/// header "Editar perfil" + "Complete seu perfil", foto circular 120px com
/// icone de camera, lista com icones outline (Nome, Nome de Usuário, Sexo,
/// Aniversário, Bio, Moldura de perfil com bolinha vermelha, Instagram)
/// e seta > na direita de cada item. Fundo branco.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _instagram = TextEditingController();

  String _gender = '';
  String _birthday = '';
  String _frame = 'Clássica';
  String? _photoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    final profile =
        await ref.read(databaseServiceProvider).getProfile(uid);
    if (profile == null || !mounted) return;
    setState(() {
      _name.text = profile.name;
      _username.text = profile.username;
      _bio.text = profile.bio;
      _instagram.text = profile.instagram;
      _gender = profile.gender;
      _birthday = profile.birthday;
      _frame = profile.frame.isEmpty ? 'Clássica' : profile.frame;
      _photoUrl = profile.photoUrl;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final uid = ref.read(authStateProvider).value;
    setState(() => _saving = true);
    try {
      final url = await StorageService().uploadFile(
        file: File(file.path),
        folder: 'avatars',
        uid: uid ?? 'anon',
        ext: 'jpg',
      );
      if (mounted) setState(() => _photoUrl = url);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final username = _username.text.trim().toLowerCase();
      final taken = username.isNotEmpty
          ? await db.usernameTaken(username, uid)
          : false;
      if (taken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nome de usuário já está em uso.')),
          );
        }
        return;
      }
      final profile = ref.read(myProfileProvider).value;
      await db.saveProfile(
        (profile ?? ref.read(authServiceProvider).defaultProfile(
            ref.read(authServiceProvider).currentUser!))
            .copyWith(
          name: _name.text.trim(),
          username: username,
          bio: _bio.text.trim(),
          instagram: _instagram.text.trim().replaceAll('@', ''),
          gender: _gender,
          birthday: _birthday,
          frame: _frame,
          photoUrl: _photoUrl ?? profile?.photoUrl ?? '',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil salvo ✅')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickGender() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Feminino', 'Masculino', 'Outro', 'Prefiro não dizer']
              .map((g) => ListTile(
                    title: Text(g),
                    onTap: () => Navigator.pop(ctx, g),
                  ))
              .toList(),
        ),
      ),
    );
    if (value != null) setState(() => _gender = value);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (date != null) {
      setState(() =>
          _birthday = '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.pink),
                  )
                : const Text('Salvar',
                    style: TextStyle(
                        color: AppColors.pink,
                        fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Complete seu perfil',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quanto mais completo, mais fácil encontrar amigos.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              // Foto circular 120px com icone de camera
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.pinkStart, AppColors.purpleEnd],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: const Color(0xFFE8E8E8),
                        backgroundImage: _photoUrl != null &&
                                _photoUrl!.isNotEmpty
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: _photoUrl == null || _photoUrl!.isEmpty
                            ? const Icon(Icons.person,
                                size: 52, color: AppColors.textGrey)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border:
                              Border.all(color: AppColors.textGrey, width: 1),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 17, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ItemRow(
                icon: Icons.person_outline,
                label: 'Nome',
                value: _name.text,
                onTap: () => _openEditor('Nome', _name, (v) => _name.text = v),
              ),
              _ItemRow(
                icon: Icons.alternate_email,
                label: 'Nome de Usuário',
                value: _username.text,
                onTap: () => _openEditor(
                    'Nome de Usuário', _username, (v) => _username.text = v),
              ),
              _ItemRow(
                icon: Icons.wc,
                label: 'Sexo',
                value: _gender,
                onTap: _pickGender,
              ),
              _ItemRow(
                icon: Icons.cake_outlined,
                label: 'Aniversário',
                value: _birthday,
                onTap: _pickBirthday,
              ),
              _ItemRow(
                icon: Icons.notes_outlined,
                label: 'Bio',
                value: _bio.text,
                onTap: () => _openEditor('Bio', _bio, (v) => _bio.text = v),
              ),
              _ItemRow(
                icon: Icons.portrait_outlined,
                label: 'Moldura de perfil',
                value: _frame,
                showRedDot: true,
                onTap: _pickFrame,
              ),
              _ItemRow(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram',
                value: _instagram.text,
                onTap: () => _openEditor(
                    'Instagram', _instagram, (v) => _instagram.text = v),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFrame() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Clássica', 'Rosa', 'Ciano', 'Roxa', 'Dourada']
              .map((f) => ListTile(
                    leading: Icon(
                      f == 'Clássica'
                          ? Icons.circle_outlined
                          : Icons.auto_awesome,
                      color: AppColors.pink,
                    ),
                    title: Text(f),
                    trailing: f == _frame
                        ? const Icon(Icons.check_circle,
                            color: AppColors.pink)
                        : null,
                    onTap: () => Navigator.pop(ctx, f),
                  ))
              .toList(),
        ),
      ),
    );
    if (value != null) setState(() => _frame = value);
  }

  Future<void> _openEditor(
    String title,
    TextEditingController controller,
    void Function(String) apply,
  ) async {
    final textController = TextEditingController(text: controller.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: title == 'Bio' ? 100 : 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('OK',
                style: TextStyle(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (result != null) {
      apply(result);
      setState(() {});
    }
  }
}

/// Linha de item com icone outline, label, valor e seta > (estilo Kwai).
class _ItemRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool showRedDot;

  const _ItemRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.showRedDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textGrey, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 14),
                ),
              ),
            const SizedBox(width: 8),
            if (showRedDot)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
