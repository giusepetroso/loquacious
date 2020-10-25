class LqModel {
  String table = '';

  DateTime createdAt;
  DateTime updatedAt;

  LqModel() {}
}

class MyModel extends LqModel {
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