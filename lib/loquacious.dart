library loquacious;

import 'package:recase/recase.dart';

class LqModel {
  /* 
    table propery for defining the sqlite table to query
   */
  static String table;

  /* 
    constructor
   */
  LqModel() {
    ReCase rc = ReCase(this.runtimeType.toString());
    LqModel.table = rc.snakeCase;
  }

  /* static methods */
  static List<Map<String, dynamic>> all() {
    return LqQueryBuilder(LqModel.table).all();
  }
}

class LqQueryBuilder {
  String _query;
  String _table;
  LqQueryBuilder(this._table);

  List<Map<String, dynamic>> all() {

  }
}
