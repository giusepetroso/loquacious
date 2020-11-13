# LOQUACIOUS

An ORM for Flutter inspired by Laravel Eloquent

This package is built on top of the [Sqflite](https://pub.dev/packages/sqflite) package

Features:
- Database manager (migrations)
- Query builder
- Object Relational Mapping with generated models 

## Install
In the **pubspec.yaml** file:
```
// loquacious in dependencies
dependencies:
  ...
  loquacious: <last_version>

// craftsman in dev dependencies
dev_dependencies:
  ...
  craftsman: <last_version>

// define loquacious asset folders
flutter:
  ...
  assets:
  ... 
  - assets/loquacious/migrations/
```

## Documentation index
1. [Use craftsman](#use-craftsman)
2. [Generate your first 'descriptor' file with craftsman](#generate-your-first-descriptor-file-with-craftsman)
3. [Run craftsman scaffold](#run-craftsman-scaffold)
4. [Start using Loquacious](#start-using-loquacious)
5. [Using Loquacious Query Builder](#using-loquacious-query-builder)
6. [Using Loquacious ORM](#using-loquacious-orm)

## Use craftsman
[Craftsman](https://pub.dev/packages/craftsman) package is the Loquacious tool for files generation and scaffolding

Craftsman is not required but **highly recommended** since it helps you to scaffold complex generated files

*For example using ORM feature require model classes generation, that will be very tedious and prone to errors task, but with Craftsman you can make it very simple and straightforward*

## Generate your first 'descriptor' file with craftsman
Run the command `flutter pub run craftsman:descriptor` and follow the console instruction for generating a descriptor file

The descriptor file defines two different scaffolding description type:
- **db** type, for the migration file generation
- **orm** type, for models generation

After descriptor generation you should have a **json** file in `craftsman/descriptor` (named as the version you input) which is a template like this:

```
{
  "db": {
    "version": 1,
    "migrations": [
      {
        "create_table": {
          "name": "TABLE_NAME",
          "columns": [
            {
              "name": "id",
              "type": "integer",
              "index": "primary"
            },
            "timestamps"
          ]
        }
      }
    ]
  },
  "orm": {
    "create_models": [
      {
        "entity": "MODEL_NAME",
        "from_migration_table": "TABLE_NAME"
      }
    ]
  }
}
```

Then you can fill it with your schema setup, for example:

```
{
  "db": {
    "version": 1,
    "migrations": [
      {
        "create_table": {
          "name": "users",
          "columns": [
            {
              "name": "id",
              "type": "integer",
              "index": "primary"
            },
            {
              "name": "username",
              "type": "text"
            },
            {
              "name": "password",
              "type": "text"
            },
            "timestamps"
          ]
        }
      }
    ]
  },
  "orm": {
    "create_models": [
      {
        "entity": "user",
        "from_migration_table": "users"
      }
    ]
  }
}
```

*Further instructions of the schema definition in the [descriptor documentation](DOC_DESCRIPTOR.md)*

## Run craftsman scaffold
After you filled the descriptor you have to run the `flutter pub run craftsman:scaffold` command.

This command will generate some files based on the descriptor file.

If you inserted one or more objects into the **db.migrations** array a **json** file will be generated in the `assets/loquacious/migrations` folder, named as the version you specified in the **db.version** property.

For each object inserted into **orm.create_models** array a model file will be generated into the `lib/models` folder, named as you specified in the **entity** property of the object.

## Start using Loquacious
Now that you have setup all files you can start using Loquacious.

Import Loquacious package in your **main.dart** file:
```
import 'package:loquacious/loquacious.dart';
```

Then before the `runApp(...)` method insert the Loquacious initialization method.

Ensure you call `WidgetsFlutterBinding.ensureInitialized();` in the first line of the `main()` method.
```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Loquacious.init('db_name', 1, useMigrations: true).then((_) {
    runApp(MyApp());
  });
}
```
If you want to run your generated migration set the property `useMigrations` to `true`.

Make sure you set up the correct version of your database (second argument of the init method)

Now you can use **Loquacious** and all it's features

## Using Loquacious Query Builder
Loquacious comes with an handful query builder called `LQB`.

Here is a simple example:
```
final result = await LQB.table('users').where('username', 'foo').get();
```
Here you can find the [full API documentation](DOC_LQB.md)

## Using Loquacious ORM
The real power of Loquacious is the **Object Relational Mapping**.

If you are a **Laravel** developer you certainly know **Eloquent ORM**.

Well, **Loquacious** is very inspired by **Eloquent** and tries to be a lightweight ORM for your Flutter and Sqlite projects.

Some simple examples of the use of **Loquacious ORM**:
```
// create a user
final user = await User.create(username:'jDoe', password:'secret');

// edit created user
user.username = 'johnDoe';
user.password = 'moreSecret';
await user.save();

// fetch all users
final users = await User.all();
```
As you can see the model comes with all the properties you specified into the **descriptor** file.

*It is not recommended to edit the model file directly, instead you should create a new descriptor file and generate a new model with the craftsman scaffold command*

