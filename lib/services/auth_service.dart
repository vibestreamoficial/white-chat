import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';

/// Autenticacao: Google, Email/Senha e Telefone.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Login com Google cancelado.');
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Envia o codigo de verificacao do telefone e retorna a
  /// [verificationId] para confirmar depois com [verifyPhoneCode].
  Future<String> sendPhoneCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    String sentId = '';
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android: verificacao automatica (sem precisar digitar codigo)
        await _auth.signInWithCredential(credential);
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
    return _auth.signInWithCredential(credential);
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
    await _auth.signOut();
  }
}
