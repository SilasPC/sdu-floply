import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'util/Chat.dart';
import 'db/Follow.dart';
import 'package:image_picker/image_picker.dart';
import 'db/User.dart';
import 'package_flutter_chat_bubble/chat_bubble.dart';
import 'package_flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package_flutter_chat_bubble/bubble_type.dart';
import 'common/Spin.dart';
import 'util/Msg.dart';

const padding = 20.0;

/// Page for chatting with another user
class PersonPage extends StatefulWidget {

  final Chat chat;
  PersonPage(this.chat);

  createState() => _State(chat);

}

class _State extends State<PersonPage> {

  /// Seconds between polls
  static final _pollDelay = 5;

  final Chat _chat;
  /// Used for picking/taking images 
  final picker = ImagePicker();

  final textInput = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  /// Map from Msgs to Widgets to avoid rebuilding/reanalyzing large messages
  Map<Msg, Widget> _msgWidgets = {};
  List<Msg> _msgs;

  // no older messages to load
  bool _noMoreOlder = false;
  bool _isLoadingOlder = false;
  // follow button
  bool _showBell = false;

  /// Image to be displayed in fullscreen
  Widget? _fullscreenImage;

  _State(this._chat):
    _msgs = _chat.getMsgs().reversed.toList();

  @override
  void initState() {
    super.initState();
    _startPoll();
    _fetchIsFollowed();
    _scrollCtrl.addListener(() async {
      var offset = _scrollCtrl.offset;
      var max = _scrollCtrl.position.maxScrollExtent;
      if (max - offset < 100)
        _fetchOlder();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollCtrl.dispose();
    textInput.dispose();
  }

  /// Open camera
  void _takePicture(BuildContext ctx) async {
    PickedFile? file;
    try {
      file = await picker.getImage(
        source: ImageSource.camera,
        maxHeight: 500,
        maxWidth: 500
      );
    } catch(e) {
      _showSnackBar(context, 'Could not open camera.');
      // print('FAILED TO OPEN CAMERA');
      // print(e);
    }

    if (file == null) return;
    await _useImage(ctx, File(file.path));
    await scrollDown();
  }

  /// Choose image from gallery
  void _pickImage(BuildContext ctx) async {
    PickedFile? file;
    try {
      file = await picker.getImage(
        source: ImageSource.gallery,
        maxHeight: 500,
        maxWidth: 500
      );
    } catch(e) {
      _showSnackBar(context, 'Could not open gallery.');
      // print('FAILED TO CHOOSE IMAGE');
      // print(e);
    }

    if (file == null) return;
    await _useImage(ctx, File(file.path));
    await scrollDown();
  }

  /// Process image and send.
  Future<void> _useImage(BuildContext ctx, File image) async {
    // this should probably run in an isolate instead
    List<int> imageBytes = await image.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    var msg = MsgPart.base64Image(base64Image);
    if (!await _chat.send([msg])) {
      _showSnackBar(ctx, 'Could not send image');
      return;
    }
    setState((){
      _msgs = _chat.getMsgs().reversed.toList();
    });
  }

  /// Send a plain text message to the recipient.
  Future<void> _sendText() async {
    String text = textInput.text.trim();
    textInput.clear();

    if (text.length == 0)
      return;

    if (!await _chat.send([MsgPart.text(text)])) {
      _showSnackBar(context, 'Could not send message');
      return;
    }
    setState((){
      _msgs = _chat.getMsgs().reversed.toList();
    });
    await scrollDown();
  }

  /// Fetch whether or not the user follows the recipient.
  void _fetchIsFollowed() async {
    if (!await Follow.checkExists(_chat.sender.id, _chat.receiver.id)) {
      if (mounted)
        setState((){
          _showBell = true;
        });
    }
  }

  /// Scroll down to the bottom of the chat screen.
  Future<void> scrollDown() async {
    await _scrollCtrl.animateTo(
      _scrollCtrl.position.minScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
            margin: EdgeInsets.all(6),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.person, color: Colors.white)
            ),
          ),
        title: Text(this._chat.receiver.name),
        actions: _buildActions()
      ),
      body: _buildBody(context)
      // bottomNavigationBar: TextField(),
    );
  }

  /// Build the top bar action icons.
  List<Widget> _buildActions() {
    if (!_showBell) return [];
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.add_alert),
        onPressed: () async {
          var success = await Follow.create(_chat.sender.id, _chat.receiver.id);
          var text = success
            ? 'Followed ${_chat.receiver.id}'
            : 'Could not follow';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text)
            )
          );
          if (success && mounted)
            setState((){
              _showBell = false;
            });
        }
      )
    ];
  }

  /// Build the message content
  Widget _buildBody(BuildContext context) {
    List<Widget> msgs = _msgs.map(
        (msg) => msg.outgoing
          ? _createOwnBubble(context, msg)
          : _createBubble(context, msg)
      ).toList(growable: true);

    if (_isLoadingOlder)
      msgs.add(Spin(40));

    var stack = <Widget>[
      ListView(
        controller: _scrollCtrl,
        reverse: true,
        padding: EdgeInsets.only(bottom: 10), // padding down to text input
        children: msgs
      )
    ];
    if (_fullscreenImage is Widget)
      stack.add(GestureDetector(
        child: Center(
          child: _fullscreenImage,
        ),
        onTap: () {
          setState((){
            _fullscreenImage = null;
          });
        }
      ));
    var stackWidget = Stack(children: stack);
    var inputBar = _buildInputBar(context);
    return Column(
      children: [
        Expanded(
          child: stackWidget
        ),
        inputBar
      ],
    );
  }

  /// Build the bottom input bar.
  /// Taken and modified from https://github.com/abuanwar072/Chat-Messaging-App-Light-and-Dark-Theme
  Widget _buildInputBar(ctx) =>
    Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    SizedBox(width: padding / 4),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        maxLines: 4,
                        minLines: 1,
                        controller: textInput,
                        decoration: InputDecoration(
                          hintText: "Aa",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickImage(context),
                      child: Container(
                        padding: EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(border: 
                          Border(left: BorderSide(
                            color: Colors.black.withOpacity(0.3)
                            )
                          )
                        ),
                        child: Icon(
                          Icons.attach_file,
                            color: Colors.black
                              .withOpacity(0.64),
                        ),
                      ),
                    ),                 
                    SizedBox(width: padding / 4),
                    GestureDetector(
                      onTap: () => _takePicture(context),
                      child: Container(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.black
                            .withOpacity(0.64),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: padding),
            GestureDetector(
              onTap: _sendText,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.send, color: Colors.white, size: 18, ),
              ),
            ),
          ],
        ),
      ),
    );

  /// Build a chat bubble shown as sent to the recipient.
  Widget _createOwnBubble(BuildContext ctx, Msg msg) => ChatBubble(
    clipper: ChatBubbleClipper5(type: BubbleType.sendBubble),
    alignment: Alignment.topRight,
    margin: EdgeInsets.only(top: 20, right: 8),
    backGroundColor: Theme.of(context).primaryColor,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(ctx).size.width * 0.7,
      ),
      child: _buildMsg(ctx, msg),
    )
  );

  /// Build a chat bubble shown as received from the recipient.
  Widget _createBubble(BuildContext ctx, Msg msg) => ChatBubble(
    clipper: ChatBubbleClipper5(type: BubbleType.receiverBubble),
    margin: EdgeInsets.only(top: 20, left: 8),
    backGroundColor: Theme.of(context).accentColor,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(ctx).size.width * 0.7,
      ),
      child: _buildMsg(ctx, msg),
    )
  );

  /// Build the actual content of a message bubble given a Msg.
  Widget _buildMsg(BuildContext ctx, Msg msg) {
    {
      // avoid rebuilding if possible
      Widget? widget = _msgWidgets[msg];
      if (widget is Widget)
        return widget;
    }
    if (_msgWidgets.containsKey(msg))
      return _msgWidgets[msg]!;
    var children = msg.parts.map((p) {
        var body = p.body;
        switch (p.type) {
          case 'TXT':
            return Text(
              body,
              style: TextStyle(color: Colors.white)
            );
          case 'IMG':
            return _buildImageB64(body);
          case 'IMGURL':
            return _wrapImage(Image.network(body));
          case 'USER':
            return _PersonLink(
              body,
              (user) => _navigatePerson(ctx, user),
            );
          case 'LATLNG':
            return GestureDetector(
              onTap: () => _launchGeo(body),
              child: Text(
                body,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                )
              ),
            );
          default:
            return Text('?? (${p.type})');
        }
      }).toList();
    // save widget for reuse
    return _msgWidgets[msg] = Column(
      children: children
    );
  }

  /// Build an Image Widget from a base64 string
  Widget _buildImageB64(String b64) {
    Uint8List bytes = base64Decode(b64);
    return _wrapImage(Image.memory(bytes));
  }

  /// Wraps an image so it can be displayed in fullscreen
  Widget _wrapImage(Image img) {
    return GestureDetector(
      child: Container(
        child: FractionallySizedBox(
          widthFactor: 0.7,
          child: img
        ),
        margin: EdgeInsets.symmetric(vertical: 8),
      ),
      onTap: () {
        setState((){
          _fullscreenImage = img;
        });
      }
    );
  }

  /// Fetch older messages (if any)
  Future<void> _fetchOlder() async {
    if (_noMoreOlder)
      return;
    setState((){_isLoadingOlder = true;});
    if (await _chat.fetchOlder() == 0)
      _noMoreOlder = true;
    // await Future.delayed(Duration(milliseconds:300));
    setState((){
      _isLoadingOlder = false;
      _msgs = _chat.getMsgs().reversed.toList();
    });
  }

  /// Polling loop. Stops when unmounted.
  Future<void> _startPoll() async {
    while (mounted) {
      await _fetch();
      await Future.delayed(Duration(seconds:_pollDelay));
    }
  }

  /// Fetch newer messages
  Future<void> _fetch() async {
    await _chat.fetchNewer();
    if (mounted && _msgs.length != _chat.msgCount())
      setState((){
        _msgs = _chat.getMsgs().reversed.toList();
      });
  }

  /// Opens a chat with `user`
  void _navigatePerson(BuildContext ctx, User? user) {
    if (user is User)
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (ctx) => PersonPage(
            Chat(_chat.sender, user)
          )
        )
      );
  }

  /// Open geographical app (eg. Google Maps).
  /// Fallback to google maps in webbrowser.
  void _launchGeo(String latlng) async {
    var geo = 'geo:$latlng';
    if (await canLaunch(geo))
      await launch(geo);
    else {
      var google = 'https://www.google.com/maps/search/?api=1&query=$latlng';
      if (await canLaunch(google))
        await launch(google);
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 2),
      )
    );
  }

}

/// An inline text link, that loads a users name.
class _PersonLink extends StatefulWidget {
  final String userId;
  final void Function(User?) onClick;
  const _PersonLink(this.userId, this.onClick, {Key? key}): super(key:key);
  createState() => _PState(userId, onClick);
}
class _PState extends State<_PersonLink> {
  
  final String userId;
  User? _user;
  final void Function(User?) onClick;

  _PState(this.userId, this.onClick);
  
  @override
  initState() {
    super.initState();
    _fetch();
  }

  Widget build(BuildContext ctx) =>
    GestureDetector(
      child: Text(
        userId + _buildName(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white
        )  
      ),
      onTap: () => onClick(_user)
    );


  String _buildName() {
    if (_user is User)
      return ' (${_user!.name})';
    return '';
  }

  void _fetch() async {
    var user = await User.byId(userId);
    if (user is User)
      setState((){
          _user = user;
      });
  }

}