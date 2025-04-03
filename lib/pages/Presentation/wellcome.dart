import 'package:flutter/material.dart';
import 'dart:async'; // Para el temporizador

import 'package:frontend_android/pages/Game/init.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/Login/signin.dart';

class Wellcome_page extends StatefulWidget {
  static const String id = "wellcome_page";

  @override
  _Wellcome_pageState createState() => _Wellcome_pageState();
}

class _Wellcome_pageState extends State<Wellcome_page> {
  List<Color> gradientColors1 = [Color(0xff3A3A3A), Color(0xff2D2D2D)];
  List<Color> gradientColors2 = [Color(0xff2D2D2D), Color(0xff3A3A3A)];
  bool toggle = true;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          toggle = !toggle;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // <- Esto evita el memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: toggle ? gradientColors1 : gradientColors2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bienvenido a CheckMateX",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Juega, aprende y mejora tu ajedrez con jugadores de todo el mundo.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              Image.asset(
                'assets/logo.png',
                height: 350,
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login_page()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Signin_page()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Registrarse",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Init_page()),
                  );
                },
                child: Text(
                  "Entrar como invitado",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
