import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foply/db/User.dart';
import 'package:foply/db/db.dart';
import 'package:http/http.dart' as Http;
import '../util/util.dart';
import 'dart:convert';

final uri = Uri(scheme: 'http', host: 'caracal.imada.sdu.dk', path: '/app2021/follows');

/// Represents a follow in the database.
/// This is only used as a static class,
/// as `follows` acts mostly as a join table.
@immutable
class Follow {
  
  static final _table = TableSyncer('follows', {
    'followee': 'not.is.null',
    'follower': 'not.is.null',
  });
  static Future<void> syncTable() async {
    await _table.syncTable();
  }

  /// Check if a given follows relation exists:
  /// does `follower` follow `followee`?
  static Future<bool> checkExists(String follower, String followee) async {
    var db = await database;
    await _table.syncTable();
    var result = await db.query('follows', where: 'follower = ? AND followee = ?',
      whereArgs: [follower, followee]);
    return result.length > 0;
  }

  /// Make `follower` follow `followee`.
  /// Returns true on success.
  static Future<bool> create(String follower, String followee) async {
    try {
      await Http.post(
        uri,
        headers: headers, //? conflict = ignore
        body: json.encode({
          'follower': follower,
          'followee': followee
        }));
      
      await _table.syncTable(newSync: true);
      
      return true;
    } catch(e) {
      // print('FAILED CREATE FOLLOW');
      // print(e);
      return false;
    }
  }

  /// Get the followers of a given user.
  static Future<List<User>> getFollowers(String id) async {
    var db = await database;
    await syncTable();
    //! TODO proper escaping
    var results = await db.rawQuery('''
      SELECT id, name, users.stamp
        FROM follows
        JOIN users ON id = follower
        WHERE followee = '${escapeSingleQuotes(id)}'
      ''');
    return results.map((m) => User.fromMap(m)).toList();
  }

  /// Get the followees of a given user.
  static Future<List<User>> getFollowees(String id) async {
    var db = await database;
    await syncTable();
    //! TODO Same issue as above
    var results = await db.rawQuery('''
      SELECT id, name, users.stamp
        FROM follows
        JOIN users ON id = followee
        WHERE follower = '${escapeSingleQuotes(id)}'
      ''');
    return results.map((m) => User.fromMap(m)).toList();
  }

}
