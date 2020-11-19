import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'SourceSansPro',
  bottomNavigationBarTheme:
      BottomNavigationBarThemeData(selectedItemColor: Colors.indigo),
  backgroundColor: Colors.white,
  dividerColor: Colors.transparent,
  accentColor: Colors.indigoAccent,
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.indigo.withOpacity(0.8)),
  appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: Colors.indigo),
      iconTheme: IconThemeData(color: Colors.white),
      color: Colors.indigo,
      textTheme: TextTheme(
          headline6: TextStyle(
        color: Colors.black,
      ))),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'SourceSansPro',
  bottomNavigationBarTheme:
      BottomNavigationBarThemeData(selectedItemColor: Colors.white),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.indigo.withOpacity(0.8)),
  dividerColor: Colors.transparent,
  accentColor: Colors.indigoAccent,
  backgroundColor: Colors.indigo,
  appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
      color: Colors.indigo,
      textTheme: TextTheme(headline6: TextStyle(color: Colors.white))),
);
