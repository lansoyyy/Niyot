import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_navigator.dart';
import '../models/notification_model.dart';
import '../screens/notifications/notifications_screen.dart';
import '../widgets/navigation/notification_navigation_helper.dart';

/// Shows system tray banners from Firestore notification events
/// while the app process is alive (foreground + background).
class LocalNotificationHelper {
  LocalNotificationHelper._();

  static final LocalNotificationHelper instance = LocalNotificationHelper._();

  static const _channelId = 'niyot_alerts';
  static const _channelName = 'Niyot Alerts';
  static const _channelDesc = 'Booking, message, and offer alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }

    return true;
  }

  Future<void> showFromModel(NotificationModel notification) async {
    if (!_initialized || kIsWeb) return;

    final id = notification.id.hashCode & 0x7fffffff;
    final payload = jsonEncode({
      'id': notification.id,
      'type': notification.type.value,
      'relatedId': notification.relatedId,
      'userId': notification.userId,
    });

    await _plugin.show(
      id: id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(notification.body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Day-before shoot reminder (local scheduled — works even if app is closed).
  Future<void> scheduleShootReminder({
    required String bookingId,
    required String otherPartyName,
    required DateTime sessionStart,
  }) async {
    if (!_initialized || kIsWeb) return;

    final reminderAt = DateTime(
      sessionStart.year,
      sessionStart.month,
      sessionStart.day,
    ).subtract(const Duration(days: 1)).add(const Duration(hours: 9));

    if (!reminderAt.isAfter(DateTime.now())) return;

    final id = 'shoot_$bookingId'.hashCode & 0x7fffffff;
    final when = tz.TZDateTime.from(reminderAt, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      title: 'Shoot tomorrow',
      body: 'Reminder: your session with $otherPartyName is tomorrow.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'shoot_reminder',
        'relatedId': bookingId,
      }),
    );
  }

  Future<void> cancelShootReminder(String bookingId) async {
    if (!_initialized || kIsWeb) return;
    final id = 'shoot_$bookingId'.hashCode & 0x7fffffff;
    await _plugin.cancel(id: id);
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _openNotificationsList();
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      final relatedId = data['relatedId'] as String?;
      final id = data['id'] as String? ?? '';
      final userId = data['userId'] as String? ?? '';

      final model = NotificationModel(
        id: id,
        userId: userId,
        title: '',
        body: '',
        type: NotificationTypeX.fromValue(type),
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final ctx = AppNavigator.context;
      if (ctx == null) return;

      if (type == 'shoot_reminder' && relatedId != null) {
        NotificationNavigationHelper.openFromNotification(
          ctx,
          NotificationModel(
            id: id,
            userId: userId,
            title: '',
            body: '',
            type: NotificationType.bookingConfirmed,
            relatedId: relatedId,
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
        return;
      }

      NotificationNavigationHelper.openFromNotification(ctx, model);
    } catch (_) {
      _openNotificationsList();
    }
  }

  void _openNotificationsList() {
    final ctx = AppNavigator.context;
    if (ctx == null) return;
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
