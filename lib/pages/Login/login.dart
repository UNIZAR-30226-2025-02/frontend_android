import 'dart:convert';
import 'dart:io' as IO;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_android/pages/Login/password.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_android/pages/Game/init.dart';
import 'package:frontend_android/pages/Login/signin.dart';
import 'package:frontend_android/pages/playerInfo.dart';
import 'package:socket_io_client/src/socket.dart' as IO;

import '../../services/socketService.dart';
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

  IO.Socket? socket;

  SocketService socketService = SocketService();

  Future<void> _initializeSocket() async {
    await socketService.connect(context); // ✅ Asegurar que el socket esté listo
    IO.Socket connectedSocket = await socketService.getSocket(context);

    if (mounted) {
      setState(() {
        socket = connectedSocket as IO.Socket?; // ✅ Ahora el socket está disponible
      });
    }
  }

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
        final accessToken = responseData['accessToken'];
        final publicUser = responseData['publicUser'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('idJugador', publicUser['id']);
        await prefs.setString('usuario', publicUser['NombreUser']);
        await prefs.setString('Correo', publicUser['Correo']);
        await prefs.setString('estadoPartida', publicUser['EstadoPartida']?? "NULL");
        await prefs.setString('estadoUser', publicUser['estadoUser']);
        await prefs.setString('fotoPerfil', publicUser['FotoPerfil'] ?? "");
        playerInfo(prefs.getString('idJugador'),prefs.getString('usuario'), prefs.getString('Correo'),
            prefs.getString('estadoUser'), prefs.getString('fotoPerfil'));
        try {
          await _initializeSocket(); // conecta y espera
          Navigator.pushReplacementNamed(context, Init_page.id); // solo si todo va bien
        } catch (e) {
          _mostrarSnackBar("No se pudo conectar con el servidor.");
        }
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.blueAccent, width: 1.5),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text("Recuperar Contraseña", style: TextStyle(color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Correo Electrónico",
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        prefixIcon: Icon(Icons.email, color: Colors.grey[700]),
                        filled: true,
                        fillColor: Colors.white, // Fondo blanco siempre visible
                        errorText: mensajeErrorCorreo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancelar", style: TextStyle(color: Colors.redAccent)),
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
                  child: Text("Enviar", style: TextStyle(color: Colors.blueAccent)),
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
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                "Correo enviado",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            "Tu correo de recuperación ha sido enviado.\nRevisa tu bandeja de entrada.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _redirigirAPassword();
              },
              child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
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

  Future<void> _entrarComoInvitado() async {
    final String? baseUrl = dotenv.env['SERVER_BACKEND'];
    final String apiUrl = "${baseUrl}crearInvitado";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final accessToken = responseData['accessToken'];
        final publicUser = responseData['publicUser'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('idJugador', publicUser['id']);
        await prefs.setString('usuario', publicUser['NombreUser']);
        await prefs.setString('Correo', publicUser['Correo'] ?? '');
        await prefs.setString('estadoPartida', publicUser['EstadoPartida'] ?? "NULL");
        await prefs.setString('estadoUser', publicUser['estadoUser']);
        await prefs.setString(
            'fotoPerfil',
            (publicUser['FotoPerfil'] == 'none' || publicUser['FotoPerfil'] == '') ? 'fotoPerfil.png' : publicUser['FotoPerfil']
        );

        playerInfo(
          prefs.getString('idJugador'),
          prefs.getString('usuario'),
          prefs.getString('Correo'),
          prefs.getString('estadoUser'),
          prefs.getString('fotoPerfil'),
        );

        await _initializeSocket();

        Navigator.pushReplacementNamed(context, Init_page.id);
      } else {
        _mostrarSnackBar("No se pudo crear un invitado. Intenta más tarde.");
      }
    } catch (e) {
      _mostrarSnackBar("Error al conectarse con el servidor.");
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
                    onTap: () => print('Iniciar Sesión'),
                    child: Text(
                      'Iniciar Sesión',
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
                      'Registrarse',
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
                  ? CircularProgressIndicator(color: Colors.blueAccent)
                  : _buttonLogin(),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _entrarComoInvitado,
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
      "Nombre de usuario",
      Icons.person_outline,
      _mensajeErrorUser,
    );
  }

  Widget _textFieldPassword() {
    return _textField(
      _passwordController,
      "Contraseña",
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
      child: Text('Iniciar Sesión'),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
