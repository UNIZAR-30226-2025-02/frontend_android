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
  }

  Future<void> _startInitSequence() async {
    await _cargarUsuario(); // Espera a que idJugador esté listo
    await _initializeSocketAndStartMatchmaking();
  }

  Future<void> _initializeSocketAndStartMatchmaking() async {
    await socketService.connect(context); // 👈 Context de LoginPage
    socket = await socketService.getSocket(context);
    encontrarPartida(); // Ahora sí: ya puedes registrar listeners
  }


  Future<void> encontrarPartida() async {
    socket?.on('existing-game', (data) async{
      print("🧪 EXISTING-GAME DATA: $data (${data.runtimeType})");
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
            ),
          )
      );
    });

    socket?.on('game-ready', (data) {
      final idPartida = data[0]['idPartida'];
      _gameId = idPartida;
    });

    socket?.on('color', (data) async{
      if (idJugador == null) return;
      final jugadores = List<Map<String, dynamic>>.from(data[0]['jugadores']);
      final yo = jugadores.firstWhere((jugador) => jugador['id'] == idJugador, orElse: () => {});
      final rival = jugadores.firstWhere((jugador) => jugador['id'] != idJugador, orElse: () => {});
      if (yo.isNotEmpty && yo.containsKey('color')) {
        _gameColor = yo['color'];
        final prefs = await SharedPreferences.getInstance();

        if (_gameColor == 'white') {
          await prefs.setString('nombreBlancas', yo['nombreW']);
          await prefs.setInt('eloBlancas', yo['eloW']);
          await prefs.setString('nombreNegras', rival['nombreB']);
          await prefs.setInt('eloNegras', rival['eloB']);
        } else {
          await prefs.setString('nombreNegras', yo['nombreB']);
          await prefs.setInt('eloNegras', yo['eloB']);
          await prefs.setString('nombreBlancas', rival['nombreW']);
          await prefs.setInt('eloBlancas', rival['eloW']);
        }
        _intentarEntrarAPartida();
      }
    });
  }

  void _intentarEntrarAPartida() async {
    if (_yaEntramosAPartida || _gameId == null || _gameColor == null) return;

    _yaEntramosAPartida = true;

    final prefs = await SharedPreferences.getInstance();

    final miElo = _gameColor == 'white'
        ? prefs.getInt('eloBlancas') ?? 0
        : prefs.getInt('eloNegras') ?? 0;

    final rivalElo = _gameColor == 'white'
        ? prefs.getInt('eloNegras') ?? 0
        : prefs.getInt('eloBlancas') ?? 0;

    final rivalName = _gameColor == 'white'
        ? prefs.getString('nombreNegras') ?? "Rival"
        : prefs.getString('nombreBlancas') ?? "Rival";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BoardScreen(
            selectedGameMode,
            _gameColor!,
            _gameId!,
            "null",
            0,
            0,
            miElo,
            rivalElo,
            rivalName,
          ),
        ),
      );
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
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

    print("[MATCHMAKING] ❌ Emparejamiento cancelado manualmente.");
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
    print("[MATCHMAKING] 🔍 Enviando solicitud de findGame con $idJugador, mode: $selectedGameModeKey");
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
