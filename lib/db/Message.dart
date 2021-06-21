
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../util/Stamp.dart';
import '../db/db.dart';
import '../util/util.dart';
import 'package:http/http.dart' as Http;
import 'User.dart';

final uri = Uri(
  scheme: 'http',
  host: 'caracal.imada.sdu.dk',
  path: '/app2021/messages'
);

/// Represents a message in the database.
@immutable
class Message {

  final int id;
  final String sender;
  final String receiver;
  final String body;
  final Stamp stamp;

  static final _table = TableSyncer('messages', {
    'sender': 'not.is.null',
    'receiver': 'not.is.null',
    'body': 'not.is.null'
  });
  static Future<void> syncTable() async {
    await _table.syncTable();
  }

  Message._fromMap(Map<String, dynamic> map) :
    id = map['id'],
    sender = map['sender'],
    receiver = map['receiver'],
    body = map['body'],
    stamp = Stamp.fromIso(map['stamp']);

  /// Create a Message by uploading to the remote database,
  ///   and syncing with local.
  static Future<WebValue<Message>?> create(String sender, String receiver, String body) async {
    try {
      var res = await Http.post(
        uri,
        headers: headers,
        body: json.encode({
          'sender': sender,
          'receiver': receiver,
          'body': body
        }));
      await _table.syncTable(newSync: true);

      return WebValue(Message._fromMap(json.decode(res.body)[0]));

    } catch(e) {
      // print('FAILED TO CREATE MESSAGE');
      // print(e);
      return null;
    }
  }

  /// Get all messages after the given time `after` between the two users.
  static Future<List<Message>> after(String u1, String u2, int after) async {
    var db = await database;
    await syncTable();
    var results = await db.query('messages', where:
      'stamp_unix > ? AND ((sender = ? AND receiver = ?) OR (receiver = ? AND sender = ?))',
      whereArgs: [after, u1, u2, u1, u2],
      orderBy: 'stamp ASC'
    );
    return results.map((m) => Message._fromMap(m)).toList();
  }

  /// Get `limit` messages before the given time `before` between the two users.
  static Future<List<Message>> before(String u1, String u2, int limit, int before) async {
    var db = await database;
    await syncTable();
    var results = await db.query('messages', where:
      'stamp_unix < ? AND ((sender = ? AND receiver = ?) OR (receiver = ? AND sender = ?))',
      whereArgs: [before, u1, u2, u1, u2],
      orderBy: 'stamp DESC',
      limit: limit
    );
    return results.reversed.map((m) => Message._fromMap(m)).toList();
  }

  /// Get the most recent `limit` messages between the two users.
  static Future<List<Message>> recentBetween(String u1, String u2, int limit) async {
    var db = await database;
    await syncTable();
    var results = await db.query('messages', where:
      '((sender = ? AND receiver = ?) OR (receiver = ? AND sender = ?))',
      whereArgs: [u1, u2, u1, u2],
      orderBy: 'stamp DESC',
      limit: limit
    );
    return results.reversed.map((m) => Message._fromMap(m)).toList();
  }

  /// Get the latest message between the two users.
  static Future<Message?> lastBetween(String u1, String u2) async {
    return recentBetween(u1, u2, 1)
      .then((r) => r.length > 0 ? r[0] : null);
  }

  /// Get a list of users that the given user has messages to/from.
  /// Result contains a User and a Stamp of the last message.
  static Future<List<UserWithLastMessageStamp>> chatsWith(User user) async {
    var db = await database;
    await syncTable();
    /// TODO use prepared statements
    /// NOTE sqflite does not have this (?!)
    var id = escapeSingleQuotes(user.id);
    var results = await db.rawQuery('''
      SELECT * FROM (
        SELECT id, stamp as last_stamp FROM (
          SELECT receiver AS id, stamp
            FROM messages
            WHERE sender = '$id'
          UNION
          SELECT sender AS id, stamp
            FROM messages
            WHERE receiver = '$id'
        )
          GROUP BY id
          ORDER BY MAX(stamp) DESC
      ) NATURAL JOIN users;
    ''');
    return results.map((m) =>
      UserWithLastMessageStamp(
        User.fromMap(m),
        Stamp.fromIso(m['last_stamp'] as String)
      )).toList();
  }

}

/// Result wrapper containing a User with a Stamp of the last message.
/// Useful to determine if a new message has arrived.
@immutable
class UserWithLastMessageStamp {
  final User user;
  final Stamp stamp;
  UserWithLastMessageStamp(this.user, this.stamp);

  // Overload equality operator
  @override
  bool operator ==(Object other) =>
    other is UserWithLastMessageStamp &&
    other.user == user &&
    other.stamp == stamp;
  @override
  int get hashCode => user.hashCode + stamp.hashCode;
}