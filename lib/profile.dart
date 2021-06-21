import 'package:flutter/material.dart';
import 'package:foply/db/Follow.dart';
import 'common/ChatItem.dart';
import 'db/User.dart';
import 'util/Chat.dart';

// Our inspiration on how to structure the profile page:
// https://stackoverflow.com/a/63751948/12424498

/// Page showing the users own profile
class Profile extends StatefulWidget {
  final User user;
  Profile(this.user);
  createState() => _State(user);
}

class _State extends State<Profile> {

  final User user;

  List<User>? followers;
  List<User>? followees;

  _State(this.user) {
    _fetch();
  }

  /// Get follower information
  Future<void> _fetch() async {
    var _followers = await Follow.getFollowers(user.id);
    var _followees = await Follow.getFollowees(user.id);
    if (mounted)
      setState((){
        followees = _followees;
        followers = _followers;
      });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                floating: true,
                pinned: true,
                bottom: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color:Theme.of(context).accentColor
                  ),
                  tabs: [
                    Tab(text: 'Followers${numStr(followers?.length)}'),
                    Tab(text: 'Followees${numStr(followees?.length)}'),
                  ],
                ),
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Scaffold(
                  backgroundColor: Theme.of(context).primaryColor,
                    body: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Container(
                              height: 200.0,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage("https://static.vecteezy.com/system/resources/previews/000/598/570/non_2x/abstract-colorful-retro-low-poly-vector-background-with-warm-gradient-futuristic-pattern.jpg")
                                )
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 110,
                          left: 20,
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundImage: NetworkImage("https://berlingske.bmcdn.dk/media/cache/resolve/image_x_large/image/33/337569/4730918-pix-legomand.jpg"),
                          ),
                        ),
                        Positioned(
                          top: 220,
                          left: 185,
                          child: Container(
                            width: 195, 
                            child: FittedBox(
                              alignment: Alignment.center,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${user.name}', 
                                style: TextStyle(fontSize: 20, color: Colors.white)
                              )
                            )
                          )
                        )
                      ],
                    ),
                  )
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              Container(
                child: ListView.separated(
                  physics: BouncingScrollPhysics(),
                  itemCount: 1 + (followers?.length ?? 0),
                  separatorBuilder: (ctx, i) => Divider(),
                  itemBuilder: (ctx, i) => i == 0
                    ? _header(context, "People who follow you")
                    : ChatItem(Chat(user, followers![i-1]))
              ),
            ),
            Container(
                child: ListView.separated(
                  physics: BouncingScrollPhysics(),
                  itemCount: 1 + (followees?.length ?? 0),
                  separatorBuilder: (ctx, i) => Divider(),
                  itemBuilder: (ctx, i) => i == 0
                    ? _header(context, "People you follow")
                    : ChatItem(Chat(user, followees![i-1]))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build followers/followees header text 
  Widget _header(ctx, text) => 
    Container( 
      padding: EdgeInsets.only(left: 20, bottom: 15), 
      child: Text(
        text, 
        style: TextStyle(
          color: Theme.of(ctx).primaryColor,
          fontStyle: FontStyle.italic
        )
      )
    );

}

/// creates a string like `' (4)'` or `' (99+)'`
String numStr(int? n) => n is int ? (
    n > 99 ? ' (99+)' : ' ($n)'
  ) : '';