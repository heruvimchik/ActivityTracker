import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:activityTracker/models/project.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper db = DBHelper._();
  sql.Database _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database;
    _database = await _initDB();
    return _database;
  }

  _initDB() async {
    Directory dbPath = await getApplicationDocumentsDirectory();
    return sql.openDatabase(path.join(dbPath.path, 'projects.db'),
        onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE Projects(projectID TEXT PRIMARY KEY, description TEXT, records TEXT, color INTEGER)');
    }, version: 1);
  }

  Future<void> insert(Map<String, Object> data) async {
    final db = await database;
    await db.insert(
      'Projects',
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getData() async {
    final db = await database;
    return db.query('Projects');
  }

  Future<void> update(Project project) async {
    final db = await database;
    await db.update("Projects", project.toMap(),
        where: 'projectID = ?', whereArgs: [project.projectID]);
  }

  Future<void> delete(Project project) async {
    final db = await database;
    await db.delete("Projects",
        where: 'projectID = ?', whereArgs: [project.projectID]);
  }

  Future<void> clear() async {
    final db = await database;
    db.delete("Projects");
  }
}
