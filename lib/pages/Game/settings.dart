import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/Game/friends.dart';
import 'package:frontend_android/pages/Game/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/socketService.dart';
import '../Presentation/wellcome.dart';
import '../../widgets/app_layout.dart'; // 👈 importa AppLayout

class Settings_page extends StatefulWidget {
  static const String id = "setting_page";

  @override
  _Settings_pageState createState() => _Settings_pageState();
}

class _Settings_pageState extends State<Settings_page> {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Column(
        children: [
          SizedBox(height: 16),
          Container(
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AJUSTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.settings, color: Colors.white, size: 36),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.person, 'PERFIL', () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Profile_page()),
                        (route) => true,
                  );
                }),
                _buildMenuItem(Icons.group, 'AMIGOS', () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Friends_Page()),
                        (route) => true,
                  );
                }),
                _buildMenuItem(Icons.close, 'CERRAR SESIÓN', () {
                  _confirmCloseSession(context);
                }),
              ],
            ),
          ),
          BottomNavBar(currentIndex: 4),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCloseSession(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text("Cerrar sesión", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            "¿Estás seguro de que quieres cerrar sesión?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancelar
              },
              child: Text("Cancelar", style: TextStyle(color: Colors.blueAccent)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cierra el diálogo
                await Future.delayed(Duration(milliseconds: 300));
                _cerrarSesion(context);
              },
              child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioActual = prefs.getString('usuario');

    if (usuarioActual != null) {
      try {
        String? backendUrl = dotenv.env['SERVER_BACKEND'];
        final response = await http.post(
          Uri.parse("${backendUrl}logout"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"NombreUser": usuarioActual}),
        );

        if (response.statusCode == 200) {
          print("✅ Sesión cerrada correctamente en el servidor.");
        } else {
          print("❌ Error al cerrar sesión en el servidor: ${response.body}");
        }
      } catch (e) {
        print("❌ Error de conexión al servidor: $e");
      }
    }

    await prefs.clear();

    if (mounted) {
      SocketService().showForceLogoutPopup("Tu sesión se ha cerrado correctamente.");
    }
  }
}
