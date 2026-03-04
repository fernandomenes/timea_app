import 'package:flutter/material.dart';

import '../../domain/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final Goal goal;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (goal.trackTime) 'Tiempo',
      if (goal.trackMoney) 'Dinero',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    goal.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${goal.daysSinceStart} día(s)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Inicio: ${_formatDate(goal.startDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: labels
                      .map(
                        (label) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(label: Text(label)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}