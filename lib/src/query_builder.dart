import 'database_manager.dart';
import 'package:sqflite/sqflite.dart';

// LOQUACIOUS QUERY BUILDER
const String EQ = '=';
const String NE = '!=';
const String GT = '>';
const String GE = '>=';
const String LT = '<';
const String LE = '<=';
const String EQUALS = EQ;
const String NOT_EQUALS = NE;
const String GREATER_THAN = GT;
const String GREATER_EQUALS = GE;
const String LESS_THAN = LT;
const String LESS_EQUALS = LE;

// ##################
// QUERY BUILDER UTILITIES
// ##################
class LqbUtils {
  static String _checkComparisonOperator(String comparisonOperator) {
    if (comparisonOperator != '=' && comparisonOperator != '!=' && comparisonOperator != '<>' && comparisonOperator != '<' && comparisonOperator != '<=' && comparisonOperator != '>' && comparisonOperator != '>=') {
      return '=';
    }
    return comparisonOperator;
  }
}

// ##################
// QUERY BUILDER MAIN CLASS
// ##################
class LQB {
  /* 
    TODO 
    - error handling
    - raw queries methods
    - raw queries options in normal methods
    - nested joins
    - column aliases
    - latest/oldest methods
    - inRandomOrder method
    - reorder method
    - aggregates methods
    - insert many: when rows count is huge consider to do a batch
    - insertOrIgnore method
    - upsert method
    - updateOrInsert method
  */

  // database instance
  Database _db;

  // query
  String _query;
  Map<String, List<dynamic>> _queryArgs = {
    'values': [],
    'where': [],
    'having': [],
  };

  // aliases
  Map<String, String> _tAliases = {}; // tables aliases
  Map<String, String> _cAliases = {}; // columns aliases

