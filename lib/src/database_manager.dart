import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:loquacious/src/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// LOQUACIOUS DATABASE MANAGER
enum DBType {
  NULL,
  INTEGER,
  REAL,
  TEXT,
  BLOB,
}

class LqDBM {
  // SINGLETON CONSTRUCT
  static LqDBM _self;
  factory LqDBM.instance() {
    if (LqDBM._self == null) {
      LqDBM._self = LqDBM._internal();
    }
    return LqDBM._self;
  }
  LqDBM._internal();

  // DB PROPS
  Database _db;
  String _dbName;
  int _dbVersion;

  // INIT METHOD
  Future<void> init(
    String databaseName,
    int databaseVersion, {
    bool useMigrations,
    bool resetDB,
  }) async {
    this._dbName = databaseName;
    this._dbVersion = databaseVersion;
    if (resetDB) await this._deleteDB();
    await this._loadDB(useMigrations);
  }

  // MIGRATIONS METHODS
  Future<List<String>> loadMigrations(int version, String direction) async {
    final migrationsFolder = "assets/loquacious/migrations";
    List<String> migs;
    try {
      final file = await rootBundle.loadString("$migrationsFolder/$version.json");
      final fileDecoded = json.decode(file);
      migs = List<String>.from(fileDecoded[direction]);
    } catch (e) {
      print(e);
    }

    return migs;
  }

  // DELETE DATABASE
  Future<void> _deleteDB() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    await sp.remove('loquacious_db_version:${this._dbName}');
    await deleteDatabase("${this._dbName}.db");
  }

  // LOAD THE DATABASE
  Future<void> _loadDB(bool useMigrations) async {
    _db = await openDatabase("${this._dbName}.db", onConfigure: (Database db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onOpen: (Database db) async {
      SharedPreferences sp = await SharedPreferences.getInstance();
      final prefsVersionKey = 'loquacious_db_version:${this._dbName}';
      List<String> migs;
      int dbVersion = 0;
      if (sp.containsKey(prefsVersionKey)) {
        dbVersion = sp.getInt(prefsVersionKey);
      }

      // upgrade migrations
      if (this._dbVersion > dbVersion) {
        migs = await this.loadMigrations(this._dbVersion, 'up');
      }

      // downgrade migrations
      if (this._dbVersion < dbVersion) {
        migs = await this.loadMigrations(dbVersion, 'down');
      }

      // run migrations
      Exception error;
      if (migs != null) {
        try {
          await db.transaction((txn) async {
            List<Future> execs = [];
            for (var i = 0; i < migs.length; i++) {
              execs.add(txn.execute(migs[i]));
            }
            await Future.wait(execs);
          });
        } catch (e) {
          error = e;
        }
      }

      // save new version
      if (error == null) {
        if (this._dbVersion != dbVersion) {
          await sp.setInt(prefsVersionKey, this._dbVersion);
        }
      } else {
        throw MigrationException(this._dbVersion, this._dbVersion > dbVersion ? 'up' : 'down', error.toString());
      }
    });
  }

  // GETS THE DATABASE INSTANCE
  Database getDB() {
    return _db;
  }
}
