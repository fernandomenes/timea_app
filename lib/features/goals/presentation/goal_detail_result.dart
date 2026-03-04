import '../domain/goal.dart';

class GoalDetailResult {
  const GoalDetailResult.updated(this.goal) : deletedGoalId = null;
  const GoalDetailResult.deleted(this.deletedGoalId) : goal = null;

  final Goal? goal;
  final String? deletedGoalId;
}