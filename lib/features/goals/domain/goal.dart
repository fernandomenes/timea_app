class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.icon,
    required this.startDate,
    required this.trackTime,
    required this.trackMoney,
    this.dailyTargetMinutes,
  });

  final String id;
  final String title;
  final String icon;
  final DateTime startDate;
  final bool trackTime;
  final bool trackMoney;
  final int? dailyTargetMinutes;

  int get daysSinceStart {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    return today.difference(start).inDays + 1;
  }
}