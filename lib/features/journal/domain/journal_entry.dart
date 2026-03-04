class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.goalId,
    required this.date,
    required this.text,
    this.minutesSpent,
    this.moneySpent,
  });

  final String id;
  final String goalId;
  final DateTime date;
  final String text;
  final int? minutesSpent;
  final double? moneySpent;
}