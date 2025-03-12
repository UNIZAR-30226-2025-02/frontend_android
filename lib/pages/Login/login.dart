import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_android/pages/Game/init.dart';
import 'package:frontend_android/pages/Login/signin.dart';

class Login_page extends StatefulWidget {
  static const String id = "login_page";

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Login_page> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mensajeError = '';
  bool _isLoading = false; // ✅ Muestra un indicador de carga mientras se procesa el login

  Future<void> _login() async {
    String user = _userController.text;
    String password = _passwordController.text;

    if (user.isEmpty || password.isEmpty) {
      setState(() {
        _mensajeError = "Todos los campos son obligatorios";
      });
      return;
    }

    setState(() {
      _mensajeError = "";
      _isLoading = true; // ✅ Activa el indicador de carga
    });

    final String baseUrl = dotenv.env['SERVER_BACKEND'] ?? "http://localhost:3000/";
    final String apiUrl = "${baseUrl}login"; // Backend local

    final Map<String, String> loginData = {
      "NombreUser": user,
      "Contrasena": password
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      setState(() {
        _isLoading = false; // ✅ Desactiva el indicador de carga
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("✅ Inicio de sesión exitoso: ${response.body}");

        // ✅ Guardar datos del usuario en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', responseData['NombreUser']);
        await prefs.setString('fotoPerfil', responseData['FotoPerfil'] ?? ""); // Opcional

        // ✅ Redirigir a la página principal
        Navigator.pushReplacementNamed(context, Init_page.id);
      } else {
        setState(() {
          _mensajeError = "Usuario o contraseña incorrectos";
        });
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
      setState(() {
        _mensajeError = "Error de conexión con el servidor.";
        _isLoading = false;
      });
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
                      Navigator.pushNamed(context, Signin_page.id);
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
              _isLoading
                  ? CircularProgressIndicator() // ✅ Muestra un indicador de carga mientras espera la respuesta
                  : _buttonLogin(),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, Init_page.id);
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
      onPressed: _login, // ✅ Ahora llama a la función con conexión al backend
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
