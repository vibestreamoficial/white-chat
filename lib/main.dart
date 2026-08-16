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

  // Inicializa o Firebase. Se as credenciais ainda nao foram configuradas
  // (firebase_options.dart + google-services.json), o app abre uma tela
  // de aviso mostrando o passo a passo.
  FirebaseApp? firebase;
  String? firebaseError;
  try {
    firebase = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.initial,
    );
  } catch (e) {
    firebaseError = e.toString();
  }

  if (firebase != null) {
    try {
      await FcmService().init();
    } catch (_) {/* FCM opcional */}
  }

  runApp(
    ProviderScope(
      child: WhiteChatApp(
        firebaseReady: firebase != null,
        firebaseError: firebaseError,
      ),
    ),
  );
}

class WhiteChatApp extends ConsumerWidget {
  final bool firebaseReady;
  final String? firebaseError;

  const WhiteChatApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _Root(firebaseReady: firebaseReady, firebaseError: firebaseError),
    );
  }
}

class _Root extends ConsumerWidget {
  final bool firebaseReady;
  final String? firebaseError;

  const _Root({required this.firebaseReady, this.firebaseError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseReady) {
      return _FirebaseSetupScreen(error: firebaseError);
    }

    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      ),
      error: (e, _) => _FirebaseSetupScreen(error: e.toString()),
      data: (uid) {
        if (uid == null) {
          return const LoginScreen();
        }
        return const ShellScreen();
      },
    );
  }
}

/// Tela exibida quando o Firebase ainda nao foi configurado.
class _FirebaseSetupScreen extends StatelessWidget {
  final String? error;

  const _FirebaseSetupScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.pink, size: 72),
                const SizedBox(height: 16),
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Falta conectar o Firebase para o app funcionar.\n\n'
                  '1. Crie um projeto em console.firebase.google.com\n'
                  '2. Adicione um app Android com pacote: com.whitechat.app\n'
                  '3. Baixe o google-services.json e coloque em android/app/\n'
                  '4. Edite lib/firebase_options.dart com as chaves do projeto\n'
                  '5. Ative Authentication (Google/E-mail/Telefone), Firestore,\n'
                  '   Realtime Database, Storage e Cloud Messaging\n\n'
                  'Depois disso, rode: flutter run',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.6),
                ),
                if (error != null && error!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Erro: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                const Icon(Icons.rocket_launch, color: AppColors.pink, size: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
