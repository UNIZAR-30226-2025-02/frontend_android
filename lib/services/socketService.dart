import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../main.dart';
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
  String? _modoSeleccionado = "Clásica";

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();
  Future<void> initializeSocket(BuildContext context) async {
    _latestContext = context;
    if (_isInitialized) {
      print("⚠️ Socket ya inicializado.");
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
      print("⚠️ Token o ID no encontrado, abortando conexión.");
      return;
    }

    socket = IO.io(backendUrl, {
      'transports': ['websocket'],
      'query': {'token': token},
      'autoConnect': true,
    });
    //socket.clearListeners();
    _setupListeners(idJugador);
  }

  void _setupListeners(String idJugador) {
    socket.onConnect((_) {
      print("✅ Socket conectado correctamente.");
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      print("🔴 Socket desconectado.");
      showForceLogoutPopup("Se ha perdido la conexión con el servidor.");
    });

    socket.onConnectError((err) {
      print("⚠️ Error de conexión: $err");
    });

    socket.onError((err) {
      print("❌ Error general: $err");
    });
    //socket.on('friendRequest', (data) => _showFriendRequestPopup(data));
    //socket.on('challengeSent', (data) => _showChallengePopup(data));

    print("✅ Listeners configurados correctamente.");
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

    const int eloPorDefecto = 0;

    if (_color == 'white') {
      await prefs.setString('nombreBlancas', yo['nombreW']);
      await prefs.setInt('eloBlancas', eloPorDefecto);
      await prefs.setString('fotoBlancas', yo['fotoBlancas'] ?? 'none');

      await prefs.setString('nombreNegras', rival['nombreB']);
      await prefs.setInt('eloNegras', eloPorDefecto);
      await prefs.setString('fotoNegras', rival['fotoNegras'] ?? 'none');
    } else {
      await prefs.setString('nombreNegras', yo['nombreB']);
      await prefs.setInt('eloNegras', eloPorDefecto);
      await prefs.setString('fotoNegras', yo['fotoNegras'] ?? 'none');

      await prefs.setString('nombreBlancas', rival['nombreW']);
      await prefs.setInt('eloBlancas', eloPorDefecto);
      await prefs.setString('fotoBlancas', rival['fotoBlancas'] ?? 'none');
    }

    _nombreRival = _color == 'white' ? rival['nombreB'] : rival['nombreW'];
    _fotoRival = _color == 'white' ? rival['fotoNegras'] : rival['fotoBlancas'];

    _goToBoardScreen();
  }

  void _handleForceLogout(dynamic data, String idJugador) {
    String? idConectado;
    String? mensaje;

    if (data is List && data.isNotEmpty) {
      final primerElemento = data[0];
      if (primerElemento is Map<String, dynamic>) {
        idConectado = primerElemento['idJugador'];
        mensaje = primerElemento['message'];
      }
    } else if (data is Map<String, dynamic>) {
      idConectado = data['idJugador'];
      mensaje = data['message'];
    }

    if (idConectado == null || idConectado == idJugador) {
      showForceLogoutPopup(mensaje ?? "Sesión cerrada en otro dispositivo.");
    }
  }

  void _showPopupResultado(String mensaje, bool salir) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Partida finalizada", style: TextStyle(color: Colors.white)),
        content: Text(mensaje, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (salir) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showPopupSimple(String mensaje) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Información", style: TextStyle(color: Colors.white)),
        content: Text(mensaje, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cerrar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _handleSurrender() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("🏳️ Te has rendido", style: TextStyle(color: Colors.white)),
        content: Text("Partida finalizada.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Wellcome_page()),
                    (route) => false,
              );
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _handleDrawAccepted() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("🤝 Tablas aceptadas", style: TextStyle(color: Colors.white)),
        content: Text("La partida ha terminado en empate.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Wellcome_page()),
                    (route) => false,
              );
            },
            child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _handleDrawDeclined() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Solicitud de tablas rechazada"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

 /* void _showFriendRequestPopup(dynamic dataRaw) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;
    final userData = data[0];
    final nombre = userData["nombre"] ?? "Usuario desconocido";
    final idRemitente = userData["idJugador"].toString();

    final prefs = await SharedPreferences.getInstance();
    final miIdJugador = prefs.getString("idJugador");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("$nombre quiere ser tu amigo", style: TextStyle(color: Colors.white)),
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
          ElevatedButton(
            onPressed: () {
              socket.emit('accept-request', {
                "idJugador": idRemitente,
                "idAmigo": miIdJugador,
                "nombre": nombre,
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text("Aceptar", style: TextStyle(color: Colors.black)),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("¡Reto de partida en $modo!", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Rechazar", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              _modoSeleccionado = _mapearModo(modo); // Mapear el modo
              await prefs.setString('modoDeJuegoActivo', _modoSeleccionado ?? "Clásica"); // 💥 <- aquí

              socket.emit('accept-challenge', {
                "idRetador": idRetador,
                "idRetado": idRetado,
                "modo": modo,
              });

              Navigator.of(context).pop();
            },


            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: Text("Aceptar", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }*/

  void _goToBoardScreen() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    if (_gameId == null || _color == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String modoGuardado = prefs.getString('modoDeJuegoActivo') ?? "Clásica";

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BoardScreen(
          modoGuardado,   // 👈 aquí pasamos el modo REAL
          _color!,
          _gameId!,
          "null",
          0,
          0,
          0,
          0,
          _nombreRival ?? "Rival",
          _fotoRival ?? 'fotoPerfil.png',
        ),
      ),
    );
  }


  /*String _mapearModo(String modoServidor) {
    switch (modoServidor) {
      case "Punt_10":
        return "Clásica";
      case "Punt_30":
        return "Principiante";
      case "Punt_5":
        return "Avanzado";
      case "Punt_3":
        return "Relámpago";
      case "Punt_5_10":
        return "Incremento";
      case "Punt_3_2":
        return "Incremento exprés";
      default:
        return "Clásica";
    }
  }*/

  Future<void> connect(BuildContext context) async {
    _latestContext = context;
    if (!_isConnected) {
      await initializeSocket(context);
      socket.connect();
      print("🔌 Socket conectado.");
    } else {
      print("✅ Ya estaba conectado.");
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