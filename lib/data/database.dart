import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class AppDatabase {
  AppDatabase.privateConstructor();
  static final AppDatabase instance = AppDatabase.privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'foodapp.db');
    Database db = await openDatabase(
      version: 1,
      path,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return db;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          email TEXT,
          password TEXT,
          age INTEGER,
          heightCm REAL,
          weightKg REAL,
          gender TEXT,
          activityLevel TEXT,
          goalType TEXT,
          dietaryRestrictions TEXT)
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ใส่ migration logic เมื่อเพิ่ม version
  }

  Future close() async {
    final dbClient = await database;
    await dbClient.close();
    _database = null;
  }
}
