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

// LOQUACIOUS DATABASE MANAGEMENT
class LoquaciousDatabaseManager {
  static Map<String, Database> _dbMap = {};
  static Map<String, int> _versionMap = {};

  static Future<void> loadDBs(List<String> databases) async {
    for (var i = 0; i < databases.length; i++) {
      final databaseName = databases[i];
      if (!_dbMap.containsKey(databaseName)) {
        await loadVersion(databaseName); // load version
        _dbMap[databaseName] = await openDatabase("$databaseName.db",
            // version: _versionMap[databaseName],
            version: 3, onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        }, onUpgrade: (Database db, int newVersion, int oldVersion) {
          db.execute("DROP TABLE IF EXISTS 'my_model'");
          db.execute("DROP TABLE IF EXISTS 'pippo'");
          db.execute("CREATE TABLE IF NOT EXISTS 'my_model' (id INTEGER PRIMARY KEY, name TEXT, pippo_id INTEGER)");
          db.execute("CREATE TABLE IF NOT EXISTS 'pippo' (id INTEGER PRIMARY KEY, pippo_name TEXT)");
          db.insert('my_model', {
            'name': 'ginetto',
            'pippo_id': 1,
          });
          db.insert('my_model', {
            'name': 'carletto',
            'pippo_id': 2,
          });
          db.insert('my_model', {
            'name': 'pippetto',
            'pippo_id': 3,
          });
          db.insert('my_model', {
            'name': 'no pippo',
            'pippo_id': 4,
          });
          db.insert('my_model', {
            'name': 'no pippo id',
          });
          db.insert('pippo', {
            'pippo_name': 'ginetto bis',
          });
          db.insert('pippo', {
            'pippo_name': 'carletto bis',
          });
          db.insert('pippo', {
            'pippo_name': 'pippetto bis',
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

// LOQUACIOUS QUERY BUILDER
enum OP {
  EQ,
  NE,
  GT,
  LT,
  GE,
  LE,
}

class LQB {
  // database instance
  Database _db;

  // query props
  String _table;
  bool _distinct;
  List<Map<String, String>> _join;
  List<String> _columns;
  List<Map<String, String>> _where;
  List<dynamic> _whereArgs;
  String _groupBy;
  String _having;
  String _orderBy;
  int _limit;
  int _offset;

  /* 
    TABLE CONSTRUCTOR (entrypoint for all queries)
  */
  factory LQB.table(String tableName) {
    final lqb = LQB._internal();
    lqb._table = tableName;
    return lqb;
  }

  /* 
    INTERNAL CONSTRUCTOR
   */
  LQB._internal() {
    this._db = LoquaciousDatabaseManager.getDB();
  }

  // ##################
  // UTILITY
  // ##################
  static String opToString(OP operator) {
    String op = '=';
    switch (operator) {
      case OP.EQ:
        op = '=';
        break;
      case OP.NE:
        op = '!=';
        break;
      case OP.GT:
        op = '=';
        break;
      case OP.GE:
        op = '=';
        break;
      case OP.LT:
        op = '=';
        break;
      case OP.LE:
        op = '=';
        break;
    }
    return op;
  }

  // ##################
  // RAW METHODS
  // ##################
  // TODO

  // ##################
  // SELECTS
  // ##################

  // SELECT
  LQB select(List<String> columns) {
    this._columns = columns;
    return this;
  }

  // COMMON WHERE
  LQB _commonWhere(
    String column,
    dynamic value,
    String whereOperator, {
    OP operator,
  }) {
    final op = LQB.opToString(operator);

    if (this._where == null) this._where = [];
    this._where.add({
      'logical_operator': this._where.length == 0 ? '' : "$whereOperator",
      'where_string': "$column $op ?",
    });

    if (this._whereArgs == null) this._whereArgs = [];
    this._whereArgs.add(value);
    return this;
  }

  // WHERE
  LQB where(
    String column,
    dynamic value, {
    OP operator,
  }) {
    return this._commonWhere(column, value, 'AND');
  }

  // OR WHERE
  LQB orWhere(
    String column,
    dynamic value, {
    OP operator,
  }) {
    return this._commonWhere(column, value, 'OR');
  }

  // DISTINCT
  LQB distinct() {
    this._distinct = true;
    return this;
  }

  // ADD SELECT
  LQB addSelect(String column) {
    if (this._columns == null) this._columns = [];
    this._columns.add(column);
    return this;
  }

  // COMMON JOIN
  LQB _commonJoin(String joinType, String table, String joinColumn, OP operator, String tableColumn) {
    if (this._join == null) this._join = [];

    final splittedTable = table.toLowerCase().split('as');
    final tableString = splittedTable[0];
    String aliasString;
    if (splittedTable.length > 1) {
      aliasString = splittedTable[1];
    }

    this._join.add({
      'type': joinType,
      'table': tableString,
      'alias': aliasString,
      'join_column': joinColumn,
      'operator': LQB.opToString(operator),
      'table_column': tableColumn,
    });
    return this;
  }

  // INNER JOIN
  LQB join(String table, String joinColumn, OP operator, String tableColumn) {
    this._commonJoin('INNER JOIN', table, joinColumn, operator, tableColumn);
    return this;
  }

  LQB innerJoin(String table, String joinColumn, OP operator, String tableColumn) {
    this._commonJoin('INNER JOIN', table, joinColumn, operator, tableColumn);
    return this;
  }

  // LEFT JOIN
  LQB leftJoin(String table, String joinColumn, OP operator, String tableColumn) {
    this._commonJoin('LEFT JOIN', table, joinColumn, operator, tableColumn);
    return this;
  }

  // RIGHT JOIN
  // not supported by Sqflite
  // LQB rightJoin(String table, String joinColumn, OP operator, String tableColumn) {
  //   this._commonJoin('RIGHT JOIN', table, joinColumn, operator, tableColumn);
  //   return this;
  // }

  // GET
  Future<List<Map<String, dynamic>>> get() async {
    if (this._join == null) {
      return this._db.query(
            this._table,
            distinct: this._distinct,
            columns: this._columns,
            where: this._where == null ? null : this._where.map((w) => "${w['logical_operator']} ${w['where_string']}").join(' '),
            whereArgs: this._whereArgs,
            groupBy: this._groupBy,
            having: this._having,
            orderBy: this._orderBy,
            limit: this._limit,
            offset: this._offset,
          );
    } else {
      // joins
      String joinQueries = this._join.map((j) {
        return """
          ${j['type']} ${j['table']} ${j['alias'] != null ? j['alias'] : ''} 
          ON ${j['alias'] != null ? j['alias'] : j['table']}.${j['join_column']} ${j['operator']} ${this._table}.${j['table_column']}
        """;
      }).join(' ');

      // where
      if (this._where == null) this._where = [];
      String whereQueries = this._where.map((w) => "${w['logical_operator']} ${w['where_string']}").join(' ');

      // build query
      String query = """
      SELECT ${this._distinct == null ? 'DISTINCT' : ''} ${this._columns == null ? '*' : this._columns.join(',')} FROM ${this._table}
      $joinQueries
      $whereQueries
      """;

      return this._db.rawQuery(query);
    }
  }

  // ##################
  // INSERTS
  // ##################

  // INSERT
  Future<void> insert({Map<String, dynamic> values, List<Map<String, dynamic>> rows}) async {
    if (values != null) {
      await this._db.insert(this._table, values);
    } else {
      final batch = this._db.batch();
      for (var i = 0; i < rows.length; i++) {
        batch.insert(this._table, rows[i]);
      }
      await batch.commit(continueOnError: true);
    }
  }
}

class LoquaciousModel {
  String table = '';

  DateTime createdAt;
  DateTime updatedAt;

  LoquaciousModel() {}
}

class MyModel extends LoquaciousModel {
  int id;
  String name;

  factory MyModel.create({int id, String name}) {
    final m = MyModel(id, name);
    m.save();
    return m;
  }

  MyModel(this.id, this.name) {
    this.table = 'my_model';
  }

  Future<MyModel> save() async {
    return this;
  }
}
