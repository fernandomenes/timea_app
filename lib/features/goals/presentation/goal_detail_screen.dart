import 'package:flutter/material.dart';

import '../../journal/data/journal_local_data_source.dart';
import '../../journal/domain/journal_entry.dart';
import '../../journal/data/add_journal_entry_sheet.dart';
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

  List<JournalEntry> _entries = [];
  bool _loading = true;
  String? _error;

  Goal get _goal => widget.goal;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _journalDs.getEntriesByGoalId(_goal.id);
      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error cargando registros: $e';
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

  int get _totalMinutes {
    return _entries.fold(0, (sum, entry) => sum + (entry.minutesSpent ?? 0));
  }

  double get _totalMoney {
    return _entries.fold(0, (sum, entry) => sum + (entry.moneySpent ?? 0));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
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
            onPressed: _loadEntries,
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
                          ],
                        ),
                      ),
                    ),
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
                              title: 'Tiempo registrado',
                              value: _goal.trackTime
                                  ? '$_totalMinutes min'
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
                          ],
                        ),
                      ),
                    ),
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