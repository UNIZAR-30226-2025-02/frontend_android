import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;
  bool _isConnected = false; // Flag para evitar múltiples conexiones
  bool _isInitialized = false; // Evita múltiples inicializaciones

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  /// 🔹 Inicializa el socket y envía el token
  Future<void> initializeSocket() async {
    if (_isInitialized) return; // Evita múltiples inicializaciones
    _isInitialized = true;

    final backendUrl = dotenv.env['SERVER_BACKEND'];
    if (backendUrl == null) {
      throw Exception("SERVER_BACKEND no está definido en el .env");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {
        'token': token ?? '' // 🔥 Enviar el token en la URL como parámetro
      }
    });

    _setupListeners();
  }

  void _setupListeners() {
    socket?.onConnect((_) {
      print("🟢 SOCKET CONECTADO");
      _isConnected = true;
    });

    socket?.onDisconnect((_) {
      print("🔴 SOCKET DESCONECTADO");
      _isConnected = false;
    });

    socket?.onConnectError((err) {
      print("⚠️ ERROR de conexión del socket: $err");
    });

    socket?.onError((err) {
      print("❌ ERROR en el socket: $err");
    });

    socket?.on("force-logout", (data) {
      socket?.disconnect();
    });
  }

  Future<void> connect() async {
    if (!_isConnected) {
      await initializeSocket(); // 🔥 Asegura que el socket esté inicializado antes de conectarse
      socket?.connect();
    }
  }

  void disconnect() {
    socket?.disconnect();
  }

  Future<IO.Socket> getSocket() async {
    if (!_isInitialized) {
      await initializeSocket();
    }
    return socket!;
  }
}
