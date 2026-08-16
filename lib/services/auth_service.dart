import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/user_profile.dart';

/// Autenticacao: Google, Email/Senha e Telefone.
///
/// Se o Firebase ainda nao foi configurado (faltando o google-services.json),
/// os metodos lanca uma mensagem amigavel em vez de erro tecnico de API key.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseAuth? _auth;

  FirebaseAuth get _instance {
    _checkConfigured();
    return _auth ??= FirebaseAuth.instance;
  }

  void _checkConfigured() {
    if (!DefaultFirebaseOptions.configured) {
      throw Exception(
        'google-services.json nao encontrado. Coloque o arquivo na pasta '
        'firebase_config/ e rode: bash firebase_config/ativar_firebase.sh',
      );
    }
  }

  Stream<User?> get authStateChanges => _instance.authStateChanges();

  User? get currentUser => _instance.currentUser;

  String? get currentUid => _instance.currentUser?.uid;

  Future<UserCredential> signInWithGoogle() async {
    _checkConfigured();
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login com Google cancelado.');
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Envia o codigo de verificacao do telefone e retorna a
  /// [verificationId] para confirmar depois com [verifyPhoneCode].
  Future<String> sendPhoneCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    _checkConfigured();
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

  Future<UserCredential> verifyPhoneCode(String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _instance.signInWithCredential(credential);
  }

  /// Perfil padrao criado na primeira entrada (igual tela Editar Perfil).
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
