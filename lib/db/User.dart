
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'db.dart';
import 'package:http/http.dart' as Http;
import '../util/Stamp.dart';
import '../util/util.dart';

final uri = Uri(scheme: 'http', host: 'caracal.imada.sdu.dk', path: '/app2021/users');

/// Represents a user in the database.
@immutable
class User {

  final String id;
  final String name;
  final Stamp stamp;

  static final _table = TableSyncer('users', {
    'name': 'not.is.null'
  });
  static Future<void> syncTable() async {
    await _table.syncTable();
  }

  const User(this.id, this.name, this.stamp);
  User.fromMap(Map<String, dynamic> map) :
    id = map['id'],
    name = map['name'],
    stamp = Stamp.fromIso(map['stamp']);


  /// Create a new user. Returns null on id-conflict, no internet, etc.
  static Future<WebValue<User?>?> create(String id, String name) async {
    try {
      var res = await Http.post(
        uri,
        headers: headers,
        body: json.encode({
          'id': id,
          'name': name
        }));

      if (res.statusCode != 201) // 201 Created
        return WebValue(null);

      await _table.syncTable(newSync: true);

      // return=representation gives response like [{"id":"xxx",...}]
      return WebValue(User.fromMap(json.decode(res.body)[0]));

    } catch(e) {
      // print('FAILED TO CREATE USER');
      // print(e);
      return null;
    }
    
  }

  /// Search for users matching the given string.
  /// More specifically, find users whose name or id contain the given
  /// search string (ignoring case).
  static Future<List<User>> search(String search) async {
    // `search` pattern is escaped by '!' character.
    // '%' is placed in both ends to match `search` in any position.
    
    search = search.replaceAllMapped(RegExp(r'[%_!]'), (m) => '!${m[0]}');
    search = '%$search%';
    var db = await database;
    await syncTable();
    var results = await db.query('users',
      where: "name LIKE ? ESCAPE '!' OR id LIKE ? ESCAPE '!'",
      whereArgs: [search, search],
      orderBy: 'name'
    );
    return results.map((m) => User.fromMap(m)).toList();
  }

  /// Attempt to find a user with an exact matching id.
  static Future<User?> byId(String id) async {
    var db = await database;
    await syncTable();
    var results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.length == 1)
      return User.fromMap(results[0]);
    return null;
  }

  // Overload equality operator
  @override
  bool operator ==(Object other) => other is User && other.id == id;
  @override
  int get hashCode => id.hashCode;

  /// Debugging toString method
  String toString() => 'User { "$id", "$name" }';

}
