import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  static const int _notificationId = 41001;
  static const String _channelId = 'timea_pinned_goal';
  static const String _channelName = 'Meta anclada';
  static const String _channelDescription =
      'Muestra la meta anclada y su progreso actual';

  static const String _pinnedGoalIdKey = 'pinned_goal_id';

  static const String openActionId = 'timea_open_goal';
  static const String unpinActionId = 'timea_unpin_goal';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pinnedGoalId;
  String? _pendingOpenGoalId;

  String? get pinnedGoalId => _pinnedGoalId;

  String? consumePendingOpenGoalId() {
    final value = _pendingOpenGoalId;
    _pendingOpenGoalId = null;
    return value;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final prefs = await SharedPreferences.getInstance();
    _pinnedGoalId = prefs.getString(_pinnedGoalIdKey);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        await _processNotificationResponse(response);
      }
    }

    _initialized = true;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    unawaited(_processNotificationResponse(response));
  }

  Future<void> _processNotificationResponse(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    final goalId = response.payload;

    if (actionId == unpinActionId) {
      await cancelPinnedGoalNotification();
      return;
    }

    if (actionId == null || actionId == openActionId) {
      if (goalId != null && goalId.isNotEmpty) {
        _pendingOpenGoalId = goalId;
      }
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showPinnedGoalNotification({
    required String goalId,
    required String title,
    required String icon,
    required int todayMinutes,
    int? dailyTargetMinutes,
    required int dailyProgressPercent,
  }) async {
    await initialize();
    await _requestPermissionIfNeeded();

    final body = (dailyTargetMinutes != null && dailyTargetMinutes > 0)
        ? 'Hoy: $todayMinutes min • Meta: $dailyTargetMinutes min • Cumplimiento: $dailyProgressPercent%'
        : 'Hoy: $todayMinutes min';

    const actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        openActionId,
        'Abrir',
        showsUserInterface: true,
        cancelNotification: false,
      ),
      AndroidNotificationAction(
        unpinActionId,
        'Quitar',
        showsUserInterface: true,
        cancelNotification: false,
        semanticAction: SemanticAction.delete,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      silent: true,
      showWhen: false,
      channelShowBadge: false,
      actions: actions,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (defaultTargetPlatform == TargetPlatform.android &&
        androidPlugin != null) {
      await androidPlugin.startForegroundService(
        id: _notificationId,
        title: '$icon $title',
        body: body,
        notificationDetails: androidDetails,
        payload: goalId,
        startType: AndroidServiceStartType.startSticky,
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
        },
      );
    } else {
      await _plugin.show(
        id: _notificationId,
        title: '$icon $title',
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
        payload: goalId,
      );
    }

    _pinnedGoalId = goalId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinnedGoalIdKey, goalId);
  }

  Future<void> cancelPinnedGoalNotification() async {
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (defaultTargetPlatform == TargetPlatform.android &&
        androidPlugin != null) {
      await androidPlugin.stopForegroundService();
    }

    await _plugin.cancel(id: _notificationId);

    _pinnedGoalId = null;
    _pendingOpenGoalId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinnedGoalIdKey);
  }
}