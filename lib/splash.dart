
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/User.dart';
import 'login.dart';
import 'tabs.dart';

/// Splash page.
/// Determines whether user is signed in, and redirects accordingly.
class SplashPage extends StatelessWidget {

  /// Fetch stored information and redirect
  Future<void> _getPrefs(BuildContext context) async {
    try {
      
      var prefs = await SharedPreferences.getInstance();

      var id = prefs.getString('user');
      if (id is String) {
        var user = await User.byId(id);
        if (user is User)
          return _transition(context, () => TabsView(user));
      }

    } catch(e) {
      // print('FAILED TO GET SPLASH PREFS');
      // print(e);
    }

    _transition(context, () => LoginPage());
  }

  /// Transition to the given page
  void _transition(BuildContext context, Widget Function() buildPage) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => buildPage()),
      (r) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    _getPrefs(context);
    return Scaffold(
      body: Container(
        child: Center(
          child: Image(
            image: AssetImage(
              'assets/hoply.png'
            )
          )
        )
      )
    );
  }

}