import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Game/init.dart';

class Settings_page extends StatelessWidget {
  static const String id = "setting_page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Fondo claro como el de la imagen
      body: Column(
        children: [
          // Encabezado con color verde
          Container(
            color: Colors.black,
            height: 80,
            alignment: Alignment.center,
            child: Text(
              'CHECKMATES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),

          // Sección de ajustes
          Container(
            color: Colors.grey[900], // Fondo lila claro
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

          // Lista de opciones
          Expanded(
            child: Container(
              color: Colors.grey, // Fondo igual al de ajustes
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
          ),

          // Barra de navegación inferior
          _buildBottomNavigationBar(context),
        ],
      ),
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
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarIcon(context, Icons.home), // Ahora sí recibe context
          _buildNavBarIcon(context, Icons.emoji_events),
          _buildNavBarIcon(context, Icons.folder),
          _buildNavBarIcon(context, Icons.group),
          _buildNavBarIcon(context, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildNavBarIcon(BuildContext context, IconData icon) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 32),
      onPressed: () {
        if (icon == Icons.home) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Init_page()),
          );
        }
      },
    );
  }
}