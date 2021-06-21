import 'package:sqflite/sqflite.dart';

/// Headers for remote database queries.
final headers = {
  'prefer': 'return=representation',
  'Authorization': 'Bearer XYZ',
  'Content-Type': 'application/json',
  'Accept': 'application/json'
};

/// The local database instance.
/// Use with async/await to get instance.
final Future<Database> database = _createDatabase();

/// Deletes all local data.
/// Used for debugging (and removing broken messages sent by other groups).
Future<void> clearLocalDatabase() async {
  var db = await database;
  var batch = db.batch();
  batch.delete('users');
  batch.delete('follows');
  batch.delete('messages');
  await batch.commit();
  // print('!!! CLEARED LOCAL DATABASE !!!');
}

/// Setup and initialize database.
/// Only called once.
Future<Database> _createDatabase() async {
  var db = await openDatabase('local_data.db');
  var batch = db.batch();
  batch.execute('''
    CREATE TABLE
      IF NOT EXISTS
      users (
        id TEXT
          PRIMARY KEY,
        name TEXT
          NOT NULL,
        stamp TEXT
          NOT NULL,
        stamp_unix INT
          NOT NULL
      );
  ''');
  batch.execute('''
    CREATE TABLE
      IF NOT EXISTS
      follows (
        followee TEXT
          NOT NULL,
        follower TEXT
          NOT NULL,
        stamp TEXT
          NOT NULL,
        stamp_unix INT
          NOT NULL,
        
        PRIMARY KEY(followee, follower)
      );
  ''');
  batch.execute('''
    CREATE TABLE
      IF NOT EXISTS
      messages (
        id INTEGER
          PRIMARY KEY,
        sender TEXT
          NOT NULL,
        receiver TEXT
          NOT NULL,
        body TEXT
          NOT NULL,
        stamp TEXT
          NOT NULL,
        stamp_unix INT
          NOT NULL
      );
  ''');
  batch.execute('''
    CREATE INDEX
      IF NOT EXISTS
      messages_stamp
      ON messages (stamp_unix);
  ''');
  await batch.commit();
  return db;
}
