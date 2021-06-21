
import 'package:flutter/material.dart';
import 'dart:convert';
import '../db/Message.dart';
import 'Stamp.dart';

/// Partial message content
class MsgPart {

  final String type;
  final String body;

  MsgPart.raw(this.type, this.body);

  MsgPart.fromMap(Map<String,dynamic> map) :
    type = map['type'],
    body = map['body'];

  MsgPart.text(this.body) :
    type = 'TXT';

  MsgPart.base64Image(this.body) :
    type = 'IMG';

  /// JSON encode
  String toString() {
    return json.encode({
      'type': type,
      'body': body
    });
  }

}

/// Representation of a complete, displayable chat message
@immutable
class Msg {

  final int id;
  final bool outgoing;
  final List<MsgPart> parts;
  final Stamp stamp;
  const Msg._(this.id, this.outgoing, this.parts, this.stamp);

  /// Parse a raw message tuple into a formatted `Msg`.
  factory Msg.parse(bool outgoing, Message msg) {
    final body = msg.body;
    
    // Normal message
    if (
      body.length == 0 ||
      body[0] != '@'
    ) return Msg._(
      msg.id,
      outgoing,
      [MsgPart.text(body)],
      msg.stamp
    );

    // Normal message with escaped '@'
    if (body[1] == '@')
      return Msg._(
        msg.id,
        outgoing,
        [MsgPart.text(body.substring(1))],
        msg.stamp
      );

    // Custom message (old format, hopefully)
    if (body[1] != '[') {
      var i = body.indexOf(' ');
      var tag = body.substring(1, i);
      var data = body.substring(i+1);
      // Really we should check if this is actually valid
      // However, it is not catastrophic, and I am not cleaning others mess up.
      return Msg._(
        msg.id,
        outgoing,
        [MsgPart.raw(tag, data)],
        msg.stamp
      );
    }

    // Custom message (new format)
    late List<dynamic> parts;
    parts = json.decode(body.substring(1));
    return Msg._(
      msg.id,
      outgoing,
      parts.map((p) => MsgPart.fromMap(p)).toList(),
      msg.stamp
    );
  }

  /// Returns a textual preview of the message.
  String preview() {
    if (parts.length == 0) return '';
    var prefix = outgoing ? 'You: ' : '';
    var p = parts[0];
    if (p.type == 'TXT') return prefix + p.body + (parts.length > 1 ? ' ...' : '');
    return '$prefix...';
  }

  /// Debugging implementation
  String toString() =>
    'Msg { ${stamp.iso} }';

}