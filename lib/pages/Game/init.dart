import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/settings.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/inGame/board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/buildHead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Presentation/wellcome.dart';

class Init_page extends StatefulWidget {
  static const String id = "init_page";

  @override
  _InitPageState createState() => _InitPageState();
}

class _InitPageState extends State<Init_page> {
  String? usuarioActual;
  String? fotoPerfil;
  String selectedGameMode = "Clásica"; // ✅ Se mantiene el modo de juego

  final List<GameMode> gameModes = [
    GameMode("Clásica", Icons.extension, "10 min", "Modo tradicional de ajedrez."
        " Cada jugador consta de 10 min para realizar sus movimientos",
        Colors.brown),
    GameMode("Principiante", Icons.verified, "30 min", "Ideal para quienes están"
        " aprendiendo. Cada jugador consta de 30 min para realizar sus "
        "movimientos", Colors.green),
    GameMode("Avanzado", Icons.timer_off, "5 min", "Para jugadores "
        "experimentados. Cada jugador consta de 5 min para realizar sus "
        "movimientos", Colors.red),
    GameMode("Relámpago", Icons.bolt, "3 min", "Modo para expertos. El tiempo es"
        " muy limitado, cada jugador cuenta con 3 minutos.", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15 min + 10 seg", "Cada jugada "
        "suma 10 segundos al tiempo del jugador.", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3 min + 2 seg", "Partidas rápidas"
        " con incremento de 2 segundos por jugada.", Colors.yellow),
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      usuarioActual = prefs.getString('usuario');
      fotoPerfil = prefs.getString('fotoPerfil'); // ✅ Se usará más adelante para la imagen de perfil
    });
  }

  Future<void> _cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario');
    await prefs.remove('fotoPerfil');

    Navigator.pop(context); // ✅ Cierra el menú antes de redirigir

    Future.delayed(Duration(milliseconds: 100), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => welcome_page()),
            (Route<dynamic> route) => false, // ✅ Elimina todas las pantallas previas
      );
    });
  }



  void _mostrarOpcionesUsuario(BuildContext context) {
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
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                onTap: () {
                  _cerrarSesion();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
            padding: EdgeInsets.only(right: 12), // ✅ Evita que el icono se salga por el lateral
            child: GestureDetector(
              onTap: () => _mostrarOpcionesUsuario(context),
              child: CircleAvatar(
                radius: 18, // ✅ Tamaño más equilibrado
                backgroundColor: Colors.white,
                backgroundImage: fotoPerfil != null ? NetworkImage(fotoPerfil!) : null,
                child: fotoPerfil == null ? Icon(Icons.person, color: Colors.black) : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (usuarioActual != null)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Bienvenido, $usuarioActual',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
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
              _buildInfoButton(context, mode.name, mode.description),
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

  Widget _buildInfoButton(BuildContext context, String title, String description) {
    return IconButton(
      icon: Icon(Icons.info_outline, color: Colors.blue, size: 22),
      onPressed: () {
        _showInfoDialog(context, title, description);
      },
    );
  }

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
              MaterialPageRoute(builder: (context) => BoardScreen(gameMode: selectedGameMode)),
            );
          },
          child: Text(
            'BUSCAR PARTIDA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
