import 'dart:convert';
import 'package:flutter/services.dart';
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

  // INIT METHOD
  Future<void> init(String databaseName, int databaseVersion, bool useMigrations) async {
    await this._loadDB(databaseName, databaseVersion, useMigrations);
  }

  // LOAD THE MIGRATIONS
  Future<Map<String, List<String>>> loadMigrations(int upVersion, int downVersion) async {
    final migrationsFolder = "assets/loquacious/migrations";
    List<String> upMigs;
    List<String> downMigs;
    try {
      final upFile = await rootBundle.loadString("$migrationsFolder/$upVersion.json");
      final upDecoded = json.decode(upFile);
      upMigs = List<String>.from(upDecoded['up']);
    } catch (e) {
      print(e);
    }

    try {
      if (downVersion != null) {
        final downFile = await rootBundle.loadString("$migrationsFolder/$downVersion.json");
        final downDecoded = json.decode(downFile);
        downMigs = List<String>.from(downDecoded['down']);
      }
    } catch (e) {
      print(e);
    }

    return {
      'up': upMigs,
      'down': downMigs,
    };
  }

  // LOAD THE DATABASE
  Future<void> _loadDB(String databaseName, int databaseVersion, bool useMigrations) async {
    _db = await openDatabase("$databaseName.db", version: databaseVersion, onConfigure: (Database db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (Database db, int version) async {
      final migs = await this.loadMigrations(version, null);
      if (migs['up'] != null) {
        db.transaction((txn) async {
          List<Future> execs = [];
          for (var i = 0; i < migs['up'].length; i++) {
            execs.add(txn.execute(migs['up'][i]));
          }
          await Future.wait(execs);
        });
      }
    }, onUpgrade: (Database db, int newVersion, int oldVersion) async {
      final migs = await this.loadMigrations(newVersion, oldVersion);
      if (migs['up'] != null) {
        db.transaction((txn) async {
          List<Future> execs = [];
          for (var i = 0; i < migs['up'].length; i++) {
            execs.add(txn.execute(migs['up'][i]));
          }
          await Future.wait(execs);
        });
      }
    }, onDowngrade: (Database db, int newVersion, int oldVersion) async {
      final migs = await this.loadMigrations(newVersion, oldVersion);
      if (migs['down'] != null) {
        db.transaction((txn) async {
          List<Future> execs = [];
          for (var i = 0; i < migs['down'].length; i++) {
            execs.add(txn.execute(migs['down'][i]));
          }
          await Future.wait(execs);
        });
      }
    }, onOpen: (Database db) async {});
  }

  // GETS THE DATABASE INSTANCE
  Database getDB() {
    return _db;
  }
}
