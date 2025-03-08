import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Game/botton_nav_bar.dart';

class LearnPage extends StatelessWidget {
  static const String id = "learn_page";

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.account_circle, color: Colors.white, size: 32),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[850], // Color oscuro para la sección
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APRENDER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.folder, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.menu_book, 'APERTURAS'),
                _buildMenuItem(Icons.assignment, 'REGLAS'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2), // Índice de "Aprender"
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
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