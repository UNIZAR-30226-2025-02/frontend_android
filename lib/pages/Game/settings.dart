import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';

class Settings_page extends StatelessWidget {
  static const String id = "setting_page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Color oscuro para la barra superior
        title: Text(
          'CHECKMATES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[850],
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AJUSTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.settings, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.person, 'PERFIL'),
                _buildMenuItem(Icons.group, 'AMIGOS'),
                _buildMenuItem(Icons.emoji_events, 'RANKING'),
                _buildMenuItem(Icons.star, 'VALORA LA APP'),
                _buildMenuItem(Icons.play_arrow, 'HISTORIAL PARTIDAS'),
                _buildMenuItem(Icons.close, 'CERRAR SESIÓN'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4), // Índice de "Ajustes"
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
    );
  }
}
