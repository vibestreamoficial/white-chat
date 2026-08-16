import 'package:firebase_auth/firebase_auth.dart';

/// Usuario da sessao atual.
///
/// Com o Firebase configurado, encapsula o [User] do FirebaseAuth.
/// Sem o google-services.json (modo demonstracao), e uma sessao local
/// apenas para testar o app (nada e enviado para a internet).
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final User? firebaseUser;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.firebaseUser,
  });

  factory AppUser.fromFirebase(User u) => AppUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoURL: u.photoURL,
        firebaseUser: u,
      );

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    await firebaseUser?.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
    );
  }
}

/// Resultado de um login (Firebase real ou demonstracao).
class AppCredential {
  final AppUser user;
  const AppCredential(this.user);
}
