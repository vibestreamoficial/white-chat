import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificacoes push com Firebase Cloud Messaging (FCM).
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Inicializa notificacoes locais + FCM (iOS pede permissao).
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      // salve o token no perfil do usuario para o backend enviar push
      // ex.: FirebaseFirestore.instance.collection('profiles')
      //        .doc(uid).update({'fcmToken': token});
    }

    // Mostra notificacao local quando o app esta aberto
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n == null) return;
      _showLocal(n.title ?? 'WHITE CHAT', n.body ?? '');
    });
  }

  Future<void> _showLocal(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'social',
      'Atividade social',
      channelDescription: 'Curtidas, comentarios, seguidores e mensagens',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _local.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }
}
