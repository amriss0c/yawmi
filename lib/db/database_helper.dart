// lib/db/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/day_task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yawmi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // Increased version to 1. Using a standard initialization pattern.
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        date TEXT PRIMARY KEY,
        taskText TEXT NOT NULL,
        status INTEGER NOT NULL
      )
    ''');
    
    // Indexing the date column ensures that searching for monthly tasks 
    // remains instant even after years of usage.
    await db.execute('CREATE INDEX idx_date ON tasks (date)');
  }

  /// Retrieves a specific task by date string (YYYY-MM-DD)
  Future<DayTask?> getTask(String date) async {
    final db = await database;
    final result = await db.query(
      'tasks', 
      where: 'date = ?', 
      whereArgs: [date],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return DayTask.fromMap(result.first);
  }

  /// OPTIMIZED: Uses BETWEEN for range-based searching instead of LIKE %
  /// This is scientifically more efficient for SQLite indexing.
  Future<Map<String, DayTask>> getTasksForMonth(int year, int month) async {
    final db = await database;
    
    // Generate ISO 8601 compliant bounds
    final String start = '$year-${month.toString().padLeft(2, '0')}-01';
    final String end = '$year-${month.toString().padLeft(2, '0')}-31';

    final result = await db.query(
      'tasks',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
    );

    final Map<String, DayTask> map = {};
    for (final row in result) {
      final task = DayTask.fromMap(row);
      map[task.date] = task;
    }
    return map;
  }

  /// PROFESSIONAL UPSERT: Uses a transaction to ensure data integrity.
  /// This prevents data loss if the app is closed during a write operation.
  Future<void> upsertTask(DayTask task) async {
    final db = await database;
    
    await db.transaction((txn) async {
      await txn.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    
    debugPrint('Database: Upserted task for ${task.date}');
  }

  Future<void> deleteTask(String date) async {
    final db = await database;
    await db.delete('tasks', where: 'date = ?', whereArgs: [date]);
  }

  /// HEALTH CHECK: Verifies the database is responsive.
  Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return true;
    } catch (e) {
      debugPrint("Database Health Check Failed: $e");
      return false;
    }
  }
}