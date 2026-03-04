import 'package:flutter/material.dart';

import '../../goals/domain/goal.dart';
import '../../goals/presentation/create_goal_sheet.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/widgets/goal_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Goal> _goals = [];

  Future<void> _openCreateGoalSheet() async {
    final goal = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateGoalSheet(),
    );

    if (goal == null) return;

    setState(() {
      _goals.insert(0, goal);
    });
  }

  void _openGoalDetail(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GoalDetailScreen(goal: goal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGoals = _goals.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timea'),
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
            const SizedBox(height: 16),
            Expanded(
              child: hasGoals
                  ? ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];

                        return GoalCard(
                          goal: goal,
                          onTap: () => _openGoalDetail(goal),
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
                                style: Theme.of(context).textTheme.titleMedium,
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