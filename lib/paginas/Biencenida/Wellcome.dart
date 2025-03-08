import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Game/init.dart';
import 'package:frontend_android/paginas/Login/login.dart';
import 'package:frontend_android/paginas/Login/signin.dart';

class welcome_page extends StatelessWidget {
  static const String id = "wellcome_page";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff3A3A3A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título principal
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

            // Subtítulo
            Text(
              "Juega, aprende y mejora tu ajedrez con jugadores de todo el mundo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 40),

            // Imagen del logo
            Image.asset(
              'assets/logo.png',
              height: 350,
            ),

            SizedBox(height: 30),

            // Botones de inicio de sesión y registro
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón "Iniciar Sesión"
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

                // Botón "Registrarse"
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

            // Enlace para entrar como invitado
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
    );
  }
}
