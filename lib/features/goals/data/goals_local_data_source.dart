import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_db.dart';
import '../domain/goal.dart';

class GoalsLocalDataSource {
  GoalsLocalDataSource({AppDb? db}) : _db = db ?? AppDb.instance;

  final AppDb _db;

  Future<List<Goal>> getAllGoals() async {
    final Database database = await _db.database;

    final rows = await database.query(
      'goals',
      orderBy: 'id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> insertGoal(Goal goal) async {
    final Database database = await _db.database;

    await database.insert(
      'goals',
      _toRow(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGoal(Goal goal) async {
    final Database database = await _db.database;

    await database.update(
      'goals',
      _toRow(goal),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoalCascade(String goalId) async {
    final Database database = await _db.database;

    await database.transaction((txn) async {
      await txn.delete(
        'journal_entries',
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );

      await txn.delete(
        'timer_sessions',
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );

      await txn.delete(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );
    });
  }

  Map<String, Object?> _toRow(Goal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'icon': goal.icon,
      'start_date_ms': goal.startDate.millisecondsSinceEpoch,
      'track_time': goal.trackTime ? 1 : 0,
      'track_money': goal.trackMoney ? 1 : 0,
      'daily_target_minutes': goal.dailyTargetMinutes,
    };
  }

  Goal _fromRow(Map<String, Object?> row) {
    return Goal(
      id: row['id'] as String,
      title: row['title'] as String,
      icon: row['icon'] as String,
      startDate:
          DateTime.fromMillisecondsSinceEpoch(row['start_date_ms'] as int),
      trackTime: (row['track_time'] as int) == 1,
      trackMoney: (row['track_money'] as int) == 1,
      dailyTargetMinutes: row['daily_target_minutes'] as int?,
    );
  }
}