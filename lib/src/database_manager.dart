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
  static Map<String, Database> _dbMap = {};
  static Map<String, int> _versionMap = {};

  static Future<void> loadDBs(List<String> databases) async {
    for (var i = 0; i < databases.length; i++) {
      final databaseName = databases[i];
      if (!_dbMap.containsKey(databaseName)) {
        await loadVersion(databaseName); // load version
        _dbMap[databaseName] = await openDatabase("$databaseName.db",
            // version: _versionMap[databaseName],
            version: 5, onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        }, onUpgrade: (Database db, int newVersion, int oldVersion) {
          db.execute("DROP TABLE IF EXISTS 'users'");
          db.execute("DROP TABLE IF EXISTS 'posts'");
          db.execute("CREATE TABLE IF NOT EXISTS 'users' (id INTEGER PRIMARY KEY, name TEXT NOT NULL, username TEXT NOT NULL, password TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)");
          db.execute("CREATE TABLE IF NOT EXISTS 'posts' (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL, title TEXT NOT NULL, content TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY (user_id) REFERENCES users (id))");
          db.insert('users', {
            'name': 'Mario Rossi',
            'username': 'mrossi',
            'password': 'gin1jed7iwjds9#!)0',
            'created_at': '2020-10-24 22:00',
            'updated_at': '2020-10-24 22:10',
          });
          db.insert('users', {
            'name': 'Carlo Verdi',
            'username': 'cverdi',
            'password': 'gin1jed7iwjds9#!)0',
            'created_at': '2020-10-24 22:20',
            'updated_at': '2020-10-24 22:30',
          });
          db.insert('posts', {
            'user_id': 1,
            'title': 'Post 1 di Mario',
            'content': 'Lorem ipsum Mario 1 ecc...',
            'created_at': '2020-10-25 12:00',
            'updated_at': '2020-10-25 12:10',
          });
          db.insert('posts', {
            'user_id': 1,
            'title': 'Post 2 di Mario',
            'content': 'Lorem ipsum Mario 2 ecc...',
            'created_at': '2020-10-25 12:20',
            'updated_at': '2020-10-25 12:30',
          });
          db.insert('posts', {
            'user_id': 1,
            'title': 'Post 3 di Mario',
            'content': 'Lorem ipsum Mario 3 ecc...',
            'created_at': '2020-10-25 12:40',
            'updated_at': '2020-10-25 12:50',
          });
          db.insert('posts', {
            'user_id': 2,
            'title': 'Post 1 di Carlo',
            'content': 'Lorem ipsum Carlo 1 ecc...',
            'created_at': '2020-10-25 13:00',
            'updated_at': '2020-10-25 13:10',
          });
          db.insert('posts', {
            'user_id': 2,
            'title': 'Post 2 di Carlo',
            'content': 'Lorem ipsum Carlo 2 ecc...',
            'created_at': '2020-10-25 13:20',
            'updated_at': '2020-10-25 13:30',
          });
          db.insert('posts', {
            'user_id': 2,
            'title': 'Post 3 di Carlo',
            'content': 'Lorem ipsum Carlo 3 ecc...',
            'created_at': '2020-10-25 13:40',
            'updated_at': '2020-10-25 13:50',
          });
        });
      }
    }
  }

  /* 
    GETS A DATABASE FROM THE DB MAP (the database should be loaded before get the db)
   */
  static Database getDB({String databaseName}) {
    if (databaseName == null) databaseName = 'test'; //TODO get from env
    if (!_dbMap.containsKey(databaseName)) return null;
    return _dbMap[databaseName];
  }

  static Future<void> loadVersion(String databaseName) async {
    if (_versionMap.containsKey(databaseName)) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('loquacious_db_version:$databaseName')) {
      _versionMap[databaseName] = prefs.getInt('loquacious_db_version:$databaseName');
    } else {
      _versionMap[databaseName] = 1;
    }
  }
}
