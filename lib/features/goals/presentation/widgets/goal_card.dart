import 'package:flutter/material.dart';

import '../../domain/goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.isPinned,
    required this.onPin,
    required this.onUnpin,
  });

  final Goal goal;
  final VoidCallback onTap;
  final bool isPinned;
  final VoidCallback onPin;
  final VoidCallback onUnpin;

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
      if (goal.trackTime && goal.dailyTargetMinutes != null)
        'Meta diaria: ${goal.dailyTargetMinutes} min',
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
                  Text(goal.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPinned) ...[
                    const Icon(Icons.push_pin, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '${goal.daysSinceStart} día(s)',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pin') onPin();
                      if (value == 'unpin') onUnpin();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: isPinned ? 'unpin' : 'pin',
                        child: Text(isPinned ? 'Quitar notificación' : 'Anclar notificación'),
                      ),
                    ],
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: labels.map((label) => Chip(label: Text(label))).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}