import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/ButtonWithLoading.dart';
import 'signup.dart';
import 'tabs.dart';
import 'db/User.dart';
import 'util/util.dart';

/// ### DISCLAIMER ###
/// The code on this page is (mostly) not authored by us,
/// but updated and modified from a tutorial/example found at
/// https://www.tutorialkart.com/flutter/flutter-login-screen/
class LoginPage extends StatefulWidget {
  @override
  _State createState() => _State();
}
 
class _State extends State<LoginPage> {
  
  TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
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
              )
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              child: Text(
                'Sign in',
                style: TextStyle(fontSize: 20),
              )
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: TextField(
                cursorColor: cursorColor(context),
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'User id',
                ),
              ),
            ),
            Container(
              height: 50,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ButtonWithLoading(
                  msg: _isLoading ? null : 'Login',
                  onTap: () => _clickLogin(context)
                )
              ),
            Container(
              child: Row(
                children: [
                  Text('Need an account?'),
                  TextButton(
                    child: Text(
                      'Sign up',
                      style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor),
                    ),
                    onPressed: !_isLoading ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => SignupPage()
                        ),
                      );
                    } : null,
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              )
            )
          ],
        )
      )
    );
  }

  void _clickLogin(BuildContext context) async {
    setState((){
      _isLoading = true;
    });
    var user = await User.byId(_nameController.text);
    if (user is User) {

      // persist the user login
      var prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', user.id);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (ctx) => TabsView(user)
        ),
        (r) => false
      );
    } else {
      _showSnackBar(context, 'User not found');
      setState((){
        _isLoading = false;
      });
    }
  }

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

}