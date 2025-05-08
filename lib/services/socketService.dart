

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../main.dart';
import '../pages/Game/friends.dart';
import '../pages/Presentation/wellcome.dart';
import '../pages/inGame/board.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false;
  bool _isInitialized = false;
  BuildContext? _latestContext;

  // 📌 Variables internas para partida
  String? _gameId;
  String? _color;
  String? _nombreRival;
  String? _fotoRival;
  String? _modoSeleccionado = "Rápida";

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();
  Future<void> initializeSocket(BuildContext context) async {
    _latestContext = context;
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    final backendUrl = dotenv.env['SERVER_BACKEND'];
    if (backendUrl == null) {
      throw Exception("SERVER_BACKEND no definido");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? idJugador = prefs.getString('idJugador');

    if (token == null || idJugador == null) {
      return;
    }

    socket = IO.io(backendUrl, {
      'transports': ['websocket'],
      'query': {'token': token},
      'autoConnect': true,
    });
    _setupListeners(idJugador);
  }

  void _setupListeners(String idJugador) {
    socket.onConnect((_) {
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      showForceLogoutPopup("Se ha perdido la conexión con el servidor.");
    });

    socket.onConnectError((err) {
    });

    socket.onError((err) {
    });

    // 👇 Eventos importantes
    socket.on('game-ready', (data) => _handleGameReady(data));
    socket.on('color', (data) async=> _handleColor(data));
    socket.on('friendRequest', (data) async=> _showFriendRequestPopup(data));
    socket.on('challengeSent', (data) async=> _showChallengePopup(data));

  }
  void _handleGameReady(dynamic data) {
    _gameId = data[0]['idPartida'];
  }

  void _handleColor(dynamic data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');

    if (idJugador == null) return;

    final jugadores = List<Map<String, dynamic>>.from(data[0]['jugadores']);
    final yo = jugadores.firstWhere((jugador) => jugador['id'] == idJugador, orElse: () => {});
    final rival = jugadores.firstWhere((jugador) => jugador['id'] != idJugador, orElse: () => {});

    if (yo.isEmpty) return;

    _color = yo['color'];

    if (_color == 'white') {
      await prefs.setString('nombreBlancas', yo['nombreW']);
      await prefs.setInt('eloBlancas', (yo['eloW'] as num).toInt());
      await prefs.setString('fotoBlancas', yo['fotoBlancas'] ?? 'none');

      await prefs.setString('nombreNegras', rival['nombreB']);
      await prefs.setInt('eloNegras', (rival['eloB'] as num).toInt());
      await prefs.setString('fotoNegras', rival['fotoNegras'] ?? 'none');
    } else {
      await prefs.setString('nombreNegras', yo['nombreB']);
      await prefs.setInt('eloNegras', (yo['eloB'] as num).toInt());
      await prefs.setString('fotoNegras', yo['fotoNegras'] ?? 'none');

      await prefs.setString('nombreBlancas', rival['nombreW']);
      await prefs.setInt('eloBlancas', (rival['eloW'] as num).toInt());
      await prefs.setString('fotoBlancas', rival['fotoBlancas'] ?? 'none');
    }

    _nombreRival = _color == 'white' ? rival['nombreB'] : rival['nombreW'];
    _fotoRival = _color == 'white' ? rival['fotoNegras'] : rival['fotoBlancas'];

    _goToBoardScreen();
  }

  void _showFriendRequestPopup(dynamic dataRaw) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
    final userData = data[0];
    final nombre = userData["nombreJugador"] ?? "Usuario desconocido";
    final idRemitente = userData["idJugador"].toString();

    final prefs = await SharedPreferences.getInstance();
    final miIdJugador = prefs.getString("idJugador");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.blueAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "$nombre quiere ser tu amigo",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Text(
          "¿Deseas aceptar la solicitud de amistad?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              socket.emit('reject-request', {
                "idJugador": idRemitente,
                "idAmigo": miIdJugador,
                "nombre": nombre,
              });
              Navigator.of(context).pop();
            },
            child: Text("Rechazar", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              socket.emit('accept-request', {
                "idJugador": idRemitente,
                "idAmigo": miIdJugador,
                "nombre": nombre,
              });
              Friends_Page.onFriendListShouldRefresh?.call();
              Navigator.of(context).pop();
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showChallengePopup(dynamic dataRaw) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final data = (dataRaw as List)[0];
    final idRetador = data['idRetador'].toString();
    final idRetado = data['idRetado'].toString();
    final modo = data['modo'];
    final retador = data['nombreRetador'];
    final modoVisible = _mapearModo(modo); // nuevo

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.sports_kabaddi, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("¡Reto recibido!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "$retador te ha retado a una partida en modo $modoVisible.\n¿Deseas aceptar?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Rechazar", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              _modoSeleccionado = _mapearModo(modo);
              await prefs.setString('modoDeJuegoActivo', _modoSeleccionado ?? "Rápida");

              socket.emit('accept-challenge', {
                "idRetador": idRetador,
                "idRetado": idRetado,
                "modo": modo,
              });

              Navigator.of(context).pop();
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _goToBoardScreen() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    if (_gameId == null || _color == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String modoGuardado = prefs.getString('modoDeJuegoActivo') ?? "Rápida";
    int whiteElo = prefs.getInt('eloBlancas') ?? 0;
    int blackElo = prefs.getInt('eloNegras') ?? 0;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          modoGuardado,   // 👈 aquí pasamos el modo REAL
          _color!,
          _gameId!,
          "null",
          0,
          0,
          whiteElo,
          blackElo,
          _nombreRival ?? "Rival",
          _fotoRival ?? 'fotoPerfil.png',
        ),
      ),
    );
  }


  String _mapearModo(String modoServidor) {
    switch (modoServidor) {
      case "Punt_10":
        return "Rápida";
      case "Punt_30":
        return "Clásica";
      case "Punt_5":
        return "Blitz";
      case "Punt_3":
        return "Bullet";
      case "Punt_5_10":
        return "Incremento";
      case "Punt_3_2":
        return "Incremento exprés";
      default:
        return "Rápida";
    }
  }

  Future<void> connect(BuildContext context) async {
    _latestContext = context;
    if (!_isConnected) {
      await initializeSocket(context);
      socket.connect();
    } else {
    }
  }

  void disconnect() {
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
    _isConnected = false;
    _isInitialized = false;
  }

  Future<IO.Socket> getSocket(BuildContext context) async {
    if (!_isInitialized) {
      await initializeSocket(context);
    }
    return socket;
  }

  void showForceLogoutPopup(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Sesión cerrada", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              disconnect();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => Wellcome_page()),
                    (_) => false,
              );
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }
}
