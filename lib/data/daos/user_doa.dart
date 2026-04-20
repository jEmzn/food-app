import 'package:app1/models/user_profile.dart';
import 'package:app1/data/database.dart';
import 'package:sqflite/sql.dart';

class UserDOA {
  final database = AppDatabase.instance;

  Future<int> insertUser(UserProfile user) async {
    final db = await database.database;

    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUserById(int id) async {
    final db = await database.database;

    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (results.isNotEmpty) {
      return UserProfile.fromMap(results.first);
    }
    return null;
  }
}
