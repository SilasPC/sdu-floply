import 'package:flutter/material.dart';
import 'common/ButtonWithLoading.dart';
import 'tabs.dart';
import 'db/User.dart';
import 'util/util.dart';

/// Page enabling users to create a new user.
///
/// ### DISCLAIMER ###
/// The code on this page is (mostly) not authored by us,
/// but updated and modified from a tutorial/example found at
/// https://www.tutorialkart.com/flutter/flutter-login-screen/
class SignupPage extends StatefulWidget {
  @override createState() => _State();
}
 
class _State extends State<SignupPage> {

  /// `true` when loading/creating user 
  bool _isLoading = false;

  // input controllers
  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  /// Attempt to create a new user
  Future<void> _signUp(BuildContext context) async {

    setState(() {_isLoading = true;});

    var user = await User.create(idController.text, nameController.text);
    
    // check success
    if (user is! WebValue) {
      _showSnackBar(context, 'Could not connect to server.');
      setState(() {_isLoading = false;});
      return;
    }
    if (user!.value is! User) {
      _showSnackBar(context, 'User already exists.');
      setState(() {_isLoading = false;});
      return;
    }

    // navigate to root
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TabsView(user.value!)
      ),
      (r) => false
    );

  }

  /// Show a small text overlay on the bottom of the screen
  void _showSnackBar(BuildContext ctx, String msg) {
    ScaffoldMessenger
      .of(ctx)
      .showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: Duration(seconds: 2),
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoply'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Text(
                'Hoply',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 30),
              )),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Text(
                'Sign up',
                style: TextStyle(fontSize: 20),
              )),
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                cursorColor: cursorColor(context),
                controller: idController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User ID',
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                cursorColor: cursorColor(context),
                controller: nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User name',
                ),
              ),
            ),
            Container(
              height: 50,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ButtonWithLoading(
                  msg: _isLoading ? null : 'Sign up',
                  onTap: () => _signUp(context)
                )
              ),
          ],
        )
      )
    );
  }

}
