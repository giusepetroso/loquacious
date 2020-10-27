import 'package:intl/intl.dart';
import 'package:loquacious/src/query_builder.dart';

abstract class LqModel {
  static const String _primaryKey = 'id';
  String _table;
  Map<String, dynamic> _arguments;

  DateTime get createdAt => DateTime.parse(_arguments['created_at']);
  set createdAt(DateTime value) {
    _arguments['created_at'] = DateFormat('yyy-MM-dd H:m:s').format(value);
  }

  DateTime get updatedAt => DateTime.parse(_arguments['updated_at']);
  set updatedAt(DateTime value) {
    _arguments['updated_at'] = DateFormat('yyy-MM-dd H:m:s').format(value);
  }

  // STATIC METHODS
  static Future<List<Map<String, dynamic>>> _all(String table) async {
    return await LQB.table(table).get();
  }

  static Future<List<Map<String, dynamic>>> _find(String table, int id, {String primaryKey = _primaryKey}) async {
    if (primaryKey == null) primaryKey = _primaryKey;
    return await LQB.table(table).where(primaryKey, id).get();
  }

  // INSTANCE METHODS
  Future<void> _save({String primaryKey = _primaryKey}) async {
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
}

class Customer extends LqModel {
  static const String _primaryKey = 'id';
  
  String _table = 'customers';
  String get table => _table;

  Map<String, dynamic> _arguments = {
    'id': null,
    'name': null,
    'created_at': null,
    'updated_at': null,
  };
  Map<String, dynamic> get arguments => _arguments;

  int get id => _arguments['id'];
  set id(int value) {
    _arguments['id'] = value;
  }

  String get name => _arguments['name'];
  set name(String value) {
    _arguments['name'] = value;
  }

  Customer({
    int id,
    String name,
  }) {
    this.id = id;
    this.name = name;
  }

  static Future<Customer> create({int id, String name}) async {
    final m = Customer();
    m.id = id;
    m.name = name;
    await m.save();
    return m;
  }

  // MAP METHOD
  static Customer mapToModel(Map<String, dynamic> e) {
    final m = Customer(
      id: e['id'],
      name: e['name'],
    );
    m._arguments['created_at'] = e['created_at'];
    m._arguments['updated_at'] = e['updated_at'];
    return m;
  }

  // STATIC METHODS
  static Future<List<Customer>> all() async {
    final res = await LqModel._all('customers');
    return res.map(Customer.mapToModel).toList();
  }

  static Future<Customer> find(int id) async {
    final res = await LqModel._find('customers', id, primaryKey: Customer._primaryKey);
    return res.map(Customer.mapToModel).toList().first;
  }

  // INSTANCE METHODS
  Future<Customer> save() async {
    await super._save(primaryKey: Customer._primaryKey);
    return this;
  }
}
