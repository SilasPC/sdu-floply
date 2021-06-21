import 'package:flutter/material.dart';
import 'package:foply/profile.dart';
import 'db/User.dart'; 
import 'package:foply/chats.dart';
import 'package:foply/settings.dart';

/// Tabs view
class TabsView extends StatelessWidget {
  
  /// The user that is signed in
  final User _user;

  const TabsView(this._user);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        bottomNavigationBar: TabBar(
          labelColor: Theme.of(context).primaryColor,
           indicator: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).primaryColor, 
                  width: 5
              )
            ),
          ),
          labelPadding: EdgeInsets.only(top: 10),
            tabs: [
              Tab(icon: Icon(Icons.message_outlined), text: "Messages"),
              Tab(icon: Icon(Icons.person_sharp), text: "Profile"),
              Tab(icon: Icon(Icons.settings), text: "Settings"),
            ],
          ),
        body: TabBarView(
          children: [
            ChatPage(_user),
            Profile(_user),
            Settings(),
          ],
        ),
      ),
    );
  }
}