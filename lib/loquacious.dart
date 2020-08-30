library loquacious;

class Model {
  /* 
    table propery for defining the sqlite table to query
   */
  String table;

  Model({this.table}) {
    this.table = this.runtimeType.toString();
  }
}