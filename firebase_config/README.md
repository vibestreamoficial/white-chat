# Firebase do WHITE CHAT

O app abre direto no login. O Firebase real so entra quando o arquivo
`google-services.json` do seu projeto for adicionado.

## Como ativar (1 minuto)

1. No [Firebase Console](https://console.firebase.google.com), crie o projeto
   e adicione um **app Android** com pacote: `com.whitechat.app`
2. Em **Authentication -> Sign-in method**, ative: E-mail/Senha, Google e
   Telefone. Em **Settings -> Authorized domains**, adicione `localhost`.
3. Cadastre as impressões digitais (corrige o erro 10 do Google):
   ```bash
   bash firebase_config/fingerprints.sh
   ```
   Cole as SHA-1 e SHA-256 (debug e release) no Firebase Console.
4. Baixe o `google-services.json` (Android) e coloque NESTA pasta:
   `firebase_config/google-services.json`
5. Rode:
   ```bash
   bash firebase_config/ativar_firebase.sh
   ```
   O script copia o arquivo para `android/app/`, gera as chaves reais em
   `lib/firebase_options.dart` (sem placeholder) e recompila o APK.

## Sem o arquivo

O app não trava nem mostra tela preta: ele abre no login normalmente e
mostra um SnackBar avisando que o `google-services.json` ainda não foi
adicionado.

## Segurança

O `firebase_config/google-services.json` é ignorado pelo Git (não vai para
o GitHub). No CI do GitHub Actions, use o secret
`FIREBASE_GOOGLE_SERVICES_JSON` com o conteúdo do arquivo.
