import 'package:flutter/material.dart';
import 'package:foply/splash.dart';

/// Main entry point
void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  /// Theme change notifier
  static final ValueNotifier<ThemeMode> notifier = ValueNotifier( ThemeMode.system );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => WidgetsBinding.instance?.focusManager.primaryFocus?.unfocus(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: notifier,
        builder: (_, mode, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hoply',
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: mode,
            home: SplashPage(),
          );
        },
      )
    );
  }

  /// The app's light theme
  static final ThemeData _lightTheme = ThemeData(
    primarySwatch: Colors.green,
    primaryColor: Color(0xff38803e),
    accentColor: Color(0xff2c6330),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.white70),
    )
  );

  /// The app's dark theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: Color(0xff41af46),
    accentColor: Color(0xff338a37),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.white
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.white70),
    ),
  );

}
