import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';

/// Lives com o Agora RTC (agora_rtc_engine 6.6.x).
///
/// ANTES DE USAR:
///  - Cole o seu App ID em AppConfig.agoraAppId (lib/config.dart)
///  - Permissoes de camera/microfone ja estao no AndroidManifest
class LiveService {
  RtcEngine? _engine;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Engine usado para montar as views de video (AgoraVideoView).
  RtcEngine? get engine => _engine;

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  /// Inicializa o engine do Agora.
  /// Sem App ID configurado, retorna false (modo demonstracao).
  Future<bool> init({required int uid}) async {
    if (_initialized) return true;
    if (AppConfig.agoraAppId.isEmpty ||
        AppConfig.agoraAppId == 'SEU_AGORA_APP_ID') {
      return false;
    }
    await _requestPermissions();

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: AppConfig.agoraAppId));
    await engine.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting);
    await engine.enableVideo();
    await engine.enableAudio();

    _engine = engine;
    _initialized = true;
    return true;
  }

  Future<void> startHost(String channel) async {
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
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
    await _engine?.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine?.joinChannel(
      token: '',
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  /// View local (host) para o AgoraVideoView.
  AgoraVideoView buildLocalVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  /// View remota (audiencia) para o AgoraVideoView.
  AgoraVideoView buildRemoteVideoView(int remoteUid, String channel) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: channel),
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
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) => onJoined?.call(),
        onUserJoined: (connection, remoteUid, elapsed) =>
            onUserJoined?.call(remoteUid),
        onUserOffline: (connection, remoteUid, reason) =>
            onUserOffline?.call(remoteUid),
        onError: (err, msg) => onError?.call('$err: $msg'),
      ),
    );
  }
}
