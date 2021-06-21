import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'Stamp.dart';
import '../db/db.dart';
import 'package:http/http.dart' as Http;
import 'package:foply/main.dart';
import 'package:flutter/material.dart';

/// Function to determine cursor color in login.dart and signup.dart
/// The original problem was that the cursor color per default is white, causing
///   the cursor to be invisble when using light theme.
Color? cursorColor(ctx) {
  if (MyApp.notifier.value == ThemeMode.system) {
    var brightness = MediaQuery.of(ctx).platformBrightness;

    return brightness == Brightness.dark
        ? Colors.white 
        : Colors.black;
  }
  else {
    return MyApp.notifier.value == ThemeMode.dark
      ? Colors.white 
      : Colors.black;
  }     
}

/// Wrapper for values fetched from the internet.
/// The idea is to use a WebValue<T>? as an indicator for network connectivity.
/// Therefore, a null value indicates no internet connection.
class WebValue<T> {
  final T value;
  WebValue(this.value);
}

/// NOTE: We are aware this is not smart, see evaluation in report.
///
/// Escapes single quotes in input with backslash
/// Crude SQL injection protection, as package `sqflite`
///   does not support arbitrary prepared statements (as far as we can tell).
String escapeSingleQuotes(String input) =>
  input.replaceAllMapped(RegExp("['\\\\]"), (m) => '\\${m[0]}');

/// Class for syncing tables with remote.
/// This is made seperate, as the syncronization code is
///   mostly the same for all three tables.
class TableSyncer {

  /// Refresh lastSync for all instantiated TableSyncers.
  /// Call if, say, all data is wiped.
  static Future<void> refreshAll() async {
    for (var instance in _instances)
      await instance.refresh();
  }

  /// List of instances to refresh with `refreshAll`. 
  static List<TableSyncer> _instances = [];

  /// An ongoing computation.
  Future<void>? _syncFut;
  final String _table;
  final Map<String,String> _params;
  TableSyncer(this._table, this._params) {
    _instances.add(this);
    ready = refresh();
  }

  /// Stamp of last tuple that was syncronized.
  /// Needs to be updated in case data in is changed.
  /// Done via `refresh` or `refreshAll`.
  Stamp lastSync = Stamp.EPOCH;

  late Future<void> ready;
  /// Refresh lastSync, use if manually editing data in table
  Future<void> refresh() async {
    var db = await database;
    var result = await db.rawQuery('SELECT * FROM $_table ORDER BY stamp_unix DESC LIMIT 1;');
    if (result.length == 1)
      lastSync = Stamp.fromIso(result[0]['stamp'] as String? ?? Stamp.EPOCH.iso);
    else
      lastSync = Stamp.EPOCH;
  }

  /// Syncronize with remote server.
  /// If `newSync` is `true`, then a new syncronization is forced,
  /// therefore not relying on an older, in-progress syncronization.
  Future<void> syncTable({bool newSync=false}) async {

    await ready;

    if (newSync) {
      // force a new syncronization instead of reusing an active one

      if (_syncFut is! Future)
        // no sync in progress
        return syncTable();
      
      // await previous sync
      await syncTable();
      // new sync
      return syncTable();
    }

    // reuse old sync
    if (_syncFut is Future)
      return _syncFut!;

    // no sync to reuse
    return _syncFut = _sync()
      .then((maxStamp) {
        // _syncFut cannot have completed before this block returns.
        // therefore, this stack frame "owns" the future stored in _syncFut.

        // as Dart async/await operates in a single thread,
        // the following will appear atomic
        lastSync = maxStamp?.max(lastSync) ?? lastSync;
        _syncFut = null; // this block owns the future
      }).catchError((er) {
        // print('SYNC COMPUTATION FAILED');
        // print(er);
        _syncFut = null;
      });

  }

  /// Syncronize with remote.
  /// Returns the maximum stamp of the retrieved data.
  Future<Stamp?> _sync() async {

    // get from remote
    var res = await Http.get(Uri(
      scheme: 'http',
      host: 'caracal.imada.sdu.dk',
      path: '/app2021/$_table',
      queryParameters: {
        ..._params,
        'stamp': 'gt.${lastSync.iso}',
      }
    ));
    List<dynamic> messages = json.decode(res.body);
      
    var db = await database;
    var batch = db.batch();
    var length = messages.length;
    var maxStamp = length == 0 ? null : Stamp.fromIso(messages[0]['stamp']);

    // insert into local
    for (Map<String,dynamic> msg in messages) {
      var stamp = Stamp.fromIso(msg['stamp']);
      maxStamp = maxStamp!.max(stamp);
      msg['stamp_unix'] = stamp.unix;
      batch.insert(_table, msg, conflictAlgorithm: ConflictAlgorithm.replace);
      // TODO: yield for event loop
    }

    await batch.commit();
    return maxStamp;
  }

}
