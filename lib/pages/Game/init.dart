import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/settings.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/inGame/board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/buildHead.dart';

class Init_page extends StatelessWidget {
  static const String id = "init_page";
  String selectedGameMode = "Clásica"; // Modo seleccionado

  final List<GameMode> gameModes = [
    GameMode("Clásica", Icons.extension, "10 min", "Modo tradicional de ajedrez."
        " Cada jugador consta de 10 min para realizar sus movimientos",
        Colors.brown),
    GameMode("Principiante", Icons.verified, "30 min", "Ideal para quienes están"
        " aprendiendo. Cada jugador consta de 30 min para realizar sus "
        "movimientos", Colors.green),
    GameMode("Avanzado", Icons.timer_off, "5 min", "Para jugadores "
        "experimentados. Cada jugador consta de 30 min para realizar sus "
        "movimientos", Colors.red),
    GameMode("Relámpago", Icons.bolt, "3 min", "Modo para expertos. El tiempo es"
        " muy limitado, cada jugador cuenta con 3 minutos.", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15 min + 10 seg", "Cada jugada "
        "suma 10 segundos al tiempo del jugador.", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3 min + 2 seg", "Partidas rápidas"
        " con incremento de 2 segundos por jugada.", Colors.yellow),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: BuildHeadLogo(actions: [
        IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Login_page()),
            );
          },
        ),
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
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: gameModes.length,
              itemBuilder: (context, index) {
                return _buildGameButton(context, gameModes[index]);
              },
            ),
          ),
          _buildBuscarPartidaButton(context),
          BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildGameButton(BuildContext context, GameMode mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: ListTile(
          leading: Icon(mode.icon, size: 28, color: mode.color),

          title: Text(
            mode.name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Row(
            children: [
              _buildInfoButton(context, mode.name, mode.description), // Botón de información táctil
              SizedBox(width: 8),
              Text(
                mode.time,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              selectedGameMode = mode.name;
            },
            child: Text("Jugar"),
          ),
        ),
      ),
    );
  }

  // Botón ℹ️ que muestra el mensaje al tocarlo
  Widget _buildInfoButton(BuildContext context, String title, String description) {
    return IconButton(
      icon: Icon(Icons.info_outline, color: Colors.blue, size: 22),
      onPressed: () {
        _showInfoDialog(context, title, description); // Muestra el mensaje
      },
    );
  }

  // Muestra un AlertDialog con la información del modo de juego
  void _showInfoDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue),
          ),
          title: Text(
            title,
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          content: Text(
            description,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cerrar", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBuscarPartidaButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class GameMode {
  final String name;
  final IconData icon;
  final String time;
  final String description;
  final Color color;

  GameMode(this.name, this.icon, this.time, this.description, this.color);
}
