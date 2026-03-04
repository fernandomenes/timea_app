class TimerSession {
  const TimerSession({
    required this.id,
    required this.goalId,
    required this.startedAt,
    required this.endedAt,
    required this.effectiveSeconds,
  });

  final String id;
  final String goalId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int effectiveSeconds;
}