import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Game/init.dart';
import 'package:frontend_android/paginas/Game/settings.dart';
import 'package:frontend_android/paginas/Login/login.dart';
import 'package:frontend_android/paginas/Login/signin.dart';
import 'package:frontend_android/paginas/Game/init.dart';
import 'package:frontend_android/paginas/Biencenida/Wellcome.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: welcome_page.id,
      routes: {
        welcome_page.id: (_) => welcome_page(),
        Login_page.id: (_) => Login_page(),
        Signin_page.id: (_) => Signin_page(),
        Init_page.id: (_) => Init_page(),
        Settings_page.id:(_) => Settings_page(),
      },
    );
  }
}

