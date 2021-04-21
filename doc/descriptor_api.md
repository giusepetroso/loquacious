# DESCRIPTOR FILE DOCUMENTATION

## Introduction
The descriptor is a **json** file that contains some **actions** which the `craftsman:scaffold` command will execute.

The main purposes of the file are to describe **migrations** and **models**.

## Descriptor root
```
{
    "db": {
        "version": 1, 
        "migrations": [
            ... 
        ]
    },
    "orm": {
        ...
    }
}
```
The root of the file is composed by two main properties **db** and **orm**.
- **db**: is the part that contains informations about database, as version and migrations. Version property set the migration file name. Migrations property contains an array of objects that describes the details of a migration
- **orm**: is the part that contains informations about the models generation 

## Migrations property (db)
Here's the basic example of a migration
```
...
"migrations": [
    // MIGRATION OBJECT
    {   
        "create_table": {   // ACTION
            "name": "users",
            "columns": [
                {
                    "name": "id",
                    "type": "integer",
                    "index": "primary"
                },
                {
                    "name": "username",
                    "type": "string"
                },
                "timestamps"
            ]
        }
    }
    // END MIGRATION OBJECT
    ... OTHER MIGRATIONS
]
...
```
Every migration object must have a property, whose name indicates a specific action and value contains data required for the action.

### Available actions:  
### **create_table** 
The create_table action will generate a table creation query.
