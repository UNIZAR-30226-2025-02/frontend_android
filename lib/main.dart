import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Login/login.dart';
import 'package:frontend_android/paginas/Login/signin.dart';



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
    initialRoute: Login_page.id,
    routes: {
    Login_page.id: (_) => Login_page(),
    Signin_page.id: (_) => Signin_page(),
  },
    );
  }
}

