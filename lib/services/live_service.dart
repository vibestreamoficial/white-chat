import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';

/// Lives com o Agora RTC (agora_rtc_engine).
///
/// ANTES DE USAR:
///  - Cole o seu App ID em AppConfig.agoraAppId (lib/config.dart)
///  - Libere as permissoes de camera/microfone no AndroidManifest
///    (ja configuradas no projeto)
class LiveService {
  RtcEngine? _engine;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  /// Inicializa o engine do Agora.
  /// Sem App ID configurado, retorna false com [warning] preenchido.
  Future<bool> init({required int uid}) async {
    if (_initialized) return true;
    if (AppConfig.agoraAppId.isEmpty ||
        AppConfig.agoraAppId == 'SEU_AGORA_APP_ID') {
      return false;
    }
    await _requestPermissions();

    final engine = await AgoraRtcEngineImpl.createWithConfig(
      RtcEngineConfig(appId: AppConfig.agoraAppId),
    );
    await engine.initialize();

    // Roles padrao para broadcast (host + audience)
    await engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await engine.enableVideo();
    await engine.enableAudio();

    _engine = engine;
    _initialized = true;
    return true;
  }

  Future<void> startHost(String channel) async {
    await _engine?.setClientRole(ClientRoleType.clientRoleBroadcaster);
    await _engine?.enableLocalVideo(true);
    await _engine?.enableLocalAudio(true);
    await _engine?.startPreview();
    await _engine?.joinChannel(
      token: '',
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> joinAudience(String channel) async {
    await _engine?.setClientRole(ClientRoleType.clientRoleAudience);
    await _engine?.joinChannel(
      token: '',
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  /// Substitui o video local (host) na tela.
  Future<void> setupLocalVideo(RtcSurfaceView view, {bool mirror = true}) async {
    await _engine?.setVideoSource(VideoSourceType.videoSourceCamera);
    await _engine?.setupLocalVideo(
      VideoCanvas(
        view: view,
        uid: 0,
        renderMode: VideoRenderMode.VideoRenderFit,
        mirrorMode: mirror
            ? VideoMirrorModeType.videoMirrorModeEnabled
            : VideoMirrorModeType.videoMirrorModeDisabled,
      ),
    );
  }

  /// Exibe o video remoto de um usuario na tela.
  Future<void> setupRemoteVideo(int remoteUid, RtcSurfaceView view) async {
    await _engine?.setupRemoteVideo(
      VideoCanvas(
        view: view,
        uid: remoteUid,
        renderMode: VideoRenderMode.VideoRenderFit,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    await _engine?.stopPreview();
  }

  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
    _initialized = false;
  }

  /// Callbacks: onUserJoined, onUserOffline, onJoinChannelSuccess, onError.
  void listen({
    void Function(int uid)? onUserJoined,
    void Function(int uid)? onUserOffline,
    void Function()? onJoined,
    void Function(String message)? onError,
  }) {
    _engine?.setEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (channel, uid, elapsed) => onJoined?.call(),
        onUserJoined: (uid, elapsed) => onUserJoined?.call(uid),
        onUserOffline: (uid, reason) => onUserOffline?.call(uid),
        onError: (code, message) => onError?.call('$code: $message'),
      ),
    );
  }
}
