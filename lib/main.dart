import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_android/pages/Game/init.dart';
import 'package:frontend_android/pages/Game/settings.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/Login/signin.dart';
import 'package:frontend_android/pages/Presentation/wellcome.dart';
import 'package:frontend_android/pages/Game/profile.dart';

void main() async {
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        iconTheme: IconThemeData( color: null),
      ),
      initialRoute: welcome_page.id,
      routes: {
        welcome_page.id: (_) => welcome_page(),
        Login_page.id: (_) => Login_page(),
        Signin_page.id: (_) => Signin_page(),
        Init_page.id: (_) => Init_page(),
        Settings_page.id:(_) => Settings_page(),
        Profile_page.id: (_) => Profile_page(),
      },
    );
  }
}

