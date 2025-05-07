import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:frontend_android/pages/inGame/board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/socketService.dart';
import '../../utils/photoUtils.dart';
import '../../widgets/app_layout.dart';


class Init_page extends StatefulWidget {
  static const String id = "init_page";

  @override
  _InitPageState createState() => _InitPageState();
}

class _InitPageState extends State<Init_page> {
  String? usuarioActual;
  String? idJugador;
  String? fotoPerfil;
  String selectedGameMode = "Clásica";
  String selectedGameModeKey = "clasica";
  bool _buscandoPartida = false;
  bool _yaEntramosAPartida = false;
  String? _gameId;
  String? _gameColor;
  late Future<Map<String, dynamic>> resumenFuture;
  String? serverBackend;
  String? userId;

  SocketService socketService = SocketService();
  IO.Socket? socket;

  final List<GameMode> gameModes = [
    GameMode("Clásica", Icons.extension, "10 min", "Modo tradicional de ajedrez.", Colors.brown),
    GameMode("Principiante", Icons.verified, "30 min", "Ideal para quienes están aprendiendo.", Colors.green),
    GameMode("Avanzado", Icons.timer_off, "5 min", "Para jugadores experimentados.", Colors.red),
    GameMode("Relámpago", Icons.bolt, "3 min", "Modo para expertos. Tiempo muy limitado.", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15 min + 10 seg", "Cada jugada suma 10 segundos.", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3 min + 2 seg", "Partidas rápidas con 2 seg por jugada.", Colors.yellow),
  ];

  final Map<String, String> modoBackendMap = {
    "Clásica": "Punt_10",
    "Principiante": "Punt_30",
    "Avanzado": "Punt_5",
    "Relámpago": "Punt_3",
    "Incremento": "Punt_5_10",
    "Incremento exprés": "Punt_3_2",
  };

  @override
  void initState() {
    super.initState();
    _startInitSequence();
    resumenFuture = _fetchResumenPartidas();
  }

  Future<void> _startInitSequence() async {
    await _cargarUsuario(); // Espera a que idJugador esté listo
    await _initializeSocketAndStartMatchmaking();
    print("Socket ID en friends: ${socket?.id}");
  }

  Future<void> _initializeSocketAndStartMatchmaking() async {
    await socketService.connect(context); // 👈 Context de LoginPage
    socket = await socketService.getSocket(context);
    print("Socket ID en init: ${socket?.id}");
    encontrarPartida(); // Ahora sí: ya puedes registrar listeners
  }


