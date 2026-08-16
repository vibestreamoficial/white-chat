/// Configuracao central do app.
///
/// 1) AGORA_APP_ID: crie uma conta em https://console.agora.io e um projeto,
///    depois cole o App ID aqui para as lives funcionarem.
/// 2) Os dados do Firebase sao carregados de lib/firebase_options.dart
///    (gere com: `flutterfire configure` ou cole manualmente).
class AppConfig {
  AppConfig._();

  /// App ID do Agora para live streaming (RTC).
  /// Troque "SEU_AGORA_APP_ID" pelo seu App ID real.
  static const String agoraAppId = 'SEU_AGORA_APP_ID';

  /// Nome exibido no app.
  static const String appName = 'WHITE CHAT';

  /// Tempo maximo de gravacao de video (segundos).
  static const int maxVideoSeconds = 300; // 5 minutos

  /// Limite de caracteres da legenda.
  static const int maxCaptionLength = 150;
}
