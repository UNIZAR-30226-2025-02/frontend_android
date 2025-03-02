import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Login/login.dart';
/* Clase que implementa la interfaz del registro del usuario
*/

class Signin_page extends StatelessWidget {
  static const String id = 'signin_page'; // Ruta nombrada

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xff3A3A3A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "CheckMates",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),

              // Fila de botones (Login y Sign In)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Login_page()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
              _textFieldName(),
              SizedBox(height: 25.0),

              // Espaciadores eliminados para mejor orden
              _textFieldSurname(),
              SizedBox(height: 25.0),
              _textFieldUser(),
              SizedBox(height: 25.0),
              // Espaciadores eliminados para mejor orden
              _textFieldPassword(),
              SizedBox(height: 25.0),

              // Espaciadores eliminados para mejor orden
              _buttonLogin(),

              // Espaciadores eliminados para mejor orden

            ],
          ),
        ),
      ),
    );
  }
  Widget _textFieldName() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.text_fields),
          labelText: "Name",
        ),
      ),
    );
  }
  Widget _textFieldSurname() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.text_fields_outlined),
          labelText: "Surname",
        ),
      ),
    );
  }

  Widget _textFieldUser() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.person_outline),
          labelText: "User",
        ),
      ),
    );
  }

  Widget _textFieldPassword() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          labelText: "Password",
        ),
      ),
    );
  }

  Widget _buttonLogin() {
    return ElevatedButton(
      onPressed: () {
        print('Botón presionado');
      },
      child: Text('Sign in'),
    );
  }
}
