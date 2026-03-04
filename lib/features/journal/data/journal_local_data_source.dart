import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_db.dart';
import '../domain/journal_entry.dart';

class JournalLocalDataSource {
  JournalLocalDataSource({AppDb? db}) : _db = db ?? AppDb.instance;

  final AppDb _db;

  Future<List<JournalEntry>> getEntriesByGoalId(String goalId) async {
    final Database database = await _db.database;

    final rows = await database.query(
      'journal_entries',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'entry_date_ms DESC, id DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> insertEntry(JournalEntry entry) async {
    final Database database = await _db.database;

    await database.insert(
      'journal_entries',
      _toRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, Object?> _toRow(JournalEntry entry) {
    return {
      'id': entry.id,
      'goal_id': entry.goalId,
      'entry_date_ms': entry.date.millisecondsSinceEpoch,
      'text': entry.text,
      'minutes_spent': entry.minutesSpent,
      'money_spent': entry.moneySpent,
    };
  }

  JournalEntry _fromRow(Map<String, Object?> row) {
    return JournalEntry(
      id: row['id'] as String,
      goalId: row['goal_id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['entry_date_ms'] as int),
      text: row['text'] as String,
      minutesSpent: row['minutes_spent'] as int?,
      moneySpent: row['money_spent'] as double?,
    );
  }
}