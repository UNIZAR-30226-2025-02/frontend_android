import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/pages/Login/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Password_page extends StatefulWidget {
  static const String id = 'reset_password_page';

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<Password_page> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _mensajeErrorToken;
  String? _mensajeErrorUser;
  String? _mensajeErrorPassword;
  String? _mensajeErrorConfirmPassword;

  bool _isLoading = false;

  Future<void> _resetPassword() async {
    String token = _tokenController.text.trim();
    String user = _userController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // Resetear mensajes de error
    setState(() {
      _mensajeErrorToken = null;
      _mensajeErrorUser = null;
      _mensajeErrorPassword = null;
      _mensajeErrorConfirmPassword = null;
    });

    bool hasError = false;

    if (token.isEmpty) {
      setState(() => _mensajeErrorToken = "Completa este campo");
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

    if (confirmPassword.isEmpty) {
      setState(() => _mensajeErrorConfirmPassword = "Confirma tu contraseña");
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _mensajeErrorConfirmPassword = "Las contraseñas no coinciden");
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}tryResetPasswd";

    final Map<String, String> resetData = {
      "token": token,
      "NombreUser": user,
      "Contrasena": password
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(resetData),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _mostrarDialogoExito();
      } else {
        setState(() {
          _mostrarSnackBar(response.body);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mostrarSnackBar("Error de conexión con el servidor.");
      });
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

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Contraseña Restablecida"),
          content: Text("Tu contraseña ha sido actualizada correctamente."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _redirigirALogin();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _redirigirALogin() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, Login_page.id);
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
                "Restablecer Contraseña",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),
              _textField(_tokenController, "Código de Verificación", Icons.lock_open, _mensajeErrorToken),
              SizedBox(height: 15.0),
              _textField(_userController, "Usuario", Icons.person, _mensajeErrorUser),
              SizedBox(height: 15.0),
              _textField(_passwordController, "Nueva Contraseña", Icons.lock, _mensajeErrorPassword, isPassword: true),
              SizedBox(height: 15.0),
              _textField(_confirmPasswordController, "Confirmar Contraseña", Icons.lock, _mensajeErrorConfirmPassword, isPassword: true),
              SizedBox(height: 20),
              _isLoading ? CircularProgressIndicator(color: Colors.blueAccent,) : _buttonResetPassword(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, IconData icon, String? errorMessage, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 5),
      child: TextField(
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
    );
  }

  Widget _buttonResetPassword() {
    return ElevatedButton(
      onPressed: _resetPassword,
      child: Text('Confirmar'),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
