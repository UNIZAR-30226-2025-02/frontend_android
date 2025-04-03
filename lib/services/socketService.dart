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
  BuildContext? _latestContext;


  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// 🔹 Inicializa el socket y envía el token
  Future<void> initializeSocket(BuildContext context) async {
    _latestContext = context;

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

    //socket.clearListeners(); // ✅ evita duplicaciones
    _setupListeners(context, idJugador);

    /*socket.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito. ID del socket: ${socket.id}");
      _isConnected = true;

      // 🔁 Re-registrar los listeners cada vez que se conecte
      _setupListeners(context, idJugador);  // <--- AÑADE ESTO

      print("📤 Registrando sesión en el servidor con ID: $idJugador...");
      socket.emit("register-session", idJugador);
    });*/

  }

  void _setupListeners(BuildContext context, String idJugador) {
    print("🛠 Configurando listeners del socket...");

    socket.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito.");
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      print("🔴 SOCKET DESCONECTADO.");
      if (context.mounted){
        showForceLogoutPopup(context, "Se ha perdido la conexión con el servidor.");
      }
    });

    socket.onConnectError((err) {
      print("⚠️ ERROR de conexión del socket: $err");
    });

    socket.onError((err) {
      print("❌ ERROR en el socket: $err");
    });

    socket.on("force-logout", (data) async {
      print("🚨 Recibido evento 'force-logout' del servidor!");
      print("📌 Data recibido: $data");

      String? idJugadorConectado;
      String? mensaje;

      // Manejo flexible del formato recibido
      if (data is List && data.isNotEmpty) {
        final primerElemento = data[0];
        if (primerElemento is Map<String, dynamic>) {
          idJugadorConectado = primerElemento['idJugador'];
          mensaje = primerElemento['message'];
        }
      } else if (data is Map<String, dynamic>) {
        idJugadorConectado = data['idJugador'];
        mensaje = data['message'];
      }

      // Fallback: si no viene el id, forzar cierre de sesión
      if (idJugadorConectado == null || idJugadorConectado == idJugador) {
        print("🔴 Sesión duplicada detectada o sin ID. Cerrando sesión...");
        showForceLogoutPopup(
          _latestContext,
          mensaje ?? "Tu cuenta ha sido iniciada en otro dispositivo.",
        );
      } else {
        print("⚠️ 'force-logout' recibido pero ID no coincide. Ignorado.");
      }
    });

    print("✅ Listeners configurados correctamente.");
  }

  void showForceLogoutPopup(BuildContext? context, String message) {
    print("📢 Mostrando pop-up: $message");

    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
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
                  Navigator.of(context).pop();
                  await _disconnectAndRedirect(context);
                },
                child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        },
      );
    }
  }

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

  Future<void> connect(BuildContext context) async {
    _latestContext=context;
    print("🔄 Intentando conectar al socket...");
    if (!_isConnected) {
      await initializeSocket(context);
      socket.connect();
      print("🔗 Socket en proceso de conexión...");
    } else {
      print("✅ El socket ya está conectado.");
    }
  }

  void disconnect() {
    print("🔌 Desconectando el socket manualmente...");
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
    _isConnected = false;
    _isInitialized = false;
  }

  /// ✅ CORREGIDO: se pasa el `BuildContext` y se llama bien a `initializeSocket`
  Future<IO.Socket> getSocket(BuildContext context) async {
    if (!_isInitialized) {
      print("⚠️ El socket no estaba inicializado. Inicializándolo ahora...");
      await initializeSocket(context);
    }
    return socket;
  }
}
