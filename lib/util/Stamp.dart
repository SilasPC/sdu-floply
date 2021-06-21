
import 'package:flutter/cupertino.dart';

/// Class representing a timestamp, represented in both UNIX and ISO format.
/// The main motivation, is being able to quickly compare the ISO stamps
/// used by PostgreSQL, as well as helping to interact with the PostgREST API.
@immutable
class Stamp {

  /// Get the latest of the Stamps `this` and `other`
  max(Stamp other) {
    if (unix < other.unix)
      return other;
    return this;
  }
  /// Get the earliest of the Stamps `this` and `other`
  min(Stamp other) {
    if (unix > other.unix)
      return other;
    return this;
  }

  /// UNIX epoch/zero-point
  static const EPOCH = Stamp._('1970-01-01T00:00:00.00Z', 0); //! FORMAT CORRECT?

  /// The ISO format of the timestamp
  final String iso;
  /// The UNIX milliseconds format of the timestamp
  final int unix;

  const Stamp._(this.iso, this.unix);

  /// Create Stamp from ISO datetime string
  factory Stamp.fromIso(String iso) =>
    Stamp._(iso, DateTime.parse(iso).millisecondsSinceEpoch);

  /// Create a stamp a map containing ISO string on key 'stamp'
  factory Stamp.fromMap(Map<String, dynamic> map) {
    return Stamp.fromIso(map['stamp']);
  }

  // Overload equality operator
  @override
  bool operator ==(Object other) => other is Stamp && other.iso == iso;
  @override
  int get hashCode => iso.hashCode;

}