import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/user_profile.dart';

/// Autenticacao: Google, Email/Senha e Telefone.
///
/// Sem o google-services.json o app entra em MODO DEMONSTRACAO: o login
/// aceita qualquer e-mail/senha e cria uma sessao local. Com o Firebase
/// configurado, usa o FirebaseAuth real.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth? _auth;
  final StreamController<AppUser?> _demoController =
      StreamController<AppUser?>.broadcast();
  AppUser? _demoUser;

  bool get _demoMode => !DefaultFirebaseOptions.configured;

  FirebaseAuth get _instance {
    if (_demoMode) {
      throw StateError('Firebase nao inicializado (modo demonstracao).');
    }
    return _auth ??= FirebaseAuth.instance;
  }

  Stream<AppUser?> get authStateChanges {
    if (_demoMode) {
      // Emite imediatamente o usuario atual (null = deslogado) e depois
      // segue as mudancas do login/sair local.
      return Stream.multi((controller) {
        late final StreamSubscription<AppUser?> sub;
        controller.add(_demoUser);
        sub = _demoController.stream.listen(controller.add);
        controller.onCancel = () => sub.cancel();
      });
    }
    return _instance.authStateChanges().map(AppUser.fromFirebase);
  }

  AppUser? get currentUser {
    if (_demoMode) return _demoUser;
    final u = _instance.currentUser;
    return u == null ? null : AppUser.fromFirebase(u);
  }

  String? get currentUid => currentUser?.uid;

  Future<AppCredential> signInWithGoogle() async {
    if (_demoMode) {
      return _demoLogin('convidado@demo.local', 'Convidado');
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login com Google cancelado.');
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _instance.signInWithCredential(credential);
    return AppCredential(AppUser.fromFirebase(cred.user!));
  }

  Future<AppCredential> signInWithEmail(String email, String password) async {
    if (_demoMode) return _demoLogin(email);
    final cred = await _instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppCredential(AppUser.fromFirebase(cred.user!));
  }

  Future<AppCredential> registerWithEmail(String email, String password) async {
    if (_demoMode) return _demoLogin(email);
    final cred = await _instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppCredential(AppUser.fromFirebase(cred.user!));
  }

  AppCredential _demoLogin(String email, [String? displayName]) {
    final local = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-z0-9_.-]'), '')
        .toLowerCase();
    final user = AppUser(
      uid: 'demo_${local.isEmpty ? 'user' : local}',
      email: email,
      displayName: displayName ?? local,
    );
    _demoUser = user;
    _demoController.add(user);
    return AppCredential(user);
  }

  /// Envia o codigo de verificacao do telefone e retorna a
  /// [verificationId] para confirmar depois com [verifyPhoneCode].
  ///
  /// No modo demonstracao simula o envio: aceita qualquer codigo.
  Future<String> sendPhoneCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    if (_demoMode) {
      onCodeSent('demo', null);
      return 'demo';
    }
    String sentId = '';
    await _instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android: verificacao automatica (sem precisar digitar codigo)
        await _instance.signInWithCredential(credential);
      },
      verificationFailed: (e) => onError(e.message ?? 'Falha ao enviar codigo.'),
      codeSent: (verificationId, resendToken) {
        sentId = verificationId;
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
    return sentId;
  }

  Future<AppCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    if (_demoMode) {
      return _demoLogin('usuario_demo@demo.local', 'Usuario Demo');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _instance.signInWithCredential(credential);
    return AppCredential(AppUser.fromFirebase(cred.user!));
  }

  /// Perfil padrao criado na primeira entrada (igual tela Editar Perfil).
  UserProfile defaultProfile(AppUser user) {
    final name = user.displayName ?? '';
    final username = _usernameFromEmail(user.email) ?? 'user${user.uid.substring(0, 6)}';
    return UserProfile(
      uid: user.uid,
      name: name,
      username: username,
      photoUrl: user.photoURL ?? '',
      createdAt: DateTime.now(),
    );
  }

  String? _usernameFromEmail(String? email) {
    if (email == null) return null;
    final local = email.split('@').first.toLowerCase();
    return local.replaceAll(RegExp(r'[^a-z0-9_.]'), '');
  }

  Future<void> signOut() async {
    if (_demoMode) {
      _demoUser = null;
      _demoController.add(null);
      return;
    }
    await _googleSignIn.signOut();
    await _instance.signOut();
  }
}
