import 'package:firebase_core/firebase_core.dart';

// Gerado automaticamente (nao edite a mao).
//
// configured=false: o google-services.json ainda nao foi adicionado ao
// projeto. O app abre normalmente no login e avisa com um SnackBar.
//
// Para ativar o Firebase de verdade:
//   1) Baixe o google-services.json do seu projeto Firebase
//      (app Android com pacote com.whitechat.app)
//   2) Coloque o arquivo na pasta firebase_config/
//   3) Rode: bash firebase_config/ativar_firebase.sh
//
// O script copia o arquivo para android/app/, gera este arquivo com as
// chaves reais e recompila o APK.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// true quando o Firebase real foi configurado.
  static const bool configured = false;

  static const FirebaseOptions initial = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
    databaseURL: '',
  );
}
