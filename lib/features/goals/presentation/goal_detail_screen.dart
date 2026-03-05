import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/notifications/app_notification_service.dart';
import '../../journal/data/add_journal_entry_sheet.dart';
import '../../journal/data/edit_journal_entry_sheet.dart';
import '../../journal/data/journal_local_data_source.dart';
import '../../journal/domain/journal_entry.dart';
import '../../timer/data/timer_local_data_source.dart';
import '../../timer/domain/timer_session.dart';
import '../data/goals_local_data_source.dart';
import '../domain/goal.dart';
import 'edit_goal_sheet.dart';
import 'goal_detail_result.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  final Goal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final JournalLocalDataSource _journalDs = JournalLocalDataSource();
  final TimerLocalDataSource _timerDs = TimerLocalDataSource();
  final GoalsLocalDataSource _goalsDs = GoalsLocalDataSource();
  final AppNotificationService _notificationService =
      AppNotificationService.instance;

  List<JournalEntry> _entries = [];
  List<TimerSession> _sessions = [];

  bool _loading = true;
  String? _error;

  Timer? _ticker;
  bool _hasActiveTimer = false;
  bool _isTimerRunning = false;
  int _currentElapsedSeconds = 0;
  DateTime? _currentSessionStartedAt;

  late Goal _currentGoal;
  GoalDetailResult? _resultToReturn;

  Goal get _goal => _currentGoal;

  bool get _isPinnedInNotification {
    return _notificationService.pinnedGoalId == _goal.id;
  }

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;
    _loadData();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _journalDs.getEntriesByGoalId(_goal.id);
      final sessions = await _timerDs.getSessionsByGoalId(_goal.id);

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _sessions = sessions;
        _loading = false;
      });

      unawaited(_syncPinnedNotificationIfNeeded());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error cargando datos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pinCurrentGoalNotification() async {
    try {
      await _notificationService.showPinnedGoalNotification(
        goalId: _goal.id,
        title: _goal.title,
        icon: _goal.icon,
        todayMinutes: _todayTotalTrackedMinutes,
        dailyTargetMinutes: _goal.dailyTargetMinutes,
        dailyProgressPercent: _dailyProgressPercent,
      );

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta anclada en notificación.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo mostrar la notificación: $e')),
      );
    }
  }

  Future<void> _unpinCurrentGoalNotification() async {
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
        SnackBar(content: Text('No se pudo quitar la notificación: $e')),
      );
    }
  }

  Future<void> _syncPinnedNotificationIfNeeded() async {
    if (!_isPinnedInNotification) return;

    try {
      await _notificationService.showPinnedGoalNotification(
        goalId: _goal.id,
        title: _goal.title,
        icon: _goal.icon,
        todayMinutes: _todayTotalTrackedMinutes,
        dailyTargetMinutes: _goal.dailyTargetMinutes,
        dailyProgressPercent: _dailyProgressPercent,
      );
    } catch (_) {
      // MVP: si falla la actualización, no rompemos la pantalla.
    }
  }

  Future<void> _openAddEntrySheet() async {
    final entry = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddJournalEntrySheet(goal: _goal),
    );

    if (entry == null) return;

    try {
      await _journalDs.insertEntry(entry);
      if (!mounted) return;

      setState(() {
        _entries.insert(0, entry);
      });

      await _syncPinnedNotificationIfNeeded();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el registro: $e')),
      );
    }
  }

  Future<void> _openEditEntrySheet(JournalEntry entry) async {
    final updated = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditJournalEntrySheet(
        goal: _goal,
        entry: entry,
      ),
    );

    if (updated == null) return;

    try {
      await _journalDs.updateEntry(updated);
      if (!mounted) return;

      setState(() {
        _entries = _entries
            .map((e) => e.id == updated.id ? updated : e)
            .toList()
          ..sort((a, b) {
            final byDate = b.date.compareTo(a.date);
            if (byDate != 0) return byDate;
            return b.id.compareTo(a.id);
          });
      });

      await _syncPinnedNotificationIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el registro: $e')),
      );
    }
  }

  Future<void> _confirmDeleteEntry(JournalEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar registro'),
          content: const Text('¿Quieres eliminar este registro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _journalDs.deleteEntry(entry.id);
      if (!mounted) return;

      setState(() {
        _entries.removeWhere((e) => e.id == entry.id);
      });

      await _syncPinnedNotificationIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el registro: $e')),
      );
    }
  }

  Future<void> _confirmDeleteSession(TimerSession session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar sesión'),
          content: const Text('¿Quieres eliminar esta sesión de timer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _timerDs.deleteSession(session.id);
      if (!mounted) return;

      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
      });

      await _syncPinnedNotificationIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión eliminada.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la sesión: $e')),
      );
    }
  }

  Future<void> _openEditGoalSheet() async {
    final updated = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditGoalSheet(goal: _goal),
    );

    if (updated == null) return;

    try {
      await _goalsDs.updateGoal(updated);
      if (!mounted) return;

      setState(() {
        _currentGoal = updated;
        _resultToReturn = GoalDetailResult.updated(updated);
      });

      await _syncPinnedNotificationIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta actualizada.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    }
  }

  Future<void> _confirmDeleteGoal() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar meta'),
          content: const Text(
            'Se eliminará la meta y también sus registros y sesiones. ¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      if (_isPinnedInNotification) {
        await _notificationService.cancelPinnedGoalNotification();
      }

      await _goalsDs.deleteGoalCascade(_goal.id);
      if (!mounted) return;

      Navigator.of(context).pop(GoalDetailResult.deleted(_goal.id));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  void _startTimer() {
    if (_hasActiveTimer) return;

    setState(() {
      _hasActiveTimer = true;
      _isTimerRunning = true;
      _currentElapsedSeconds = 0;
      _currentSessionStartedAt = DateTime.now();
    });

    unawaited(_syncPinnedNotificationIfNeeded());

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTimerRunning) return;

      setState(() {
        _currentElapsedSeconds += 1;
      });
    });
  }

  void _pauseTimer() {
    if (!_hasActiveTimer || !_isTimerRunning) return;

    _ticker?.cancel();

    setState(() {
      _isTimerRunning = false;
    });

    unawaited(_syncPinnedNotificationIfNeeded());
  }

  void _resumeTimer() {
    if (!_hasActiveTimer || _isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
    });

    unawaited(_syncPinnedNotificationIfNeeded());

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTimerRunning) return;

      setState(() {
        _currentElapsedSeconds += 1;
      });
    });
  }

  Future<void> _stopAndSaveTimer() async {
    if (!_hasActiveTimer || _currentSessionStartedAt == null) return;

    _ticker?.cancel();

    final endedAt = DateTime.now();
    final session = TimerSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      goalId: _goal.id,
      startedAt: _currentSessionStartedAt!,
      endedAt: endedAt,
      effectiveSeconds: _currentElapsedSeconds,
    );

    try {
      await _timerDs.insertSession(session);
      if (!mounted) return;

      setState(() {
        _sessions.insert(0, session);
        _hasActiveTimer = false;
        _isTimerRunning = false;
        _currentElapsedSeconds = 0;
        _currentSessionStartedAt = null;
      });

      await _syncPinnedNotificationIfNeeded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión guardada.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la sesión: $e')),
      );
    }
  }

  int get _totalJournalMinutes {
    return _entries.fold(0, (sum, entry) => sum + (entry.minutesSpent ?? 0));
  }

  double get _totalMoney {
    return _entries.fold(0, (sum, entry) => sum + (entry.moneySpent ?? 0));
  }

  int get _totalTimerSeconds {
    return _sessions.fold(0, (sum, session) => sum + session.effectiveSeconds);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get _todayJournalSeconds {
    final now = DateTime.now();

    return _entries
        .where((entry) => _isSameDay(entry.date, now))
        .fold(0, (sum, entry) => sum + ((entry.minutesSpent ?? 0) * 60));
  }

  int get _todaySavedTimerSeconds {
    final now = DateTime.now();

    return _sessions
        .where((session) => _isSameDay(session.startedAt, now))
        .fold(0, (sum, session) => sum + session.effectiveSeconds);
  }

  int get _todayTotalTrackedSeconds {
    return _todayJournalSeconds +
        _todaySavedTimerSeconds +
        (_hasActiveTimer ? _currentElapsedSeconds : 0);
  }

  int get _todayTotalTrackedMinutes {
    return (_todayTotalTrackedSeconds / 60).floor();
  }

  double get _dailyProgressFraction {
    final targetMinutes = _goal.dailyTargetMinutes;
    if (!_goal.trackTime || targetMinutes == null || targetMinutes <= 0) {
      return 0;
    }

    final targetSeconds = targetMinutes * 60;
    final fraction = _todayTotalTrackedSeconds / targetSeconds;

    if (fraction < 0) return 0;
    if (fraction > 1) return 1;

    return fraction;
  }

  int get _dailyProgressPercent {
    return (_dailyProgressFraction * 100).round();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$datePart $hour:$minute';
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final trackedResources = <String>[
      if (_goal.trackTime) 'Tiempo',
      if (_goal.trackMoney) 'Dinero',
    ];

    return WillPopScope(
      onWillPop: () async {
        final res = _resultToReturn;
        if (res != null) {
          Navigator.of(context).pop(res);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de meta'),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'pin') _pinCurrentGoalNotification();
                if (value == 'unpin') _unpinCurrentGoalNotification();
                if (value == 'edit') _openEditGoalSheet();
                if (value == 'delete') _confirmDeleteGoal();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _isPinnedInNotification ? 'unpin' : 'pin',
                  child: Text(
                    _isPinnedInNotification
                        ? 'Quitar notificación'
                        : 'Anclar notificación',
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddEntrySheet,
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Registro'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                _goal.icon,
                                style: const TextStyle(fontSize: 36),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _goal.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Resumen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Fecha de inicio',
                                value: _formatDate(_goal.startDate),
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.hourglass_bottom,
                                label: 'Días invertidos',
                                value: '${_goal.daysSinceStart}',
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.analytics_outlined,
                                label: 'Recursos medidos',
                                value: trackedResources.isEmpty
                                    ? 'Ninguno'
                                    : trackedResources.join(' • '),
                              ),
                              if (_goal.trackTime &&
                                  _goal.dailyTargetMinutes != null) ...[
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.flag_outlined,
                                  label: 'Meta diaria',
                                  value: '${_goal.dailyTargetMinutes} min',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_goal.trackTime &&
                          _goal.dailyTargetMinutes != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Cumplimiento diario',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoy llevas $_todayTotalTrackedMinutes min de ${_goal.dailyTargetMinutes} min',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: _dailyProgressFraction,
                                  minHeight: 12,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Cumplimiento: $_dailyProgressPercent%',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Balance actual',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _StatTile(
                                title: 'Tiempo en registros',
                                value: _goal.trackTime
                                    ? '$_totalJournalMinutes min'
                                    : 'No medido',
                              ),
                              const SizedBox(height: 12),
                              _StatTile(
                                title: 'Tiempo en timer',
                                value: _goal.trackTime
                                    ? _formatDuration(_totalTimerSeconds)
                                    : 'No medido',
                              ),
                              const SizedBox(height: 12),
                              _StatTile(
                                title: 'Dinero registrado',
                                value: _goal.trackMoney
                                    ? '\$${_totalMoney.toStringAsFixed(2)}'
                                    : 'No medido',
                              ),
                              const SizedBox(height: 12),
                              _StatTile(
                                title: 'Entradas de diario',
                                value: '${_entries.length}',
                              ),
                              const SizedBox(height: 12),
                              _StatTile(
                                title: 'Sesiones timer',
                                value: '${_sessions.length}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_goal.trackTime) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Timer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  _formatDuration(_currentElapsedSeconds),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!_hasActiveTimer)
                                      FilledButton.icon(
                                        onPressed: _startTimer,
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Iniciar'),
                                      ),
                                    if (_hasActiveTimer && _isTimerRunning)
                                      OutlinedButton.icon(
                                        onPressed: _pauseTimer,
                                        icon: const Icon(Icons.pause),
                                        label: const Text('Pausar'),
                                      ),
                                    if (_hasActiveTimer && !_isTimerRunning)
                                      OutlinedButton.icon(
                                        onPressed: _resumeTimer,
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Reanudar'),
                                      ),
                                    if (_hasActiveTimer)
                                      FilledButton.icon(
                                        onPressed: _stopAndSaveTimer,
                                        icon: const Icon(Icons.stop),
                                        label: const Text('Detener y guardar'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sesiones guardadas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (_sessions.isEmpty)
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Todavía no hay sesiones de timer guardadas.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          )
                        else
                          ..._sessions.map(
                            (session) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TimerSessionCard(
                                session: session,
                                formatDateTime: _formatDateTime,
                                formatDuration: _formatDuration,
                                onDelete: () => _confirmDeleteSession(session),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Registros',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_entries.isEmpty)
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Todavía no hay registros para esta meta.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openAddEntrySheet,
                                    icon: const Icon(Icons.note_add_outlined),
                                    label:
                                        const Text('Agregar primer registro'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _JournalEntryCard(
                              entry: entry,
                              onEdit: () => _openEditEntrySheet(entry),
                              onDelete: () => _confirmDeleteEntry(entry),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _TimerSessionCard extends StatelessWidget {
  const _TimerSessionCard({
    required this.session,
    required this.formatDateTime,
    required this.formatDuration,
    required this.onDelete,
  });

  final TimerSession session;
  final String Function(DateTime) formatDateTime;
  final String Function(int) formatDuration;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDuration(session.effectiveSeconds),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicio: ${formatDateTime(session.startedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fin: ${formatDateTime(session.endedAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = <String>[
      if (entry.minutesSpent != null) '${entry.minutesSpent} min',
      if (entry.moneySpent != null)
        '\$${entry.moneySpent!.toStringAsFixed(2)}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(entry.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (metrics.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      metrics.join(' • '),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    entry.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}