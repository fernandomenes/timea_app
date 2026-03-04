import 'dart:async';

import 'package:flutter/material.dart';

import '../../journal/data/journal_local_data_source.dart';
import '../../journal/domain/journal_entry.dart';
import '../../journal/data/add_journal_entry_sheet.dart';
import '../../timer/data/timer_local_data_source.dart';
import '../../timer/domain/timer_session.dart';
import '../domain/goal.dart';

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

  List<JournalEntry> _entries = [];
  List<TimerSession> _sessions = [];

  bool _loading = true;
  String? _error;

  Timer? _ticker;
  bool _hasActiveTimer = false;
  bool _isTimerRunning = false;
  int _currentElapsedSeconds = 0;
  DateTime? _currentSessionStartedAt;

  Goal get _goal => widget.goal;

  @override
  void initState() {
    super.initState();
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error cargando datos: $e';
        _loading = false;
      });
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el registro: $e')),
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
  }

  void _resumeTimer() {
    if (!_hasActiveTimer || _isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
    });

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de meta'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
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
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
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
                                style: Theme.of(context).textTheme.titleMedium,
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
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
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
                                  label: const Text('Agregar primer registro'),
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
                          child: _JournalEntryCard(entry: entry),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _TimerSessionCard extends StatelessWidget {
  const _TimerSessionCard({
    required this.session,
    required this.formatDateTime,
    required this.formatDuration,
  });

  final TimerSession session;
  final String Function(DateTime) formatDateTime;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
  });

  final JournalEntry entry;

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
      if (entry.moneySpent != null) '\$${entry.moneySpent!.toStringAsFixed(2)}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
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