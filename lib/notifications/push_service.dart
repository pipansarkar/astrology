import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/supabase_config.dart';

// Firebase settings come from app_config.json (see app_config.example.json),
// so no google-services.json or Gradle plugin is needed.
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');

bool get firebaseConfigured =>
    _projectId.isNotEmpty &&
    _apiKey.isNotEmpty &&
    _appId.isNotEmpty &&
    _senderId.isNotEmpty;

/// What a notification tap should open.
enum PushTarget { myQuestions, astrologerDesk, horoscope }

/// Firebase Cloud Messaging: device registration, the daily horoscope
/// topic, and notification taps. Sending happens server-side
/// (supabase/functions/push).
class PushService {
  PushService._();

  static const dailyTopic = 'daily-horoscope';
  static const _dailyPrefKey = 'daily_reminder';

  static bool _ready = false;
  static bool get isAvailable => _ready;

  static StreamSubscription<String>? _refreshSub;

  /// Called by the app when a notification is tapped.
  static void Function(PushTarget target)? onOpen;

  /// Called for notifications that arrive while the app is open.
  static void Function(String title, String body)? onForeground;

  static Future<void> init() async {
    if (!firebaseConfigured || !backendEnabled) return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _apiKey,
          appId: _appId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Firebase init failed: $e');
      return;
    }

    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n != null) onForeground?.call(n.title ?? '', n.body ?? '');
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Let the first frame build before navigating.
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleOpen(initial));
    }
  }

  static void _handleOpen(RemoteMessage m) {
    final target = switch (m.data['type']) {
      'question_answered' => PushTarget.myQuestions,
      'question_open' => PushTarget.astrologerDesk,
      _ => PushTarget.horoscope,
    };
    onOpen?.call(target);
  }

  /// Asks for permission (Android 13+ shows a dialog) and registers this
  /// device for the signed-in account. Returns false if the user refuses.
  static Future<bool> enable() async {
    if (!_ready) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    await _register();
    return true;
  }

  /// Re-registers silently if permission was already granted, e.g. after
  /// switching accounts. Never shows a dialog.
  static Future<void> sync() async {
    if (!_ready || currentUser == null) return;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _register();
      }
    } catch (e) {
      debugPrint('Push sync failed: $e');
    }
  }

  // Uses classic FCM registration tokens, which the HTTP v1 send API in
  // supabase/functions/push accepts. firebase_messaging 17 deprecates them
  // in favour of installation IDs (register/onRegistered); migrate both
  // sides together when that path is verified.
  // ignore_for_file: deprecated_member_use
  static Future<void> _register() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await requireSession();
    await supabase.rpc('register_device', params: {'p_token': token});
    _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (t) => supabase
          .rpc('register_device', params: {'p_token': t})
          .catchError((_) => null),
    );
  }

  // ------------------------------------------------------- daily reminder

  static Future<bool> dailyReminderOn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dailyPrefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the resulting state (false if permission was refused).
  static Future<bool> setDailyReminder(bool on) async {
    if (!_ready) return false;
    if (on && !await enable()) return false;
    final m = FirebaseMessaging.instance;
    if (on) {
      await m.subscribeToTopic(dailyTopic);
    } else {
      await m.unsubscribeFromTopic(dailyTopic);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dailyPrefKey, on);
    } catch (_) {}
    return on;
  }
}
