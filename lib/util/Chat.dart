
import 'Msg.dart';
import 'util.dart';
import 'package:synchronized/synchronized.dart';
import 'Stamp.dart';
import '../db/Message.dart';
import '../db/User.dart';

/// Represents an active chat between `sender` and `receiver`.
class Chat {

  /// Data is syncronized on this lock to ensure no overlapping
  /// async calls affect data in an unintended way.
  final lock = Lock();

  final User sender;
  final User receiver;

  Chat(this.sender, this.receiver);

  List<Msg> _msgs = [];
  Stamp? _newest;
  Stamp? _oldest;

  /// Get a copy of the list of messages
  List<Msg> getMsgs() => [..._msgs];
  /// Get the number of messages loaded
  int msgCount() => _msgs.length;

  /// Load more older messages.
  /// Returns the number of messages loaded.
  Future<int> fetchOlder() async {
    var gotten = 0;
    await lock.synchronized(() async {
      if (_msgs.length == 0) return _fetchRecent();
      var data = _parse(await Message.before(sender.id, receiver.id, 20, _oldest!.unix));
      gotten = data.length;
      data.addAll(_msgs);
      _msgs = data;
      if (gotten > 0)
        _oldest = data.first.stamp;
    });
    return gotten;
  }

  /// Load more newer messages.
  /// Returns the number of messages loaded.
  Future<int> fetchNewer() async {
    var gotten = 0;
    await lock.synchronized(() async {
      if (_msgs.length == 0) return _fetchRecent();
      var data = _parse(await Message.after(sender.id, receiver.id, _newest!.unix));
      gotten = data.length;
      _msgs.addAll(data);
      if (gotten > 0)
        _newest = data.last.stamp;
    });
    return gotten;
  }

  /// Should only be called when `msgs.length == 0`
  Future<int> _fetchRecent() async {
    _msgs = _parse(await Message.recentBetween(sender.id, receiver.id, 20));
    if (_msgs.length > 0) {
      _newest = _msgs.last.stamp;
      _oldest = _msgs.first.stamp;
    }
    return _msgs.length;
  }

  /// Send a message, returns true on success.
  /// If successfull, message will have been loaded into the
  /// message list, and can be retrieved with `getMsgs()`.
  Future<bool> send(List<MsgPart> parts) async {
    var body = '@[${parts.join(',')}]';

    var msg = await Message.create(sender.id, receiver.id, body);
    if (msg is! WebValue)
      return false;
    await fetchNewer();
    return true;
  }

  /// Convenience method.
  List<Msg> _parse(Iterable<Message> it)
    => it.map((m) => Msg.parse(m.sender == sender.id, m)).toList();

}
