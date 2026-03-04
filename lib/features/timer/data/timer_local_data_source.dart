import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_db.dart';
import '../domain/timer_session.dart';

class TimerLocalDataSource {
  TimerLocalDataSource({AppDb? db}) : _db = db ?? AppDb.instance;

  final AppDb _db;

  Future<List<TimerSession>> getSessionsByGoalId(String goalId) async {
    final Database database = await _db.database;

    final rows = await database.query(
      'timer_sessions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'started_at_ms DESC, id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> insertSession(TimerSession session) async {
    final Database database = await _db.database;

    await database.insert(
      'timer_sessions',
      _toRow(session),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSession(String id) async {
    final Database database = await _db.database;

    await database.delete(
      'timer_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toRow(TimerSession session) {
    return {
      'id': session.id,
      'goal_id': session.goalId,
      'started_at_ms': session.startedAt.millisecondsSinceEpoch,
      'ended_at_ms': session.endedAt.millisecondsSinceEpoch,
      'effective_seconds': session.effectiveSeconds,
    };
  }

  TimerSession _fromRow(Map<String, Object?> row) {
    return TimerSession(
      id: row['id'] as String,
      goalId: row['goal_id'] as String,
      startedAt:
          DateTime.fromMillisecondsSinceEpoch(row['started_at_ms'] as int),
      endedAt: DateTime.fromMillisecondsSinceEpoch(row['ended_at_ms'] as int),
      effectiveSeconds: row['effective_seconds'] as int,
    );
  }
}