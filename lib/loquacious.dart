library loquacious;

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

  // query
  String _query;
  List<dynamic> _queryArgs = [];

  // aliases
  Map<String, String> _aliases = {};

  // query props
  String _table;
  bool _distinct;
  List<Map<String, String>> _join;
  List<String> _columns;
  List<Map<String, String>> _where;
  List<String> _groupBy;
  List<Map<String, String>> _having;
  List<Map<String, String>> _orderBy;
  int _limit;
  int _offset;

  LQB _union;

  /* 
    TABLE CONSTRUCTOR (entrypoint for all queries)
  */
  factory LQB.table(String tableName) {
    final lqb = LQB._internal();
    lqb._table = lqb._parseTableAndAlias(tableName);
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
  // ALIAS CHECKING
  // ##################

  // PARSE TABLE AND ALIAS
  // this method parses the string of a table and eventually stores the alias then returns the table name
  String _parseTableAndAlias(String tableName) {
    final splitted = tableName.toLowerCase().split('as');
    final t = splitted[0].trim();
    String a;
    if (splitted.length > 1) {
      a = splitted[1].trim();
      this._aliases[t] = a;
    }
    return t;
  }

  String _checkTableAndAliasInColumn(String column, {String tableName}) {
    column.trim();
    if (column.contains('.')) {
      final splitted = column.split('.');
      if (splitted.length > 2) return null;

      final tableNotation = splitted[0];
      final columnNotation = splitted[1];
      if (tableName == null) {
        if (this._aliases.containsKey(tableNotation)) {
          column = "${this._aliases[tableNotation]}.$columnNotation";
        } else {
          column = "$tableNotation.$columnNotation";
        }
      } else {
        if (this._aliases.containsKey(tableName)) {
          column = "${this._aliases[tableName]}.$columnNotation";
        } else {
          column = "$tableName.$columnNotation";
        }
      }
    } else {
      if (tableName == null) {
        if (this._aliases.containsKey(this._table)) {
          column = "${this._aliases[this._table]}.$column";
        } else {
          column = "${this._table}.$column";
        }
      } else {
        if (this._aliases.containsKey(tableName)) {
          column = "${this._aliases[tableName]}.$column";
        } else {
          column = "$tableName.$column";
        }
      }
    }
    return column;
  }

  // String _findTableInColumnDeclaration(String column) {
  //   column.trim();
  //   if (column.contains('.')) {
  //     final splitted = column.split('.');
  //     if (splitted.length > 2) return null;
  //     if (this._aliases.containsKey(tableName) && splitted[0] == tableName) column = "${this._aliases[tableName]}.${splitted[1]}";
  //   } else {
  //     if (this._aliases.containsKey(tableName)) {
  //       column = "${this._aliases[tableName]}.$column";
  //     } else {
  //       column = "$tableName.$column";
  //     }
  //   }
  //   return column;
  // }

  // ##################
  // SCHEMA METHODS
  // ##################
  Future<List<String>> tableColumns(String tableName) async {
    try {
      final schema = await this._db.rawQuery("PRAGMA table_info('$tableName');");
      return schema.map((e) => e['name']);
    } catch (e) {
      // TODO error handling
    }
    return [];
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
    this._columns = columns
        .map((e) {
          return this._checkTableAndAliasInColumn(e);
        })
        .where((e) => e != null && e.split(' ').length == 1)
        .toList();
    return this;
  }

  // COMMON WHERE
  LQB _commonWhere(
    String column,
    dynamic value,
    String whereOperator, {
    OP operator,
  }) {
    if (this._where == null) this._where = [];
    this._where.add({
      'column': this._checkTableAndAliasInColumn(column),
      'value': value,
      'operator': LQB.opToString(operator),
      'where_operator': this._where.length == 0 ? '' : "$whereOperator ",
    });
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
    this._join.add({
      'type': joinType,
      'table': this._parseTableAndAlias(table),
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

  // TODO: nested joins

  // UNION
  LQB union(LQB queryBuilder) {
    if (queryBuilder == this) throw 'Cannot pass calling instance as union argument';
    this._union = queryBuilder;
    return this;
  }

  // ORDER BY
  LQB _commonOrderBy(String column, String direction) {
    if (this._orderBy == null) this._orderBy = [];
    this._orderBy.add({
      'column': column,
      'direction': direction,
    });
    return this;
  }

  LQB orderBy(String column) {
    return this._commonOrderBy(column, 'ASC');
  }

  // ORDER BY DESC
  LQB orderByDesc(String column) {
    return this._commonOrderBy(column, 'DESC');
  }

  // GROUP BY
  LQB groupBy(String column) {
    if (this._groupBy == null) this._groupBy = [];
    this._groupBy.add(column);
    return this;
  }

  // HAVING

  // GET
  Future<List<Map<String, dynamic>>> get() async {
    try {
      // compile the query
      this._compileQuery();

      // fetch result
      return await this._db.rawQuery(this._query, this._queryArgs);
    } catch (e) {
      print(e);
    }
    return [];
  }

  // ALL
  Future<List<Map<String, dynamic>>> all() async {
    try {
      return await this._db.query(this._table);
    } catch (e) {
      print(e);
    }
    return [];
  }

  // ##################
  // QUERY
  // ##################

  // COMPILE QUERY
  void _compileQuery() {
    String query = "SELECT #distinct #columns FROM #table #join #where #orderBy #groupBy #having #limit #offset ";

    // table
    String table = this._table;
    String alias;
    if (this._aliases.containsKey(this._table)) {
      alias = this._aliases[this._table];
    }

    if (alias == null) {
      query = query.replaceFirst('#table', table);
    } else {
      query = query.replaceFirst('#table', "$table as $alias");
    }

    // distinct
    if (this._distinct != null) {
      query = query.replaceFirst('#distinct', 'DISTINCT');
    } else {
      query = query.replaceFirst('#distinct ', '');
    }

    // columns
    if (this._columns != null) {
      final q = this._columns.join(', ');
      query = query.replaceFirst('#columns', q);
    } else {
      if (alias == null) {
        query = query.replaceFirst('#columns', "$table.*");
      } else {
        query = query.replaceFirst('#columns', "$alias.*");
      }
    }

    // joins
    if (this._join != null) {
      final q = this._join.map((j) {
        final joinTable = this._parseTableAndAlias(j['table']);
        final tableColumn = this._checkTableAndAliasInColumn(j['table_column'], tableName: this._table);
        final joinColumn = this._checkTableAndAliasInColumn(j['join_column'], tableName: j['table']);
        return "${j['type']} $joinTable ${this._aliases.containsKey(joinTable) ? this._aliases[joinTable] + ' ' : ''}ON $joinColumn ${j['operator']} $tableColumn";
      }).join(' ');
      query = query.replaceFirst('#join', q);
    } else {
      query = query.replaceFirst('#join ', '');
    }

    // where
    if (this._where != null) {
      final q = this._where.map((w) {
        final value = w['value'];
        this._queryArgs.add(value);

        final column = w['column'];
        final operator = w['operator'];
        final whereOperator = w['where_operator'];
        return "$whereOperator$column $operator ?";
      }).join(' ');
      query = query.replaceFirst('#where', "WHERE $q");
    } else {
      query = query.replaceFirst('#where ', '');
    }

    // order by
    if (this._orderBy != null) {
      final q = this._orderBy.join(', ');
      query = query.replaceFirst('#orderBy', "ORDER BY $q");
    } else {
      query = query.replaceFirst('#orderBy ', '');
    }

    // group by
    if (this._groupBy != null) {
      final q = this._groupBy.join(', ');
      query = query.replaceFirst('#groupBy', "GROUP BY $q");
    } else {
      query = query.replaceFirst('#groupBy ', '');
    }

    // having
    if (this._having != null) {
      final q = this._having.join(', ');
      query = query.replaceFirst('#having', "HAVING $q");
    } else {
      query = query.replaceFirst('#having ', '');
    }

    // limit
    if (this._limit != null) {
      query = query.replaceFirst('#limit', "LIMIT ${this._limit.toString()}");
    } else {
      query = query.replaceFirst('#limit ', '');
    }

    // offset
    if (this._offset != null) {
      query = query.replaceFirst('#offset', "OFFSET ${this._offset.toString()}");
    } else {
      query = query.replaceFirst('#offset ', '');
    }

    this._query = query.trim() + ';';
  }

  // GET SELECT QUERY
  String getSelectQuery({bool withValues = false}) {
    // compile query
    this._compileQuery();

    // get args
    final args = List<dynamic>.from(this._queryArgs);

    // if with values assign args to ?
    if (withValues) {
      this._query = this._query.replaceAllMapped(new RegExp(r'\?'), (match) {
        final value = args.first;
        args.removeAt(0);
        return "'$value'";
      });
    }

    // return query
    return this._query;
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
