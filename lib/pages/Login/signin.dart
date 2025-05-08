import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  String? _mensajeErrorCorreo;
  String? _mensajeErrorUser;
  String? _mensajeErrorPassword;

  bool _esEmailValido(String email) {
    String pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    RegExp regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  Future<void> _registrarUsuario() async {
    String email = _emailController.text.trim();
    String user = _userController.text.trim();
    String password = _passwordController.text.trim();

    _mensajeErrorCorreo = null;
    _mensajeErrorUser = null;
    _mensajeErrorPassword = null;

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _mensajeErrorCorreo = "Completa este campo");
      hasError = true;
    } else if (!_esEmailValido(email)) {
      setState(() => _mensajeErrorCorreo = "Incluye un signo '@' en la dirección");
      hasError = true;
    } else if (!email.contains('@') || email.endsWith('@')) {
      setState(() => _mensajeErrorCorreo = "Introduce texto después del '@'");
      hasError = true;
    }

    if (user.isEmpty) {
      setState(() => _mensajeErrorUser = "Completa este campo");
      hasError = true;
    } else if (user.length < 4) {
      setState(() => _mensajeErrorUser = "El usuario debe tener al menos 4 caracteres");
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _mensajeErrorPassword = "Completa este campo");
      hasError = true;
    } else if (password.length < 4) {
      setState(() => _mensajeErrorPassword = "La contraseña debe tener al menos 4 caracteres");
      hasError = true;
    }

    if (hasError) return;

    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}register";

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
        _mostrarDialogoRegistroExitoso();
      } else {
        final responseData = jsonDecode(response.body);
        _mostrarSnackBar(responseData['error'] ?? "Error en el registro");
      }
    } catch (e) {
      _mostrarSnackBar("Error de conexión con el servidor.");
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
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
                _redirigirAInicioSesion();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _redirigirAInicioSesion() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, 'login_page');
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
                "CheckMateX",
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
                      'Iniciar Sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Registrarse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              _textFieldUser(),
              SizedBox(height: 15.0),
              _textFieldEmail(),
              SizedBox(height: 15.0),
              _textFieldPassword(),
              SizedBox(height: 20),
              _buttonRegister(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textFieldEmail() {
    return _textField(_emailController, "Correo electrónico", Icons.email, _mensajeErrorCorreo);
  }

  Widget _textFieldUser() {
    return _textField(_userController, "Nombre de usuario", Icons.person_outline, _mensajeErrorUser);
  }

  Widget _textFieldPassword() {
    return _textField(_passwordController, "Contraseña", Icons.lock, _mensajeErrorPassword, isPassword: true);
  }

  Widget _textField(
      TextEditingController controller,
      String label,
      IconData icon,
      String? errorMessage, {
        bool isPassword = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              labelText: label,
              filled: true,
              fillColor: Colors.white,
              errorStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              errorText: errorMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonRegister() {
    return ElevatedButton(
      onPressed: _registrarUsuario,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Registrarse',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
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
