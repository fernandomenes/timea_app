import 'package:flutter/material.dart';

import '../../../core/notifications/app_notification_service.dart';
import '../../goals/data/goals_local_data_source.dart';
import '../../goals/domain/goal.dart';
import '../../goals/presentation/create_goal_sheet.dart';
import '../../goals/presentation/goal_detail_result.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/widgets/goal_card.dart';
import '../../journal/data/journal_local_data_source.dart';
import '../../timer/data/timer_local_data_source.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GoalsLocalDataSource _goalsDs = GoalsLocalDataSource();
  final JournalLocalDataSource _journalDs = JournalLocalDataSource();
  final TimerLocalDataSource _timerDs = TimerLocalDataSource();
  final AppNotificationService _notificationService =
      AppNotificationService.instance;

  List<Goal> _goals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGoals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;

      setState(() {});

      _syncPinnedNotificationFromHome();
      _handlePendingNotificationNavigation();
    }
  }

  Future<void> _loadGoals() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final goals = await _goalsDs.getAllGoals();
      if (!mounted) return;

      setState(() {
        _goals = goals;
        _loading = false;
      });

      await _syncPinnedNotificationFromHome();
      _handlePendingNotificationNavigation();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error cargando metas: $e';
        _loading = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<({int todayMinutes, int dailyPercent})> _computeTodayStats(
    Goal goal,
  ) async {
    final entries = await _journalDs.getEntriesByGoalId(goal.id);
    final sessions = await _timerDs.getSessionsByGoalId(goal.id);

    final now = DateTime.now();

    final todayJournalSeconds = entries
        .where((e) => _isSameDay(e.date, now))
        .fold<int>(0, (sum, e) => sum + ((e.minutesSpent ?? 0) * 60));

    final todayTimerSeconds = sessions
        .where((s) => _isSameDay(s.startedAt, now))
        .fold<int>(0, (sum, s) => sum + s.effectiveSeconds);

    final totalSeconds = todayJournalSeconds + todayTimerSeconds;
    final todayMinutes = (totalSeconds / 60).floor();

    int percent = 0;
    final target = goal.dailyTargetMinutes;
    if (goal.trackTime && target != null && target > 0) {
      final fraction = totalSeconds / (target * 60);
      final clamped = fraction.clamp(0, 1);
      percent = (clamped * 100).round();
    }

    return (todayMinutes: todayMinutes, dailyPercent: percent);
  }

  Future<void> _syncPinnedNotificationFromHome() async {
    final pinnedId = _notificationService.pinnedGoalId;
    if (pinnedId == null) return;

    Goal? goal;
    for (final item in _goals) {
      if (item.id == pinnedId) {
        goal = item;
        break;
      }
    }

    if (goal == null) {
      await _notificationService.cancelPinnedGoalNotification();
      if (!mounted) return;
      setState(() {});
      return;
    }

    try {
      final stats = await _computeTodayStats(goal);
      await _notificationService.showPinnedGoalNotification(
        goalId: goal.id,
        title: goal.title,
        icon: goal.icon,
        todayMinutes: stats.todayMinutes,
        dailyTargetMinutes: goal.dailyTargetMinutes,
        dailyProgressPercent: stats.dailyPercent,
      );

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // MVP
    }
  }

  void _handlePendingNotificationNavigation() {
    final goalId = _notificationService.consumePendingOpenGoalId();
    if (goalId == null) return;

    Goal? goal;
    for (final item in _goals) {
      if (item.id == goalId) {
        goal = item;
        break;
      }
    }

    if (goal == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openGoalDetail(goal!);
    });
  }

  Future<void> _pinGoalFromHome(Goal goal) async {
    try {
      final stats = await _computeTodayStats(goal);

      await _notificationService.showPinnedGoalNotification(
        goalId: goal.id,
        title: goal.title,
        icon: goal.icon,
        todayMinutes: stats.todayMinutes,
        dailyTargetMinutes: goal.dailyTargetMinutes,
        dailyProgressPercent: stats.dailyPercent,
      );

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meta anclada: ${goal.title}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo anclar: $e')),
      );
    }
  }

  Future<void> _unpinFromHome() async {
    try {
      await _notificationService.cancelPinnedGoalNotification();

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación retirada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar: $e')),
      );
    }
  }

  Future<void> _openCreateGoalSheet() async {
    final goal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateGoalSheet(),
    );

    if (goal == null) return;

    try {
      await _goalsDs.insertGoal(goal);
      if (!mounted) return;

      setState(() {
        _goals.insert(0, goal);
      });

      await _syncPinnedNotificationFromHome();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la meta: $e')),
      );
    }
  }

  Future<void> _openGoalDetail(Goal goal) async {
    final result = await Navigator.of(context).push<GoalDetailResult>(
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(goal: goal),
      ),
    );

    if (result == null) {
      await _syncPinnedNotificationFromHome();
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (result.deletedGoalId != null) {
      setState(() {
        _goals.removeWhere((g) => g.id == result.deletedGoalId);
      });

      await _syncPinnedNotificationFromHome();
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (result.goal != null) {
      final updated = result.goal!;
      setState(() {
        _goals = _goals.map((g) => g.id == updated.id ? updated : g).toList();
      });

      await _syncPinnedNotificationFromHome();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasGoals = _goals.isNotEmpty;
    final pinnedId = _notificationService.pinnedGoalId;

    Goal? pinnedGoal;
    if (pinnedId != null) {
      for (final goal in _goals) {
        if (goal.id == pinnedId) {
          pinnedGoal = goal;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timea'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadGoals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGoalSheet,
        icon: const Icon(Icons.add),
        label: const Text('Meta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metas activas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza creando tu primera meta y haz visible el tiempo que inviertes.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            if (pinnedGoal != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Meta anclada: ${pinnedGoal.icon} ${pinnedGoal.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openGoalDetail(pinnedGoal!),
                        child: const Text('Ver'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _unpinFromHome,
                        child: const Text('Quitar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                      ? Center(
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : hasGoals
                          ? ListView.separated(
                              itemCount: _goals.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final goal = _goals[index];
                                final isPinned =
                                    _notificationService.pinnedGoalId == goal.id;

                                return GoalCard(
                                  goal: goal,
                                  onTap: () => _openGoalDetail(goal),
                                  isPinned: isPinned,
                                  onPin: () => _pinGoalFromHome(goal),
                                  onUnpin: _unpinFromHome,
                                );
                              },
                            )
                          : Card(
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Text(
                                      '⏳',
                                      style: TextStyle(fontSize: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Todavía no hay metas. Usa el botón "Meta" para crear la primera.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}