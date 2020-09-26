library loquacious;

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
    schema propery for defining the sqlite table schema
   */
  Map<String, DBType> schema;

  /* 
    constructor
   */
  LqModel() {

  }

  /* 
    all
    retrieve all the collection
   */
  List<Map<String, dynamic>> all() {
    return LqQueryBuilder(this.table).all();
  }
}

class LqQueryBuilder {
  String _query;

  String _table;
  LqQueryBuilder(this._table);

  List<LqQueryWhereClause> whereList;
  List<LqQueryOrderClause> orderList;

  List<Map<String, dynamic>> all() {}
}

class LqQueryWhereClause {}

class LqQueryOrderClause {}
