library loquacious;

import 'package:flutter/foundation.dart';
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
  List<Map<String, dynamic>> all() {

  }
}

// QUERY BUILDER
class LoquaciousQueryBuilder {
  final databaseName;
  LoquaciousQueryBuilder(this.databaseName);

  Future<void> createTable(String tableName) async {
    var db = await openDatabase("${this.databaseName}.db");
  }
}

// MIGRATION MANAGEMENT
class LoquaciousMigration {
  final String databaseName;
  final String tableName;
  LoquaciousMigration({
    @required this.databaseName,
    @required this.tableName,
  });

  Future<void> up() async {
    
  }
}
