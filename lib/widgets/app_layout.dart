import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/Game/settings.dart';
import '../pages/Login/login.dart';
import '../pages/buildHead.dart';
import '../services/socketService.dart';
import '../utils/photoUtils.dart';

class AppLayout extends StatefulWidget {
  final Widget child;

  const AppLayout({required this.child, super.key});

  static _AppLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppLayoutState>();
  }
  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  String? usuarioActual;
  String? fotoPerfil;

  @override
  void initState() {
    super.initState();
    _cargarDatosSesion();
  }

  Future<void> _cargarDatosSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      usuarioActual = prefs.getString('usuario');
      fotoPerfil = prefs.getString('fotoPerfil');
    });
  }

  void recargarFoto() async {
    await _cargarDatosSesion();
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? nombreUsuario = prefs.getString('usuario');

    if (nombreUsuario != null) {
      try {
        String? backendUrl = dotenv.env['SERVER_BACKEND'];
        final response = await http.post(
          Uri.parse("${backendUrl}logout"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"NombreUser": nombreUsuario}),
        );

        if (response.statusCode == 200) {
        } else {
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ Error de conexión al servidor: $e");
        }
      }
    }

    await prefs.remove('usuario');
    await prefs.remove('fotoPerfil');

    if (!mounted) return;

    setState(() {
      usuarioActual = null;
      fotoPerfil = null;
    });

    SocketService().showForceLogoutPopup(
      "Tu sesión se ha cerrado correctamente.",
    );

  }

  Future<void> _salirComoInvitado(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final idJugador = prefs.getString('idJugador');
    final backendUrl = dotenv.env['SERVER_BACKEND'];

    try {
      final response = await http.post(
        Uri.parse("${backendUrl}borrarInvitado"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "id": idJugador,
        }),
      );

      if (response.statusCode == 200) {
      } else {
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error de conexión al borrar invitado: $e");
      }
    }

    await prefs.clear();
    if (!mounted) return;

    SocketService().showForceLogoutPopup("Tu sesión como invitado ha sido cerrada.");
  }

  void _mostrarOpcionesUsuario(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final estadoUser = prefs.getString('estadoUser');

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Configuración"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Settings_page.id);
                },
              ),
              if (estadoUser == 'guest') ...[
                ListTile(
                  leading: Icon(Icons.login),
                  title: Text("Iniciar Sesión"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _salirComoInvitado(context);
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, "wellcome_page");
                      }
                    });
                  },
                ),
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text("Salir de la app", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _salirComoInvitado(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _cerrarSesion(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadLogo(
        actions: [
          usuarioActual == null
              ? IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () {
              Navigator.pushNamed(context, Login_page.id);
            },
          )
              : Padding(
            padding: EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _mostrarOpcionesUsuario(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(getRutaSeguraFoto(fotoPerfil)),
              ),
            ),
          ),
        ],
      ),
      body: widget.child,
    );
  }
}
