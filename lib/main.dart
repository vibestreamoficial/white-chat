import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/fcm_service.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase somente quando o google-services.json foi
  // configurado (firebase_config/ativar_firebase.sh). Se faltar, o app
  // abre normal no login e avisa via SnackBar — nunca trava em tela preta.
  FirebaseApp? firebase;
  String? firebaseError;
  if (DefaultFirebaseOptions.configured) {
    try {
      firebase = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.initial,
      );
    } catch (e) {
      firebaseError = e.toString();
    }
  } else {
    firebaseError =
        'Modo demonstracao ativo: login local com qualquer e-mail/senha. '
        'Para dados reais, configure o Firebase (firebase_config/).';
  }

  if (firebase != null) {
    try {
      await FcmService().init();
    } catch (_) {/* FCM opcional */}
  }

  runApp(
    ProviderScope(
      child: WhiteChatApp(firebaseError: firebaseError),
    ),
  );
}

class WhiteChatApp extends ConsumerWidget {
  final String? firebaseError;

  const WhiteChatApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _Root(firebaseError: firebaseError),
    );
  }
}

/// Raiz do app: abre direto na tela de login do WHITE CHAT.
/// Se o Firebase nao estiver configurado, avisa uma unica vez com SnackBar.
class _Root extends ConsumerStatefulWidget {
  final String? firebaseError;

  const _Root({this.firebaseError});

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _avisou = false;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseError != null && widget.firebaseError!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _avisou) return;
        _avisou = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.firebaseError!),
            backgroundColor: AppColors.pink,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Com ou sem Firebase configurado, o app abre direto no login.
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      ),
      error: (e, _) => const LoginScreen(),
      data: (uid) {
        if (uid == null) {
          return const LoginScreen();
        }
        return const ShellScreen();
      },
    );
  }
}
