# 🎬 WHITE CHAT — app social estilo Kwai (Flutter)

App Android em **Flutter** com feed de vídeos, lives, chat em tempo real, sistema
de seguir, notificações e perfil — visual inspirado no Kwai (tema dark no feed,
branco em Mensagens/Editar Perfil, overlays de gift roxo escuro `#0A0A2A`,
destaques rosa `#FE2C55` e ciano `#25F4EE`).

Compatível com **Android 12, 13 e 14** (`minSdk 31`, `targetSdk 34`).

> ⚠️ Os 3 prints citados não vieram anexados nesta conversa, então as telas foram
> implementadas 1:1 a partir da descrição textual (cores, fontes, elementos e
> textos exatos de cada tela).

## Stack
- Flutter 3.22+ (Dart 3.4+)
- Firebase: Auth (Google/E-mail/Telefone), Firestore, Realtime Database, Storage, FCM
- Lives: `agora_rtc_engine` (Agora RTC)
- Vídeo: `video_player` + `chewie` (e `camera` para gravar até 5 min)
- Estado: Riverpod (`flutter_riverpod`)

## Estrutura
```
lib/
  main.dart                 entrada + gate de login
  config.dart               App ID do Agora e ajustes
  firebase_options.dart     credenciais do Firebase (preencher)
  theme/app_theme.dart      paleta e tema (Kwai)
  models/                   UserProfile, VideoPost, Conversation, ChatMessage,
                            LiveRoom, Gift, AppNotification
  services/                 Auth, Database (Firestore), Chat (RTDB),
                            Storage, Live (Agora), FCM
  state/providers.dart      providers Riverpod (feed, chats, notificações...)
  screens/
    auth/                   Login (Google/E-mail/Telefone) e Cadastro
    shell_screen.dart       bottom nav: Início | Jogo | + | Mensagens | Perfil
    feed/                   Feed "Para você"/"Seguindo", Criar post (câmera)
    messages/               Mensagens (3 abas de atividade) e Chat 1-1 real
    profile/                Perfil público e Editar Perfil (clone Kwai)
    live/                   Grade de lives + sessão (timer, viewers, chat, gifts)
    notifications/          Curtidas, Comentários e Seguidores
android/
  app/build.gradle.kts      assinatura release via key.properties
  key.properties            chave da assinatura (já gerada)
  whitechat-release.jks     keystore de release (senha: whitechat123)
```

## 1) Instalar Flutter
```bash
# Linux (ou use o Android Studio)
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"
flutter --version
```

## 2) Firebase (obrigatório para tudo funcionar)
1. Crie o projeto em https://console.firebase.google.com
2. Adicione um **app Android** com pacote `com.whitechat.app`
   (na assinatura, informe o SHA-1 do `whitechat-release.jks`, ver passo 5)
3. Baixe o **google-services.json** e copie para `android/app/`
4. Ative no console:
   - **Authentication** → Sign-in method: Google, E-mail/Senha, Telefone
   - **Firestore Database** (produção: regras conforme abaixo)
   - **Realtime Database** (chat 1-1 e chat de live)
   - **Storage** (uploads de vídeo/foto/avatar)
   - **Cloud Messaging** (notificações push)
5. Gere o `lib/firebase_options.dart` automaticamente:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=SEU_PROJECT_ID
```
   (ou edite manualmente `lib/firebase_options.dart` com as chaves do
   `google-services.json` + `databaseURL`)

### Regras sugeridas (Firestore)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} { allow read, write: if request.auth != null; }
  }
}
```
Realtime Database (regras): `{ ".read": "auth != null", ".write": "auth != null" }`
(Ajuste para produção conforme sua política.)

### Índices compostos (Firestore) — crie no console
- `posts`: `status ASC` + `createdAt DESC`
- `posts`: `authorUid ASC` + `createdAt DESC`
- `notifications`: `toUid ASC` + `createdAt DESC`
- `conversations`: `members ASC` + `lastMessageAt DESC`
- `comments`: `postId ASC` + `at ASC`
- `lives`: `active ASC` + `startedAt DESC`
- `follows`: `followerUid ASC`