  Future<void> encontrarPartida() async {
    socket?.on('existing-game', (data) async{
      if (_yaEntramosAPartida) return;
      _yaEntramosAPartida = true;
      final gameData = data[0];
      final gameId = gameData['gameID'];
      final pgnRaw = gameData['pgn'];
      final pgn = (pgnRaw is List)
          ? pgnRaw.join('\n')  // 🔁 Unís el pgn en un String
          : pgnRaw?.toString() ?? "";
      final color = gameData['color'];
      final timeLeftW = gameData['timeLeftW'];
      final timeLeftB = gameData['timeLeftB'];
      final myElo = gameData['miElo'];
      final rivalElo = gameData['eloRival'];
      final gameMode = gameData['gameMode'];
      final rivalName = gameData['nombreRival'];
      final rivalFoto = gameData['foto_rival'];
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BoardScreen(
              gameMode ?? "",
              color ?? "",
              gameId ?? "",
              pgn ?? "",
              timeLeftW ?? 0,
              timeLeftB ?? 0,
              myElo ?? 0,
              rivalElo ?? 0,
              rivalName ?? "Jugador Rival",
              rivalFoto ?? "none",
            ),
          )
      );
    });

    socket?.on('game-ready', (data) {
      final idPartida = data[0]['idPartida'];
      _gameId = idPartida;
    });

  }

  Future<void> _cargarUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final foto = prefs.getString('fotoPerfil');

    setState(() {
      usuarioActual = prefs.getString('usuario');
      idJugador = prefs.getString('idJugador');
      fotoPerfil = getRutaSeguraFoto(foto);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Column(
        children: [
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'PARTIDAS ONLINE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: resumenFuture,
              builder: (context, snapshot) {
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: gameModes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Tarjeta resumen como primer ítem
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.blueAccent, // 👈 aquí aplicamos el color
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          "Error al cargar partidas recientes",
                          style: TextStyle(color: Colors.redAccent),
                        );
                      }

                      final data = snapshot.data as Map<String, dynamic>;
                      final resultados = data['resultados'] as List<String>;
                      final racha = data['racha'] as int;

                      return Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.history, color: Colors.blueAccent),
                                SizedBox(width: 8),
                                Text(
                                  "Últimas 5 partidas",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: resultados.reversed.map((resultado) {
                                switch (resultado) {
                                  case "victoria":
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                                    );
                                  case "derrota":
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.cancel, color: Colors.red, size: 28),
                                    );
                                  case "tablas":
                                  default:
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.remove_circle, color: Colors.grey, size: 28),
                                    );
                                }
                              }).toList(),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (racha >= 5)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 0, right: 8),
                                    child: Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                                  ),
                                Text(
                                  "Racha de victorias: $racha",
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    // Tarjetas de modos de juego
                    final modo = gameModes[index - 1];
                    return _buildGameButton(context, modo);
                  },
                );
              },
            ),
          ),
          _buildBuscarPartidaButton(context),
          BottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget buildResumenPartidas() {
    return FutureBuilder(
      future: _fetchResumenPartidas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              color: Colors.blueAccent, // 👈 aquí añadimos el color azul que quieres
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Error al cargar partidas recientes"),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;
        final resultados = data['resultados'] as List<String>;
        final racha = data['racha'] as int;

        return Card(
          color: Colors.black87,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Últimas 5 partidas",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  children: resultados.map((resultado) {
                    switch (resultado) {
                      case "victoria":
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.check_circle, color: Colors.green),
                        );
                      case "derrota":
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.cancel, color: Colors.red),
                        );
                      case "tablas":
                      default:
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.remove_circle, color: Colors.grey),
                        );
                    }
                  }).toList(),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "Racha de victorias: $racha",
                      style: TextStyle(color: Colors.white),
                    ),
                    if (racha >= 5)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                      )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchResumenPartidas() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');
    serverBackend = dotenv.env['SERVER_BACKEND'];

    if (userId == null || serverBackend == null) {
      throw Exception("Faltan datos necesarios (userId o backend)");
    }

    final partidasUri = Uri.parse('$serverBackend/buscarUlt5PartidasDeUsuario?id=$userId');
    final userInfoUri = Uri.parse('$serverBackend/getUserInfo?id=$userId');

    final partidasRes = await http.get(partidasUri);
    final userInfoRes = await http.get(userInfoUri);

    if (partidasRes.statusCode != 200 || userInfoRes.statusCode != 200) {
      throw Exception("Error al obtener datos del backend");
    }

    final partidas = jsonDecode(partidasRes.body) as List<dynamic>;
    final userInfo = jsonDecode(userInfoRes.body);
    print("🧪 Datos recibidos de getUserInfo:");
    print(userInfo);

    List<String> resultados = partidas.map<String>((partida) {
      final ganadorId = partida['Ganador'];
      if (ganadorId == userId) return "victoria";
      if (ganadorId == null || ganadorId == "null") return "tablas";
      return "derrota";
    }).toList();

    final racha = userInfo['actualStreak'] ?? 0;

    return {
      'resultados': resultados,
      'racha': racha,
    };
  }

  Widget _buildGameButton(BuildContext context, GameMode mode) {
    final bool isSelected = selectedGameMode == mode.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.blue,
            width: 2,
          ),
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
              backgroundColor: isSelected ? Colors.white : Colors.blue,
              foregroundColor: isSelected ? Colors.blue : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blue),
            ),
            onPressed: () {
              setState(() {
                selectedGameMode = mode.name;
              });
            },
            child: Text("Jugar"),
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
        height: 60,
        child: _buscandoPartida
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: null,
              icon: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              label: Text("Emparejando...", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cancelarEmparejamiento,
              icon: Icon(Icons.close, color: Colors.white),
              label: Text("Cancelar", style: TextStyle(color: Colors.white)),
            )
          ],
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => _buscarPartida(context),
          child: Text('BUSCAR PARTIDA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ),
    );
  }

  void _cancelarEmparejamiento() {
    setState(() {
      _buscandoPartida = false;
    });

    socket?.emit('cancel-pairing', {
      'idJugador': idJugador,
    });
  }

  Widget _buildInfoButton(BuildContext context, String title, String description) {
    return IconButton(
      icon: Icon(Icons.info_outline, color: Colors.blue, size: 22),
      onPressed: () {
        _showInfoDialog(context, title, description);
      },
    );
  }

  void _buscarPartida(BuildContext context) async{
    if (usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Usuario no autenticado")),
      );
      return;
    }

    setState(() {
      _buscandoPartida = true;
    });

    selectedGameModeKey = modoBackendMap[selectedGameMode] ?? "Clásica";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('modoDeJuegoActivo', selectedGameMode);


    socket?.emit('find-game', {
      'idJugador': idJugador,
      'mode': selectedGameModeKey
    });
  }
}

void _showInfoDialog(BuildContext context, String title, String description) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue),
        ),
        title: Text(title,
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        content: Text(description, style: TextStyle(color: Colors.white)),
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

class GameMode {
  final String name;
  final IconData icon;
  final String time;
  final String description;
  final Color color;

  GameMode(this.name, this.icon, this.time, this.description, this.color);
}
