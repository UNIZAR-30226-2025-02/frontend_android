import 'package:flutter/material.dart';
import 'package:frontend_android/paginas/Game/settings.dart';
import 'package:frontend_android/paginas/Login/login.dart';
import 'package:frontend_android/paginas/inGame/board.dart';
import 'package:frontend_android/paginas/Game/botton_nav_bar.dart';  // Importa el nuevo widget

class Init_page extends StatelessWidget {
  static const String id = "init_page";
  String selectedGameMode = "Partida estándar"; // Modo de juego a seleccionar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Fondo oscuro como el login
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 70,
        title: Text(
          'CheckMates',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () {
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
                _buildBuscarPartidaButton(context),
              ],
            ),
          ),

          // Usa el BottomNavBar reutilizable
          BottomNavBar(currentIndex: 0),  // currentIndex = 0 porque es la página inicial
        ],
      ),
    );
  }

  Widget _buildGameButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            selectedGameMode = title;
          },
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

  Widget _buildBuscarPartidaButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 70,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoardScreen(gameMode: selectedGameMode),
              ),
            );
          },
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
}
