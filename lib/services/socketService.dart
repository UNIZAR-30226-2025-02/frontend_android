import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Presentation/wellcome.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false;
  bool _isInitialized = false;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// 🔹 Inicializa el socket y envía el token
  Future<void> initializeSocket(BuildContext context) async {
    if (_isInitialized) {
      print("⚠️ El socket ya estaba inicializado. No se vuelve a inicializar.");
      return;
    }
    _isInitialized = true;

    final backendUrl = dotenv.env['SERVER_BACKEND'];
    if (backendUrl == null) {
      print("❌ ERROR: SERVER_BACKEND no está definido en el .env");
      throw Exception("SERVER_BACKEND no está definido en el .env");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? idJugador = prefs.getString('idJugador');

    if (token == null || idJugador == null) {
      print("⚠️ No se puede conectar porque no hay token o ID de usuario.");
      return;
    }

    print("🔗 Conectando al backend: $backendUrl con ID: $idJugador");
    print("🔑 Token obtenido: ${token.isNotEmpty ? 'Sí' : 'No'}");

    socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'token': token}
    });

    _setupListeners(context, idJugador);

    socket.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito. ID del socket: ${socket.id}");
      _isConnected = true;

      print("📤 Registrando sesión en el servidor con ID: $idJugador...");
      socket.emit("register-session", idJugador);
    });
  }

  /// 🔹 Configura los listeners del socket
  void _setupListeners(BuildContext context, String idJugador) {
    print("🛠 Configurando listeners del socket...");

    socket.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito.");
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      print("🔴 SOCKET DESCONECTADO.");
      _showForceLogoutPopup(context, "Se ha perdido la conexión con el servidor.");
    });

    socket.onConnectError((err) {
      print("⚠️ ERROR de conexión del socket: $err");
    });

    socket.onError((err) {
      print("❌ ERROR en el socket: $err");
    });

    /// 🔥 **Evento force-logout** (Comparación correcta del ID del jugador)
    socket.on("force-logout", (data) async {
      print("🚨 Recibido evento 'force-logout' del servidor!");
      print("📌 Data recibido: $data");

      // 🔹 Extraer correctamente el ID del jugador del `Map`
      String? idJugadorConectado;
      if (data is List && data.isNotEmpty) {
        if (data[0] is Map<String, dynamic> && data[0].containsKey('idJugador')) {
          idJugadorConectado = data[0]['idJugador'];
        }
      } else if (data is Map<String, dynamic> && data.containsKey('idJugador')) {
        idJugadorConectado = data['idJugador'];
      }

      if (idJugadorConectado == null) {
        print("⚠️ No se recibió un ID de jugador válido en el evento 'force-logout'.");
        return;
      }

      print("📌 ID del jugador que se ha conectado: $idJugadorConectado");
      print("📌 ID del jugador local: $idJugador");

      // 🔹 Si el jugador que se ha conectado es el mismo, expulsar al actual
      if (idJugadorConectado == idJugador) {
        print("🔴 Sesión duplicada detectada. Cerrando sesión...");
        _showForceLogoutPopup(context, "Tu cuenta ha sido iniciada en otro dispositivo.");
      } else {
        print("⚠️ Recibido 'force-logout' pero el ID no coincide. Ignorado.");
      }
    });

    socket.onAny((event, data) {
      print("📥 Evento recibido: $event - Data: $data");
    });

    print("✅ Listeners configurados correctamente.");
  }

  /// 🔹 Muestra un `AlertDialog` antes de cerrar sesión
  void _showForceLogoutPopup(BuildContext context, String message) {
    print("📢 Mostrando pop-up: $message");

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Sesión cerrada"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Cerrar el pop-up
                  await _disconnectAndRedirect(context);
                },
                child: Text("Aceptar"),
              ),
            ],
          );
        },
      );
    }
  }

  /// 🔹 Cierra la sesión y redirige al usuario a `Wellcome_page`
  Future<void> _disconnectAndRedirect(BuildContext context) async {
    print("🗑 Eliminando datos de usuario...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print("🔌 Desconectando el socket...");
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();

    _isConnected = false;
    _isInitialized = false;

    print("🔄 Redirigiendo a la pantalla de bienvenida...");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Wellcome_page()),
          (Route<dynamic> route) => false,
    );
  }

  /// 🔹 Conecta al socket si no está ya conectado
  Future<void> connect(BuildContext context) async {
    print("🔄 Intentando conectar al socket...");
    if (!_isConnected) {
      await initializeSocket(context);
      socket.connect();
      print("🔗 Socket en proceso de conexión...");
    } else {
      print("✅ El socket ya está conectado.");
    }
  }

  /// 🔹 Desconecta el socket manualmente
  void disconnect() {
    print("🔌 Desconectando el socket manualmente...");
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
    _isConnected = false;
    _isInitialized = false;
  }

  /// 🔹 Obtiene la instancia del socket
  Future<IO.Socket> getSocket() async {
    if (!_isInitialized) {
      print("⚠️ El socket no estaba inicializado. Inicializándolo ahora...");
      await initializeSocket;
    }
    return socket;
  }
}