## 3) Agora (lives reais)
1. Crie conta em https://console.agora.io e crie um projeto
2. Copie o **App ID** e cole em `lib/config.dart` → `AppConfig.agoraAppId`
3. Sem o App ID, o app funciona em modo demonstração (timer, viewers, chat e
   gifts aparecem na tela, mas sem vídeo real).

## 4) Google Sign-In
No console Firebase → Authentication → Providers → Google, copie o **Web client
ID** e cole em `android/app/src/main/res/values/strings.xml` →
`default_web_client_id`.

## 5) Assinatura de release (já pronta)
O projeto já vem com:
- `android/whitechat-release.jks` (keystore, válido ~27 anos)
- `android/key.properties` (alias `whitechat`, senha `whitechat123`)

> 🔒 Troque a senha antes de publicar na loja
> (`keytool -storepasswd -keystore whitechat-release.jks` e atualize
> `key.properties`). Guarde o keystore em local seguro — sem ele não é
> possível atualizar o app na loja.

**Sem o `google-services.json`, o APK ainda compila** (modo demonstração:
o app abre mostrando o passo a passo do Firebase). Com o arquivo em
`android/app/`, o app fica completo (login, feed, chat, live, notificações).

## 6) Gerar os APKs
```bash
cd white_chat
flutter pub get

# APK debug (teste rápido)
flutter build apk --debug
# sai em: build/app/outputs/flutter-apk/app-debug.apk

# APK release assinado (com keystore acima)
flutter build apk --release
# sai em: build/app/outputs/flutter-apk/app-release.apk

# Releases por ABI (menores, recomendado)
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

Para instalar no celular:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```
ou envie o APK para o seu celular (Android 12/13/14).

## 6.1) Gerar APK na nuvem (GitHub Actions) — sem instalar Flutter

O projeto já vem com `.github/workflows/build-apk.yml`. Assim você baixa os
APKs prontos sem precisar de computador com Flutter:

1. Suba o projeto para um repositório no GitHub
   (`git init` → `git add .` → `git commit` → crie o repo → `git push`).
2. No GitHub: **Settings → Secrets and variables → Actions → New repository
   secret**:
   - Nome: `FIREBASE_GOOGLE_SERVICES_JSON`
   - Valor: o conteúdo **inteiro** do seu `android/app/google-services.json`
3. Aba **Actions** → selecione o workflow **Build APK (WHITE CHAT)** →
   **Run workflow**.
4. Quando terminar, abra o run e baixe o artefato **white-chat-apks**
   (contém `app-debug.apk`, `app-release.apk` e os APKs por ABI).

Sem o secret, o workflow ainda gera os APKs (modo demonstração). Com o
secret, ele preenche sozinho o `lib/firebase_options.dart`, roda
`flutter pub get` e gera os APKs debug, release assinado e por ABI.


## 6.3) Ativar Firebase com 1 comando (sem placeholder)

1. Baixe o `google-services.json` do Firebase Console (app Android
   `com.whitechat.app`).
2. Coloque o arquivo em `firebase_config/google-services.json`.
3. Rode:
   ```bash
   bash firebase_config/ativar_firebase.sh
   ```
O script copia o arquivo para `android/app/`, gera as chaves reais em
`lib/firebase_options.dart` e recompila o APK. Sem o arquivo, o app abre
direto no login (fundo branco) e mostra um SnackBar avisando — sem tela
preta. Para o erro 10 do Google Sign-In, rode
`bash firebase_config/fingerprints.sh` e cadastre as SHA-1/SHA-256 no
Firebase Console.

## 7) Moderação de posts
Posts novos entram como **Pendente** e só aparecem no feed após aprovação.
Para aprovar, atualize o campo `status` do documento em `posts/` para
`aprovado` no console do Firebase (ou implemente o painel admin em
`/admin` do seu site).

## Notas
- O feed "Seguindo" usa `whereIn` (máx. 10 uids por consulta); para muitos
  seguidos, migre para consulta por batches no `database_service.dart`.
- O chat 1-1 usa o **Realtime Database** (mensagens, digitando, online).
- Notificações locais aparecem com o app aberto via FCM; para push quando
  fechado, salve o token FCM no perfil e envie pelo console/backend.
- Código 100% aberto: revise antes de publicar conteúdo ou usar em produção.
