import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:loquacious/src/query_builder.dart';

// ##################
// MODEL SUPER CLASS
// ##################
class LqModel {
  static const String _primaryKey = 'id';
  String _table;

  Map<String, dynamic> _arguments = {};
  Map<String, dynamic> get arguments => _arguments;

  DateTime get createdAt => DateTime.parse(_arguments['created_at']);
  set createdAt(DateTime value) {
    _arguments['created_at'] = DateFormat('yyy-MM-dd H:m:s').format(value);
  }

  DateTime get updatedAt => DateTime.parse(_arguments['updated_at']);
  set updatedAt(DateTime value) {
    _arguments['updated_at'] = DateFormat('yyy-MM-dd H:m:s').format(value);
  }

  // INSTANCE METHODS

  @protected
  Future<void> saveOrUpdate({String primaryKey = _primaryKey}) async {
    if (primaryKey == null) primaryKey = _primaryKey;

    if (_arguments.containsKey('created_at') && _arguments['created_at'] == null) {
      createdAt = DateTime.now();
    }
    updatedAt = DateTime.now();

    if (_arguments.containsKey(primaryKey) && _arguments[primaryKey] == null) {
      _arguments.removeWhere((key, value) => key == primaryKey);
      int id = await LQB.table(_table).insertGetId(_arguments);
      _arguments['id'] = id;
    } else {
      await LQB.table(_table).where(primaryKey, _arguments['id']).update(_arguments);
    }
  }

  @override
  String toString() {
    return _arguments.toString();
  }
}

// class Customer extends LqModel {
//   static const String _primaryKey = 'id';

//   String _table = 'customers';
//   String get table => _table;

//   Map<String, dynamic> _arguments = {
//     'id': null,
//     'name': null,
//     'created_at': null,
//     'updated_at': null,
//   };

//   int get id => _arguments['id'];
//   set id(int value) {
//     _arguments['id'] = value;
//   }

//   String get name => _arguments['name'];
//   set name(String value) {
//     _arguments['name'] = value;
//   }

//   Customer({
//     int id,
//     String name,
//   }) {
//     this.id = id;
//     this.name = name;
//   }

//   static Future<Customer> create({int id, String name}) async {
//     final m = Customer();
//     m.id = id;
//     m.name = name;
//     await m.save();
//     return m;
//   }

//   // MAP METHOD
//   static Customer mapToModel(dynamic e) {
//     final el = Map<String, dynamic>.from(e);
//     final m = Customer(
//       id: el['id'],
//       name: el['name'],
//     );
//     m._arguments['created_at'] = el['created_at'];
//     m._arguments['updated_at'] = el['updated_at'];
//     return m;
//   }

//   // STATIC METHODS
//   static Future<List<Customer>> all() async {
//     return _LQBM<Customer>.table('customers').get();
//   }

//   static Future<Customer> find(int id) async {
//     return await _LQBM<Customer>.table('customers').where(Customer._primaryKey, id).first();
//   }

//   static _LQBM<Customer> where(
//     String column,
//     dynamic value, {
//     String comparisonOperator,
//   }) {
//     return _LQBM<Customer>.table('customers').where(
//       column,
//       value,
//       comparisonOperator: comparisonOperator,
//     );
//   }

//   static _LQBM<Customer> orderBy(String column) {
//     return _LQBM<Customer>.table('customers').orderBy(column);
//   }

//   static _LQBM<Customer> orderByDesc(String column) {
//     return _LQBM<Customer>.table('customers').orderByDesc(column);
//   }

//   static _LQBM<Customer> groupBy(List<String> columns) {
//     return _LQBM<Customer>.table('customers').groupBy(columns);
//   }

//   static _LQBM<Customer> limit(int count) {
//     return _LQBM<Customer>.table('customers').limit(count);
//   }

//   static _LQBM<Customer> take(int count) {
//     return _LQBM<Customer>.table('customers').take(count);
//   }

//   static _LQBM<Customer> offset(int count) {
//     return _LQBM<Customer>.table('customers').offset(count);
//   }

//   static _LQBM<Customer> skip(int count) {
//     return _LQBM<Customer>.table('customers').skip(count);
//   }

//   // INSTANCE METHODS
//   Future<Customer> save() async {
//     await super.saveOrUpdate(primaryKey: Customer._primaryKey);
//     return this;
//   }
// }

// // ##################
// // QUERY BUILDER OF MODEL
// // ##################
// class _LQBM<T extends Customer> extends LQB {
//   _LQBM.table(String tableName) : super.table(tableName);

//   @override
//   Future<List<Customer>> get() async {
//     return List<Customer>.from((await this.getDynamic()).map(Customer.mapToModel));
//   }

//   @override
//   Future<Customer> first() async {
//     try {
//       return List<Customer>.from((await this.getDynamic()).map(Customer.mapToModel)).first;
//     } catch (e) {}
//     return null;
//   }
// }
