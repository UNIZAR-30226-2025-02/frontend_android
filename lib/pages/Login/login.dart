import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_android/pages/Login/password.dart';
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
  final TextEditingController _emailController = TextEditingController();

  String? _mensajeErrorUser;
  String? _mensajeErrorPassword;
  bool _isLoading = false;

  Future<void> _login() async {
    String user = _userController.text.trim();
    String password = _passwordController.text.trim();


    // Resetear mensajes de error
    setState(() {
      _mensajeErrorUser = null;
      _mensajeErrorPassword = null;
    });

    bool hasError = false;

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

    setState(() => _isLoading = true);

    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}login";

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

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('idJugador', responseData['id']);
        await prefs.setString('usuario', responseData['NombreUser']);
        await prefs.setString('Correo', responseData['Correo']);
        await prefs.setString('estadoUser', responseData['estadoUser']);
        await prefs.setString('fotoPerfil', responseData['FotoPerfil'] ?? "");

        Navigator.pushReplacementNamed(context, Init_page.id);
      } else {
        _mostrarSnackBar("Usuario o contraseña incorrectos");
      }
    } catch (e) {
      _mostrarSnackBar("Error de conexión con el servidor.");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _mostrarDialogoRecuperacion() async {
    _emailController.clear();
    String? mensajeErrorCorreo;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Recuperar Contraseña"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico",
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      errorText: mensajeErrorCorreo,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    String email = _emailController.text.trim();

                    if (email.isEmpty) {
                      setState(() => mensajeErrorCorreo = "Completa este campo");
                      return;
                    } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                        .hasMatch(email)) {
                      setState(() => mensajeErrorCorreo = "Correo inválido");
                      return;
                    }

                    Navigator.pop(context);
                    await _enviarRecuperacion(email);
                  },
                  child: Text("Enviar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _enviarRecuperacion(String email) async {
    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}sendPasswdReset";

    final Map<String, String> requestData = {
      "Correo": email,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        _mostrarDialogoExitoso();
      } else {
        _mostrarSnackBar(response.body);
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

  void _mostrarDialogoExitoso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Correo de recuperación enviado"),
          content: Text("Su correo de recuperación de contrseña ha sido "
              "enviado. Revise el correo."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _redirigirAPassword();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _redirigirAPassword() async {
    await Future.delayed(Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, Password_page.id);
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
              SizedBox(height: 20.0),
              _isLoading
                  ? CircularProgressIndicator()
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
              GestureDetector(
                onTap: _mostrarDialogoRecuperacion,
                child: Text(
                  "¿Has olvidado tu contraseña?",
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
    return _textField(
      _userController,
      "User",
      Icons.person_outline,
      _mensajeErrorUser,
    );
  }

  Widget _textFieldPassword() {
    return _textField(
      _passwordController,
      "Password",
      Icons.lock,
      _mensajeErrorPassword,
      isPassword: true,
    );
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

  Widget _buttonLogin() {
    return ElevatedButton(
      onPressed: _login,
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
