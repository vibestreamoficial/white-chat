import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/user_profile.dart';

/// Autenticacao: Google, Email/Senha e Telefone.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  FirebaseAuth? _auth;

  FirebaseAuth get _instance {
    _checkConfigured();
    return _auth ??= FirebaseAuth.instance;
  }

  void _checkConfigured() {
    if (!DefaultFirebaseOptions.configured) {
      throw Exception(
        'Firebase nao configurado. Coloque google-services.json em firebase_config/ '
        'e rode: bash firebase_config/ativar_firebase.sh',
      );
    }
  }

  Stream<User?> get authStateChanges => _instance.authStateChanges();

  User? get currentUser => _instance.currentUser;

  String? get currentUid => _instance.currentUser?.uid;

  /// Traduz erros do Firebase em mensagens amigaveis em portugues.
  String _translateError(dynamic e) {
    final msg = e.toString();
    final code = e is FirebaseAuthException ? e.code : '';

    if (code == 'operation-not-allowed') {
      return 'Este metodo de login nao esta habilitado.\n'
          'Va no Console Firebase > Authentication > Sign-in method '
          'e ative: E-mail/Senha, Google e Telefone.';
    }
    if (code == 'wrong-password' || code == 'user-not-found' ||
        code == 'invalid-credential') {
      return 'E-mail ou senha incorretos.';
    }
    if (code == 'email-already-in-use') {
      return 'Este e-mail ja esta cadastrado. Faca login.';
    }
    if (code == 'weak-password') {
      return 'Senha muito fraca. Use no minimo 6 caracteres.';
    }
    if (code == 'invalid-email') {
      return 'E-mail invalido.';
    }
    if (code == 'too-many-requests') {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (code == 'network-request-failed') {
      return 'Sem conexao com a internet.';
    }
    if (msg.contains('10') && msg.contains('ApiException')) {
      return 'Erro na configuracao do Google Sign-In.\n'
          'Verifique os certificados SHA-1/SHA-256 no Console Firebase '
          'e o arquivo google-services.json.';
    }
    if (code == 'quota-exceeded') {
      return 'Limite de tentativas atingido. Aguarde e tente novamente.';
    }

    // Mensagem generica
    if (msg.length > 120) {
      return 'Erro ao fazer login. Tente novamente.';
    }
    return msg;
  }

  Future<UserCredential> signInWithGoogle() async {
    _checkConfigured();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Login com Google cancelado.');
      }
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _instance.signInWithCredential(credential);
    } catch (e) {
      throw Exception(_translateError(e));
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(_translateError(e));
    }
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(_translateError(e));
    }
  }

  Future<String> sendPhoneCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    _checkConfigured();
    String sentId = '';
    try {
      await _instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          onError(_translateError(e));
        },
        codeSent: (verificationId, resendToken) {
          sentId = verificationId;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      onError(_translateError(e));
    }
    return sentId;
  }

  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _instance.signInWithCredential(credential);
    } catch (e) {
      throw Exception(_translateError(e));
    }
  }

  UserProfile defaultProfile(User user) {
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
    await _googleSignIn.signOut();
    if (DefaultFirebaseOptions.configured) {
      await _instance.signOut();
    }
  }
}