  // query props
  String _table;
  bool _distinct;
  List<Map<String, String>> _join;
  List<String> _columns;
  List<Map<String, dynamic>> _where;
  List<String> _groupBy;
  Map<String, dynamic> _having;
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
    this._db = LqDBM.instance().getDB();
    if(this._db == null) {
      throw Exception('Cannot instantiate Loquacious Query Builder before Database initialization');
    }
  }

  // ##################
  // ARGS
  // ##################
  List<dynamic> _getQueryArgs() {
    return [
      ...this._queryArgs['values'],
      ...this._queryArgs['where'],
      ...this._queryArgs['having'],
    ];
  }

  void _mergeQueryArgs(Map<String, List<dynamic>> otherArgs) {
    for (var type in this._queryArgs.keys) {
      this._queryArgs[type].addAll(otherArgs[type]);
    }
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
      this._tAliases[t] = a;
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
        if (this._tAliases.containsKey(tableNotation)) {
          column = "${this._tAliases[tableNotation]}.$columnNotation";
        } else {
          column = "$tableNotation.$columnNotation";
        }
      } else {
        if (this._tAliases.containsKey(tableName)) {
          column = "${this._tAliases[tableName]}.$columnNotation";
        } else {
          column = "$tableName.$columnNotation";
        }
      }
    } else {
      if (tableName == null) {
        if (this._tAliases.containsKey(this._table)) {
          column = "${this._tAliases[this._table]}.$column";
        } else {
          column = "${this._table}.$column";
        }
      } else {
        if (this._tAliases.containsKey(tableName)) {
          column = "${this._tAliases[tableName]}.$column";
        } else {
          column = "$tableName.$column";
        }
      }
    }
    return column;
  }

  // ##################
  // SCHEMA METHODS
  // ##################
  Future<List<String>> tableColumns(String tableName) async {
    try {
      final schema = await this._db.rawQuery("PRAGMA table_info('$tableName');");
      return schema.map((e) => e['name']);
    } catch (e) {
      print(e);
    }
    return [];
  }

  // ##################
  // BUILD RAW METHODS
  // ##################
  // selectRaw
  // whereRaw/orWhereRaw
  // havingRaw/orHavingRaw
  // orderByRaw
  // groupByRaw

  // ##################
  // BUILD METHODS
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
    String comparisonOperator,
  }) {
    if (this._where == null) this._where = [];
    this._queryArgs['where'].add(value);
    this._where.add({
      'column': this._checkTableAndAliasInColumn(column),
      'value': value,
      'comparisonOperator': LqbUtils._checkComparisonOperator(comparisonOperator),
      'whereOperator': this._where.length == 0 ? '' : "$whereOperator ",
    });
    return this;
  }

  // WHERE
  LQB where(
    String column,
    dynamic value, {
    String comparisonOperator,
  }) {
    return this._commonWhere(column, value, 'AND', comparisonOperator: comparisonOperator);
  }

  // OR WHERE
  LQB orWhere(
    String column,
    dynamic value, {
    String comparisonOperator,
  }) {
    return this._commonWhere(column, value, 'OR', comparisonOperator: comparisonOperator);
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
  LQB _commonJoin(String joinType, String table, String joinColumn, String comparisonOperator, String tableColumn) {
    if (this._join == null) this._join = [];
    this._join.add({
      'type': joinType,
      'table': this._parseTableAndAlias(table),
      'join_column': joinColumn,
      'comparisonOperator': LqbUtils._checkComparisonOperator(comparisonOperator),
      'table_column': tableColumn,
    });
    return this;
  }

  // INNER JOIN
  LQB join(String table, String joinColumn, String comparisonOperator, String tableColumn) {
    this._commonJoin('INNER JOIN', table, joinColumn, comparisonOperator, tableColumn);
    return this;
  }

  LQB innerJoin(String table, String joinColumn, String comparisonOperator, String tableColumn) {
    this._commonJoin('INNER JOIN', table, joinColumn, comparisonOperator, tableColumn);
    return this;
  }

  // LEFT JOIN
  LQB leftJoin(String table, String joinColumn, String comparisonOperator, String tableColumn) {
    this._commonJoin('LEFT JOIN', table, joinColumn, comparisonOperator, tableColumn);
    return this;
  }

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
  LQB groupBy(List<String> columns) {
    if (this._groupBy == null) this._groupBy = [];
    this._groupBy.addAll(columns);
    return this;
  }

  // HAVING
  LQB having(
    String column,
    String comparisonOperator,
    dynamic value,
  ) {
    this._queryArgs['having'].add(value);
    this._having = {
      'column': this._checkTableAndAliasInColumn(column),
      'value': value,
      'comparisonOperator': LqbUtils._checkComparisonOperator(comparisonOperator),
    };
    return this;
  }

  // LIMIT / TAKE
  LQB limit(int count) {
    this._limit = count;
    return this;
  }

  LQB take(int count) {
    return this.limit(count);
  }

  // OFFSET / SKIP
  LQB offset(int count) {
    this._offset = count;
    return this;
  }

  LQB skip(int count) {
    return this.offset(count);
  }

  // ##################
  // QUERY
  // ##################

  // GET SELECT QUERY WITH ARGUMENTS
  Map<String, dynamic> getSelectQueryAndArgs({bool withValues = false}) {
    // compile query
    this._compileSelect();

    // get args
    final args = List<dynamic>.from(this._getQueryArgs());

    // if with values assign args to ?
    if (withValues) {
      this._query = this._query.replaceAllMapped(new RegExp(r'\?'), (match) {
        final value = args.first;
        args.removeAt(0);
        return "'$value'";
      });
    }

    // return query
    return {
      'query': this._query,
      'args': this._queryArgs,
    };
  }

  // GET SELECT QUERY
  String getSelectQuery({bool withValues = false}) {
    return this.getSelectQueryAndArgs(withValues: withValues)['query'];
  }

  // ##################
  // GET
  // ##################

  Future<List<Map<String, dynamic>>> get() async {
    try {
      // compile the query
      this._compileSelect();

      // fetch result
      return await this._db.rawQuery(this._query, this._getQueryArgs());
    } catch (e) {
      print(e);
    }
    return [];
  }

  // ##################
  // INSERTS
  // ##################

  // INSERT
  Future<int> insertGetId(Map<String, dynamic> values) async {
    try {
      return await this._db.insert(this._table, values);
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> insert(Map<String, dynamic> values) async {
    try {
      await this.insertGetId(values);
    } catch (e) {
      print(e);
    }
  }

  // INSERT MANY
  Future<void> insertMany(List<Map<String, dynamic>> rows) async {
    this._db.transaction((txn) async {
      List<Future> futs = [];
      for (var i = 0; i < rows.length; i++) {
        futs.add(txn.insert(this._table, rows[i]));
      }
      await Future.wait(futs);
    });
  }

  // ##################
  // UPDATES
  // ##################
  Future<void> update(Map<String, dynamic> values) async {
    try {
      // compile the query
      this._compileUpdate(values);

      // fetch result
      return await this._db.rawUpdate(this._query, this._getQueryArgs());
    } catch (e) {
      print(e);
    }
  }

  // ##################
  // DELETES
  // ##################

  Future<void> delete() async {
    try {
      // compile the query
      this._compileDelete();

      // fetch result
      return await this._db.rawDelete(this._query, this._getQueryArgs());
    } catch (e) {
      print(e);
    }
  }

  Future<void> truncate() async {
    try {
      final query = """
        DELETE FROM ${this._table};
        DELETE FROM sqlite_sequence WHERE name = ${this._table};
      """;

      // fetch result
      return await this._db.rawDelete(query);
    } catch (e) {
      print(e);
    }
  }

  // ##################
  // COMPILATIONS
  // ##################
  String _compileTable(String query) {
    String alias;
    if (this._tAliases.containsKey(this._table)) {
      alias = this._tAliases[this._table];
    }

    if (alias == null) {
      query = query.replaceFirst('#table', this._table);
    } else {
      query = query.replaceFirst('#table', "${this._table} as $alias");
    }
    return query;
  }

  String _compileDistinct(String query) {
    if (this._distinct != null) {
      query = query.replaceFirst('#distinct', 'DISTINCT');
    } else {
      query = query.replaceFirst('#distinct ', '');
    }
    return query;
  }

  String _compileJoin(String query) {
    if (this._join != null) {
      final q = this._join.map((j) {
        final joinTable = this._parseTableAndAlias(j['table']);
        final tableColumn = this._checkTableAndAliasInColumn(j['table_column'], tableName: this._table);
        final joinColumn = this._checkTableAndAliasInColumn(j['join_column'], tableName: j['table']);
        return "${j['type']} $joinTable ${this._tAliases.containsKey(joinTable) ? this._tAliases[joinTable] + ' ' : ''}ON $joinColumn ${j['comparisonOperator']} $tableColumn";
      }).join(' ');
      query = query.replaceFirst('#join', q);
    } else {
      query = query.replaceFirst('#join ', '');
    }
    return query;
  }

  String _compileColumns(String query) {
    if (this._columns != null) {
      final q = this._columns.join(', ');
      query = query.replaceFirst('#columns', q);
    } else {
      if (this._tAliases.containsKey(this._table)) {
        query = query.replaceFirst('#columns', "${this._tAliases[this._table]}.*");
      } else {
        query = query.replaceFirst('#columns', "${this._table}.*");
      }
    }
    return query;
  }

  String _compileWhere(String query) {
    if (this._where != null) {
      final q = this._where.map((w) {
        final column = w['column'];
        final comparisonOperator = w['comparisonOperator'];
        final whereOperator = w['whereOperator'];
        return "$whereOperator$column $comparisonOperator ?";
      }).join(' ');
      query = query.replaceFirst('#where', "WHERE $q");
    } else {
      query = query.replaceFirst('#where ', '');
    }
    return query;
  }

  String _compileGroupBy(String query) {
    if (this._groupBy != null) {
      final q = this._groupBy.join(', ');
      query = query.replaceFirst('#groupBy', "GROUP BY $q");
    } else {
      query = query.replaceFirst('#groupBy ', '');
    }
    return query;
  }

  String _compileHaving(String query) {
    if (this._having != null) {
      final column = this._having['column'];
      final comparisonOperator = this._having['comparisonOperator'];
      query = query.replaceFirst('#having', "HAVING $column $comparisonOperator ?");
    } else {
      query = query.replaceFirst('#having ', '');
    }
    return query;
  }

  String _compileOrderBy(String query) {
    if (this._orderBy != null) {
      final q = this._orderBy.map((o) => "${o['column']} ${o['direction']}").reduce((value, element) => "$value, $element");
      query = query.replaceFirst('#orderBy', "ORDER BY $q");
    } else {
      query = query.replaceFirst('#orderBy ', '');
    }
    return query;
  }

  String _compileLimit(String query) {
    if (this._limit != null) {
      query = query.replaceFirst('#limit', "LIMIT ${this._limit.toString()}");
    } else {
      query = query.replaceFirst('#limit ', '');
    }
    return query;
  }

  String _compileOffset(String query) {
    if (this._offset != null) {
      query = query.replaceFirst('#offset', "OFFSET ${this._offset.toString()}");
    } else {
      query = query.replaceFirst('#offset ', '');
    }
    return query;
  }

  String _compileUnion(String query) {
    if (this._union != null) {
      final unionQuery = this._union.getSelectQueryAndArgs();
      query += "UNION ${unionQuery['query']}";
      this._mergeQueryArgs(unionQuery['args']);
    }
    return query;
  }

  void _compileSelect() {
    String query = "SELECT #distinct #columns FROM #table #join #where #orderBy #groupBy #having #limit #offset ";

    // table
    query = _compileTable(query);

    // distinct
    query = _compileDistinct(query);

    // join
    query = _compileJoin(query);

    // columns
    query = _compileColumns(query);

    // where
    query = _compileWhere(query);

    // group by
    query = _compileGroupBy(query);

    // having
    query = _compileHaving(query);

    // order by
    query = _compileOrderBy(query);

    // limit
    query = _compileLimit(query);

    // offset
    query = _compileOffset(query);

    // union
    query = _compileUnion(query);

    // set query
    this._query = query.trim();
  }

  void _compileDelete() {
    String query = "DELETE FROM #table #where ";

    // table
    query = _compileTable(query);

    // where
    query = _compileWhere(query);

    // set query
    this._query = query.trim();
  }

  void _compileUpdate(Map<String, dynamic> values) {
    String query = "UPDATE #table SET #values #where #orderBy #limit #offset ";

    // table
    query = _compileTable(query);

    // values
    List<String> vList = [];
    for (var column in values.keys) {
      vList.add("$column = ?");
      this._queryArgs['values'].add(values[column]);
    }
    query = query.replaceFirst('#values', vList.join(', '));

    // where
    query = _compileWhere(query);

    // order by
    query = _compileOrderBy(query);

    // limit
    query = _compileLimit(query);

    // offset
    query = _compileOffset(query);

    // set query
    this._query = query.trim();
  }
}
