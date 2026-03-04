import 'package:flutter/material.dart';

import '../../goals/data/goals_local_data_source.dart';
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
  final GoalsLocalDataSource _goalsDs = GoalsLocalDataSource();

  List<Goal> _goals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGoals();
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error cargando metas: $e';
        _loading = false;
      });
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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la meta: $e')),
      );
    }
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
            const SizedBox(height: 16),
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
                                    const Text('⏳', style: TextStyle(fontSize: 28)),
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