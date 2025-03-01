import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Login/login.dart';

class Init_page extends StatelessWidget {
static const String id = "init_page";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],  // Fondo oscuro como el login
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 70,  // Más alto
        title: Text(
          'CheckMates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,  // Letra más grande
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () {
              // Navegación a la página de login
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login_page()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'PARTIDAS ONLINE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildGameButton('Partida relámpago'),
                _buildGameButton('Partida relámpago'),
                _buildGameButton('Partida estándar'),
                Spacer(),
                _buildBuscarPartidaButton(),
              ],
            ),
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildGameButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 70,  // Botones grandes
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBuscarPartidaButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 70,  // Misma altura para consistencia
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[200],  // Botón lila
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {},
          child: Text(
            'BUSCAR PARTIDA',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      color: Colors.black,
      height: 80,  // Más alto para ocupar todo
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarIcon(Icons.home),
          _buildNavBarIcon(Icons.emoji_events),
          _buildNavBarIcon(Icons.folder),
          _buildNavBarIcon(Icons.group),
          _buildNavBarIcon(Icons.settings),
        ],
      ),
    );
  }

  Widget _buildNavBarIcon(IconData icon) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 32),  // Íconos más grandes
      onPressed: () {},
    );
  }
}
