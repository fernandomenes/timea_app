import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();

  static final AppDb instance = AppDb._();
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'timea.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await _createGoalsTable(db);
        await _createJournalEntriesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createJournalEntriesTable(db);
        }
      },
    );
  }

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        icon TEXT NOT NULL,
        start_date_ms INTEGER NOT NULL,
        track_time INTEGER NOT NULL,
        track_money INTEGER NOT NULL
      );
    ''');
  }

  Future<void> _createJournalEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE journal_entries (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        entry_date_ms INTEGER NOT NULL,
        text TEXT NOT NULL,
        minutes_spent INTEGER,
        money_spent REAL
      );
    ''');
  }
}