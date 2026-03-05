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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pinnedGoalId;

  String? get pinnedGoalId => _pinnedGoalId;

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: initializationSettings,
    );

    final prefs = await SharedPreferences.getInstance();
    _pinnedGoalId = prefs.getString(_pinnedGoalIdKey);

    _initialized = true;
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

    const androidDetails = AndroidNotificationDetails(
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
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      id: _notificationId,
      title: '$icon $title',
      body: body,
      notificationDetails: notificationDetails,
      payload: goalId,
    );

    _pinnedGoalId = goalId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinnedGoalIdKey, goalId);
  }

  Future<void> cancelPinnedGoalNotification() async {
    await initialize();
    await _plugin.cancel(id: _notificationId);

    _pinnedGoalId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinnedGoalIdKey);
  }
}