library loquacious;

import 'package:recase/recase.dart';

class LqModel {
  /* 
    table propery for defining the sqlite table to query
   */
  String table;

  /* 
    constructor
   */
  LqModel() {
    ReCase rc = ReCase(this.runtimeType.toString());
    this.table = rc.snakeCase;
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
