import 'package:loquacious/loquacious.dart';

class Loquacious {
  // INITIALIZING A SINGLE DATABASE
  static Future<void> init(
    String databaseName,
    int databaseVersion, {
    bool useMigrations = false,
  }) async {
    // get instance of db manager
    final lqdbm = LqDBM.instance();

    // init DB
    await lqdbm.init(databaseName, databaseVersion, useMigrations);
  }
}
