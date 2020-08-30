library loquacious;
import 'package:recase/recase.dart';

class Model {
  /* 
    table propery for defining the sqlite table to query
   */
  String table;

  Model() {
    ReCase rc = new ReCase(this.runtimeType.toString());
    this.table = rc.snakeCase;
  }

  Builder() {

  }

  
}