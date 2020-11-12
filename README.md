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
dependencies:
  ...
  loquacious: ^0.0.1

dev_dependencies:
  ...
  craftsman: ^0.0.1
```

## Documentation index
1. [Use craftsman](#use-craftsman)
2. [Generate your first 'descriptor' file with craftsman](#generate-your-first-descriptor-file-with-craftsman)
3. 


## Use craftsman
[Craftsman](https://pub.dev/packages/craftsman) package is the Loquacious tool for files generation and scaffolding

Craftsman is not required but highly recommended since it helps you to scaffold complex generated files

For example using ORM feature require model classes generation, that will be very tedious and prone to errors task, but with Craftsman you can make it very simple and straightforward

## Generate your first 'descriptor' file with craftsman
Run the command `flutter pub run craftsman:descriptor` and follow the console instruction for generating a descriptor file

The descriptor file defines two different scaffolding instruction type:
- **database** type, for the migration file generation
- **orm** type, for models generation

After descriptor generation you should have a **json** file in `craftsman/descriptor` named as the version you input which is a template like this:

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
    "models": [
      {
        "name": "MODEL_NAME",
        "of_table": "TABLE_NAME"
      }
    ]
  }
}
```

### DB section
The **db** section contains database description for the selected version

The most important part of **db** section is the **migrations** array, where you can define your table schemas

Further instructions of the schema definition [here](DESCRIPTOR_DOCUMENTATION.md/#database-section)
