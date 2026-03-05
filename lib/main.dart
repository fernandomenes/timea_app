import 'package:flutter/widgets.dart';

import 'app/timea_app.dart';
import 'core/notifications/app_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotificationService.instance.initialize();

  runApp(const TimeaApp());
}