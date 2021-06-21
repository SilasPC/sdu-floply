import 'package:flutter/material.dart';
import 'package:foply/main.dart';
import 'package:foply/db/db.dart';
import 'package:foply/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

// Theme control is inspired the StackOverflow answer by 'CopsOnRoad':
// https://stackoverflow.com/a/64185945/12424498

/// Tab with settings
class Settings extends StatelessWidget {

  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 250,
          padding: EdgeInsets.only(bottom: 50, top: 150, right: 100, left: 100),
          child : ElevatedButton(
            style: ButtonStyle(backgroundColor: 
              MaterialStateProperty.all<Color>(Theme.of(context).primaryColor)
            ),
            onPressed: () {
              if (MyApp.notifier.value == ThemeMode.system) {
                var brightness = MediaQuery.of(context).platformBrightness;
                bool darkModeOn = brightness == Brightness.dark;
                MyApp.notifier.value = darkModeOn ? ThemeMode.light : ThemeMode.dark;
              }
              else {
                MyApp.notifier.value = MyApp.notifier.value  != ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
              }
            },
            child: Text('Toggle Theme'),
          ),
        ),
        Container(
          height: 150,
          padding: EdgeInsets.only(bottom: 50, top: 50, right: 100, left: 100),
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: 
              MaterialStateProperty.all<Color>(Theme.of(context).primaryColor)
            ),
            onPressed: () => _signOut(context),
            child: Text('Log out'),
          )
        ),
        Container(
          height: 150,
          padding: EdgeInsets.only(bottom: 50, top: 50, right: 100, left: 100),
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: 
              MaterialStateProperty.all<Color>(Theme.of(context).primaryColor)
            ),
            onPressed: () => _clearDatabase(context),
            child: Text('Clear local database'),
          ),
        )
      ],
    );

  }

  /// Wipe all data from the local database and sign out the user.
  Future<void> _clearDatabase(BuildContext context) async {
    await clearLocalDatabase();
    await TableSyncer.refreshAll();
    await _signOut(context);
  }

  /// Sign out the user.
  Future<void> _signOut(BuildContext context) async {

    // remove persisted used login information
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (ctx) => LoginPage()
      ),
      (r) => false
    );
  }

}