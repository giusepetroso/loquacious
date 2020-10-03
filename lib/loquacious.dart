library loquacious;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

enum DBType {
  NULL,
  INTEGER,
  REAL,
  TEXT,
  BLOB,
}

class LqModel {
  /* 
    table propery for defining the sqlite table to query
   */
  String table;

  /* 
    constructor
   */
  LqModel() {}

  /* 
    all
    retrieve all the collection
   */
  List<Map<String, dynamic>> all() {}
}

// LOQUACIOUS DATABASE MANAGEMENT
class LoquaciousDatabaseManager {
  static Map<String, Database> dbMap = {};
  static Map<String, int> versionMap = {};

  static Future<Database> getDB(String databaseName) async {
    if (!dbMap.containsKey(databaseName)) {
      await loadVersion(databaseName); // load version
      dbMap[databaseName] = await openDatabase(
        "$databaseName.db",
        version: versionMap[databaseName],
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: LoquaciousMigrationManager.createMigrationClosure,
        onUpgrade: LoquaciousMigrationManager.upgradeMigrationClosure,
      );
    }
    return dbMap[databaseName];
  }

  static Future<void> loadVersion(String databaseName) async {
    if (versionMap.containsKey(databaseName)) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('loquacious_db_version:$databaseName')) {
      versionMap[databaseName] = prefs.getInt('loquacious_db_version:$databaseName');
    } else {
      versionMap[databaseName] = 1;
    }
  }
}

// QUERY BUILDER
class LoquaciousQueryBuilder {
  final databaseName;
  LoquaciousQueryBuilder(this.databaseName);
}

// MIGRATION MANAGEMENT
class LoquaciousMigrationManager {
  Map<int, String> migrationsMap = {};
  Future<List<LoquaciousMigration>> getMigrations() {}

  static Future<void> createMigrationClosure(Database db, int version) async {

  
  }
  static Future<void> upgradeMigrationClosure(Database db, int oldVersion, int newVersion) async {}
}

class LoquaciousMigration {
  final String databaseName;
  final String tableName;
  LoquaciousMigration({
    @required this.databaseName,
    @required this.tableName,
  });

  Future<List<String>> up() async {}
  Future<List<String>> down() async {}
}
