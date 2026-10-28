import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'hms_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  StreamSubscription<String>? _refresh;
  String? _token;
  Future<void> enable() async {
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('Notifications are disabled in device/browser settings.');
    }
    const vapidKey = String.fromEnvironment('FCM_VAPID_KEY');
    if (kIsWeb && vapidKey.isEmpty) {
      throw Exception('Configure FCM_VAPID_KEY when building the web app.');
    }
    final token = await messaging.getToken(vapidKey: kIsWeb ? vapidKey : null);
    if (token == null) {
      throw Exception('Push token is not available yet. Try again shortly.');
    }
    await _register(token);
    await _refresh?.cancel();
    _refresh = messaging.onTokenRefresh.listen((token) async {
      try {
        await _register(token);
      } catch (e) {
        debugPrint('Push registration failed: $e');
      }
    });
  }

  Future<void> _register(String token) async {
    if (_token != null && _token != token) {
      await HmsService().call('registerDevice', {
        'token': _token,
        'remove': true,
      });
    }
    await HmsService().call('registerDevice', {'token': token});
    _token = token;
  }

  Future<void> disable() async {
    await _refresh?.cancel();
    _refresh = null;
    try {
      if (_token != null) {
        await HmsService().call('registerDevice', {
          'token': _token,
          'remove': true,
        });
      }
    } catch (e) {
      debugPrint('Push cleanup failed: $e');
    }
    // Invalidate this installation even if the server-side unsubscribe failed.
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push token deletion failed: $e');
    }
    _token = null;
  }

  void dispose() {
    _refresh?.cancel();
  }
}
