import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Signin_page extends StatefulWidget {
  static const String id = 'signin_page';

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<Signin_page> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _mensajeError = '';

  bool _esEmailValido(String email) {
    String pattern =
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  Future<void> _guardarUsuarioEnLocal(String nombreUsuario) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', nombreUsuario);
    print("✅ Usuario guardado en SharedPreferences: $nombreUsuario");
  }

  Future<void> _registrarUsuario() async {
    String email = _emailController.text;
    String user = _userController.text;
    String password = _passwordController.text;

    if (email.isEmpty || user.isEmpty || password.isEmpty) {
      setState(() {
        _mensajeError = "Todos los campos son obligatorios";
      });
      return;
    }

    if (!_esEmailValido(email)) {
      setState(() {
        _mensajeError = "Correo electrónico inválido";
      });
      return;
    }
    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}register"; // Backend local

    final Map<String, String> userData = {
      "Correo": email,
      "NombreUser": user,
      "Contrasena": password
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        print("✅ Registro exitoso: ${response.body}");
        await _guardarUsuarioEnLocal(user);
        _mostrarDialogoRegistroExitoso();
      } else {
        print("❌ Error en el registro: ${response.body}");
        setState(() {
          _mensajeError = "Error en el registro: ${response.body}";
        });
      }
    } catch (e) {
      print("❌ Error de conexión: $e");
      setState(() {
        _mensajeError = "Error de conexión con el servidor.";
      });
    }
  }

  void _mostrarDialogoRegistroExitoso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Registro Exitoso"),
          content: Text("Verifica tu correo electrónico antes de continuar."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _redirigirAInit();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _redirigirAInit() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, 'init_page');
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
                    onTap: () {
                      Navigator.pushReplacementNamed(context, Login_page.id);
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
              _textFieldEmail(),
              SizedBox(height: 15.0),
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
              _buttonRegister(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldEmail() {
    return _textField(_emailController, "Email", Icons.email);
  }

  Widget _textFieldUser() {
    return _textField(_userController, "User", Icons.person_outline);
  }

  Widget _textFieldPassword() {
    return _textField(_passwordController, "Password", Icons.lock, isPassword: true);
  }

  Widget _textField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
        ),
      ),
    );
  }

  Widget _buttonRegister() {
    return ElevatedButton(
      onPressed: _registrarUsuario,
      child: Text('Sign in'),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
