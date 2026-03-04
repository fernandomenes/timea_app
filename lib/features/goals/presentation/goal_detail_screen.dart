import 'package:flutter/material.dart';

import '../domain/goal.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  final Goal goal;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final trackedResources = <String>[
      if (goal.trackTime) 'Tiempo',
      if (goal.trackMoney) 'Dinero',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de meta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    goal.icon,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.headlineSmall,
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
                    value: _formatDate(goal.startDate),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.hourglass_bottom,
                    label: 'Días invertidos',
                    value: '${goal.daysSinceStart}',
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
                    value: goal.trackTime ? '0 min' : 'No medido',
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    title: 'Dinero registrado',
                    value: goal.trackMoney ? '\$0.00' : 'No medido',
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    title: 'Entradas de diario',
                    value: '0',
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Los registros diarios se implementarán en el siguiente bloque.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('Agregar registro (próximamente)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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