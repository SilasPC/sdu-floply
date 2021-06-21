
import 'dart:math';
import 'package:flutter/material.dart';
import '../db/Follow.dart';
import '../db/Message.dart';
import '../util/Chat.dart';
import '../util/Msg.dart';
import '../person.dart';
import 'Spin.dart';

/// ListTile for a person that is clickable to open a chat.
/// Used in various places. Shows a bell to follow the person.
class ChatItem extends StatefulWidget {

  /// Build a skeleton version of a ChatItem.
  static Widget buildSkeleton() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: randomBetween(70,130),
          height: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: randomBetween(150, 200),
          height: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  final Chat chat;
  ChatItem(this.chat, [String key = '']) : super(key: Key(chat.receiver.id+key));
  createState() => _State(chat);

}

class _State extends State<ChatItem> {
  
  /// The follow button bell
  bool _showBell = false;
  final Chat chat;

  /// Preview message
  Msg? _msg;
  /// True if there is no message for preview
  bool _noPreview = false;

  _State(this.chat);

  @override
  void initState() {
    super.initState();
    _fetch();
  }
  
  Widget build(BuildContext ctx) {
    Widget listView = ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.person, color: Colors.white)
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${chat.receiver.name} (${chat.receiver.id})',
              style: TextStyle(color: Theme.of(ctx).primaryColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            )
          )
        ],
      ),
      subtitle: _buildPreview(),
      trailing: _buildTrailing()
    );

    return GestureDetector(
      child: listView,
      onTap: () {
        Navigator.push(ctx, MaterialPageRoute(
          builder: (context) => PersonPage(chat))
        );
      }
    );
  }

  /// Trailing buttons
  Widget _buildTrailing() {

    List<Widget> children = [
      Icon(Icons.arrow_forward_ios_rounded)
    ];

    if (_showBell)
      // add follow button
      children.insert(0, IconButton(
        icon: const Icon(Icons.add_alert),
        onPressed: _doFollow,
      ));
    
    return Row(    
      mainAxisSize: MainAxisSize.min,      
      children: children
    );

  }

  Future<void> _doFollow() async {
    var success = await Follow.create(chat.sender.id, chat.receiver.id);
    var text = success
      ? 'Followed ${chat.receiver.id}'
      : 'Could not follow';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text)
      )
    );
    if (mounted && success)
      setState((){
        _showBell = false;
      });
  }

  Widget _buildPreview() {
    if (_msg is Msg)
      return Text(_msg!.preview(), overflow: TextOverflow.ellipsis, maxLines: 1);
    if (_noPreview) return Container();
    return Spin(12, Colors.grey);
  }

  /// Fetch preview message and determine if follow relation already exists
  void _fetch() async {
    var msg = await Message.lastBetween(chat.sender.id, chat.receiver.id);
    var doesFollow = await Follow.checkExists(chat.sender.id, chat.receiver.id);
    if (mounted)
      setState(() {
        _showBell = !doesFollow;
        if (msg is! Message)
          _noPreview = true;
        else
          _msg = Msg.parse(chat.sender.id == msg.sender, msg);
      });
  }

}

double randomBetween(double a, double b) =>
  Random().nextDouble() * (b - a) + a;