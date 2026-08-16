import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Criacao de conta por e-mail + perfil inicial (direciona para Editar Perfil).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      final cred = await auth.registerWithEmail(_email.text, _password.text);
      final user = cred.user!;

      // Cadastro so com usuario + e-mail + senha: o usuario vira o nome
      // de exibicao do perfil (tela Editar Perfil).
      final username = _username.text.trim().toLowerCase();
      final profile = auth.defaultProfile(user).copyWith(
            name: username,
            username: username,
          );
      await ref.read(databaseServiceProvider).saveProfile(profile);
      await user.updateProfile(displayName: username);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete seu perfil',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seus dados aparecem para quem te segue.',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              TextField(controller: _username, decoration: _dec('Nome de usuário')),
              const SizedBox(height: 12),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _dec('E-mail')),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: true, decoration: _dec('Senha (mín. 6)')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cadastrar',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
