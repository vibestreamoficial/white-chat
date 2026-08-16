import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';

/// Login com Google, Email e Telefone.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationId;
  bool _loading = false;
  String? _error;
  bool _phoneStep2 = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _ensureProfile(User user) async {
    final db = ref.read(databaseServiceProvider);
    final existing = await db.getProfile(user.uid);
    if (existing == null) {
      final profile = ref.read(authServiceProvider).defaultProfile(user);
      await db.saveProfile(profile);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await ref.read(authServiceProvider).signInWithGoogle();
      await _ensureProfile(cred.user!);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      UserCredential cred;
      try {
        cred = await auth.signInWithEmail(_emailController.text, _passwordController.text);
      } catch (_) {
        cred = await auth.registerWithEmail(_emailController.text, _passwordController.text);
      }
      await _ensureProfile(cred.user!);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPhoneCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendPhoneCode(
            _phoneController.text,
            onCodeSent: (id, _) {
              setState(() {
                _verificationId = id;
                _phoneStep2 = true;
                _loading = false;
              });
            },
            onError: (msg) {
              setState(() {
                _error = msg;
                _loading = false;
              });
            },
          );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyPhoneCode() async {
    if (_verificationId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await ref
          .read(authServiceProvider)
          .verifyPhoneCode(_verificationId!, _codeController.text);
      await _ensureProfile(cred.user!);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.play_circle_fill, color: AppColors.pink, size: 72),
                const SizedBox(height: 8),
                const Text(
                  'WHITE CHAT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Clone Kwai: vídeos, lives e chat em tempo real',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 28),

                _GoogleButton(onTap: _loading ? null : _signInWithGoogle),

                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: AppColors.textGrey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),

                if (!_phoneStep2) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _dec('Senha'),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'Entrar com e-mail',
                    onTap: _loading ? null : _signInWithEmail,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('Telefone com DDI (ex.: +5511999999999)'),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'Enviar código por SMS',
                    onTap: _loading ? null : _sendPhoneCode,
                  ),
                ] else ...[
                  const Text(
                    'Digite o código recebido por SMS:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Código de verificação'),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryButton(
                    label: 'Verificar código',
                    onTap: _loading ? null : _verifyPhoneCode,
                  ),
                ],

                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Criar conta nova'),
                ),
              ],
            ),
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

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4285F4))),
      label: const Text('Continuar com Google',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
