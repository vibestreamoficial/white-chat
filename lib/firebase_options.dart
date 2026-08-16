import 'package:firebase_core/firebase_core.dart';

// IMPORTANTE: arquivo de opcoes do Firebase.
//
// A forma mais facil de gerar este arquivo:
//   1) Crie o projeto no console Firebase (https://console.firebase.google.com)
//      com o pacote do app: com.whitechat.app
//   2) Adicione um app Android (informe o SHA-1 da assinatura de release)
//   3) Rode na pasta do projeto:
//        dart pub global activate flutterfire_cli
//        flutterfire configure
//   4) O flutterfire_cli gera este arquivo e o android/app/google-services.json
//
// Se preferir manual: copie os valores do seu google-services.json para as
// constantes abaixo e baixe o google-services.json para android/app/.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions initial = FirebaseOptions(
    apiKey: 'SUA_API_KEY',
    appId: 'SEU_APP_ID',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    // Necessario para o chat em tempo real:
    databaseURL: 'https://SEU_PROJECT_ID-default-rtdb.firebaseio.com',
  );
}
