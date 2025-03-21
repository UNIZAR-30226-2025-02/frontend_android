import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Presentation/wellcome.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false; // Flag para evitar múltiples conexiones
  bool _isInitialized = false; // Evita múltiples inicializaciones

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
    String? idJugador = prefs.getString('idJugador'); // 📌 Obtener ID del jugador

    if (token == null || idJugador == null) {
      print("⚠️ No se puede conectar porque no hay token o ID de usuario.");
      return;
    }

    print("🔗 Conectando al backend: $backendUrl con ID: $idJugador");
    print("🔑 Token obtenido: ${token.isNotEmpty ? 'Sí' : 'No'}");

    socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {
        'token': token
      }
    });

    _setupListeners(context);

    socket?.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito.");
      _isConnected = true;

      // 📢 🔥 Registrar esta sesión en el backend
      print("📤 Registrando sesión en el servidor...");
      socket?.emit("register-session", idJugador);
    });
  }


  void _setupListeners(BuildContext context) {
    print("🛠 Configurando listeners del socket...");

    socket?.onConnect((_) {
      print("✅ SOCKET CONECTADO con éxito.");
      _isConnected = true;
    });

    socket?.onDisconnect((_) {
      print("🔴 SOCKET DESCONECTADO. Intentando reconectar...");
      _isConnected = false;
      Future.delayed(Duration(seconds: 2), () {
        if (!_isConnected) {
          print("🔄 Reintentando conexión...");
          socket?.connect();
        }
      });
    });

    socket?.onConnectError((err) {
      print("⚠️ ERROR de conexión del socket: $err");
    });

    socket?.onError((err) {
      print("❌ ERROR en el socket: $err");
    });

    /// 🔥 **Evento force-logout**
    socket?.on("force-logout", (data) async {
      print("🚨 Recibido evento 'force-logout' del servidor!");
      await _handleForceLogout(context);
    });

    socket?.onAny((event, data) {
      print("📥 Evento recibido: $event - Data: $data");
    });

    print("✅ Listeners configurados correctamente.");
  }

  void _registerForceLogout(BuildContext context) {
    print("🔄 Registrando evento 'force-logout'...");
    socket?.on("force-logout", (data) async {
      print("🚨 Recibido evento 'force-logout' del servidor!");
      await _handleForceLogout(context);
    });
  }

  Future<void> _handleForceLogout(BuildContext context) async {
    print("🔴 Ejecutando _handleForceLogout()...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioActual = prefs.getString('usuario');
    String? idJugador = prefs.getString('idJugador');

    if (usuarioActual != null && idJugador != null) {
      print("📤 Enviando 'logout' al servidor con ID: $idJugador...");
      socket?.emit("logout", {"idJugador": idJugador});
    } else {
      print("⚠️ No se pudo enviar 'logout' porque no hay usuario autenticado.");
    }

    print("🗑 Eliminando datos de usuario...");
    await prefs.clear(); // 🔥 Borrar sesión

    print("🔌 Desconectando el socket...");
    socket?.disconnect();

    // 🔄 Evitar que el usuario siga reconectándose automáticamente después del logout
    socket?.clearListeners(); // 🔥 Eliminar todos los listeners previos

    Future.delayed(Duration(seconds: 5), () {
      print("🔄 Volviendo a inicializar el socket después de 5 segundos...");
      if (!socket!.connected) {
        socket?.connect(); // 🔄 Reintentar la conexión después del logout
      }
    });

    if (context.mounted) {
      print("📢 Mostrando alerta de cierre de sesión...");
      showDialog(
        context: context,
        barrierDismissible: false, // Evita que el usuario cierre el diálogo
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Sesión cerrada"),
            content: Text("Tu cuenta ha sido iniciada en otro dispositivo."),
            actions: [
              TextButton(
                onPressed: () {
                  print("🔄 Redirigiendo a la pantalla de bienvenida...");
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Wellcome_page()),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text("Aceptar"),
              ),
            ],
          );
        },
      );
    } else {
      print("⚠️ No se pudo mostrar la alerta porque el contexto ya no está montado.");
    }
  }


  Future<void> connect(BuildContext context) async {
    print("🔄 Intentando conectar al socket...");
    if (!_isConnected) {
      await initializeSocket(context); // 🔥 Asegura que el socket esté inicializado antes de conectarse
      socket?.connect();
      print("🔗 Socket en proceso de conexión...");
    } else {
      print("✅ El socket ya está conectado.");
    }
  }

  void disconnect() {
    print("🔌 Desconectando el socket manualmente...");
    socket?.disconnect();
  }

  Future<IO.Socket> getSocket() async {
    if (!_isInitialized) {
      print("⚠️ El socket no estaba inicializado. Inicializándolo ahora...");
      await initializeSocket;
    }
    return socket!;
  }
}
