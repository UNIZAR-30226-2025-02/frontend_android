import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Login/signin.dart';
import 'package:frontend_android/pages/Game/init.dart'; // Importa Init_page

class Login_page extends StatefulWidget {
  static const String id = "login_page";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Login_page> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mensajeError = '';

  void _login() {
    String user = _userController.text;
    String password = _passwordController.text;

    if (user.isEmpty || password.isEmpty) {
      setState(() {
        _mensajeError = "Todos los campos son obligatorios";
      });
    } else {
      setState(() {
        _mensajeError = "";
      });

      Navigator.pushReplacementNamed(context, Init_page.id);
    }
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => print('Login'),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Signin_page()),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25.0),
              _textFieldUser(),
              SizedBox(height: 15.0),
              _textFieldPassword(),
              SizedBox(height: 10.0),
              if (_mensajeError.isNotEmpty)
                Text(
                  _mensajeError,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 15.0),
              _buttonLogin(),
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
      ),
    );
  }

  Widget _textFieldUser() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: _userController,
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
        controller: _passwordController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          labelText: "Password",
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buttonLogin() {
    return ElevatedButton(
      onPressed: _login, // Llama a la función corregida
      child: Text('Login'),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
