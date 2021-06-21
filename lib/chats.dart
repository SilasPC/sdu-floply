import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'common/ChatItem.dart';
import 'db/Message.dart';
import 'util/Chat.dart';
import 'db/User.dart';

/// Front page with list of active message threads
class ChatPage extends StatefulWidget {

  final User _user;
  const ChatPage(this._user);
  @override
  createState() => _State(_user);

}

/// AutomaticKeepAliveClientMixin ensures that page is not rebuilt when switching tabs.
class _State extends State<ChatPage> with AutomaticKeepAliveClientMixin<ChatPage> {

  @override
  bool get wantKeepAlive => true;

  User _user;
  
  List<UserWithLastMessageStamp> _users = [];
  bool _hasLoaded = false;

  bool _isSearching = false;
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Messages');
  List<User> _searchResult = [];

  _State(this._user);

  @override
  void initState() {
    super.initState();
    _startPoll();
  }

  Future<void> _refresh(ctx) async {
    ScaffoldMessenger
      .of(ctx)
      .showSnackBar(
        SnackBar(
          content: Text("Reloading page content."),
          duration: Duration(seconds: 2),
        )
      );
    setState((){_hasLoaded = true;});
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    var users = await Message.chatsWith(_user);
    if (mounted) setState((){
      _users = users;
      _hasLoaded = true;
    });
  }

  /// Poll loop. Runs until page is unmounted.
  _startPoll() async {
    while (mounted) {
      var users = await Message.chatsWith(_user);
      setState((){
        _hasLoaded = true;
        if (users.hashCode != _users.hashCode)
          _users = users;
      });
      await Future.delayed(Duration(seconds: 10));
      await Message.syncTable();
    }
  }

  /// https://medium.com/codechai/a-simple-search-bar-in-flutter-f99aed68f523
  void _searchPressed() {
    setState(() {
      if (_searchIcon.icon == Icons.search) {
        // on search pressed
        _searchIcon = new Icon(Icons.close);
        _appBarTitle = new TextField(
          style: TextStyle(color: Colors.white),
          autofocus: true,
          decoration: new InputDecoration(
            border: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).accentColor,
                width: 2
              )
            ),
            prefixIcon: new Icon(Icons.search, color: Colors.white70),
            hintText: ' Search...',
          ),
          onChanged: _onSearchChanged,
        );
      } else {
        // on close pressed
        _searchIcon = new Icon(Icons.search);
        _appBarTitle = new Text('Messages');
        // filteredNames = names;
        _isSearching = false;
      }
    });
  }

  void _onSearchChanged(String text) async {
    setState((){
      _isSearching = text.isNotEmpty;
    });
    if (text.isNotEmpty) {
      // setState((){_searchIsLoading = true;});
      await User.syncTable();
      var users = await User.search(text);
      setState((){
        // _searchIsLoading = false;
        _searchResult = users;
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    super.build(ctx); // needed for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.transparent,
        leading: GestureDetector(
          child: Container(
            margin: EdgeInsets.all(6),
            child: _searchIcon
          ),
          onTap: _searchPressed,
        ),
        title: _appBarTitle,
        actions: [ 
          IconButton(
            padding: EdgeInsets.all(15),
            icon: Icon(Icons.refresh),
            onPressed: () => _refresh(ctx),
          )
        ],
      ),
      body: _buildBody()
    );
  }

  /// Builds the body of the page: the items to be displayed
  Widget _buildBody() {

    if (!_hasLoaded) {
      // skeleton preview

      List<Widget> items = [];

      for (int x = 0; x < 10; x++) {
        items.add(ChatItem.buildSkeleton());
        if (x < 9) items.add(Divider());
      }

      return ListView(
        key: Key('preview_view'),
        physics: BouncingScrollPhysics(),
        children: items
      );
    }

    if (!_isSearching) {
      // chat view

      if (_users.length == 0)
        return Container(
          alignment: Alignment.center,
          child: Text("You have no friends."),
        );
      
      return ListView.separated(
        key: Key('chat_view'),
        physics: BouncingScrollPhysics(),
        itemCount: _users.length,
        separatorBuilder: (ctx, i) => Divider(),
        itemBuilder: (ctx, i) => ChatItem(Chat(_user, _users[i].user), _users[i].stamp.iso)
      );

    }

    if (_searchResult.length == 0) {
      return Container(
        alignment: Alignment.center,
        child: Text("You found no friends."),
      );
    }

    return ListView.separated(
      // New key for every returned result, else flutter cannot update correctly.
      // If two search results have same length, it is assumed that they are equal.
      key: Key('${_searchResult.length}'),
      physics: BouncingScrollPhysics(),
      itemCount: _searchResult.length,
      separatorBuilder: (ctx, i) => Divider(),
      itemBuilder: (ctx, i) => ChatItem(Chat(_user, _searchResult[i]))
    );

  }

}
