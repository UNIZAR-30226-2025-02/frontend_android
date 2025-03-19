import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late IO.Socket socket;
  bool _isConnected = false; // Flag para evitar múltiples conexiones

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    final backendUrl = dotenv.env['SERVER_BACKEND'];

    if (backendUrl == null) {
      throw Exception("SERVER_BACKEND no está definido en el .env");
    }

    socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _setupListeners();
  }

  void _setupListeners() {
    socket.onConnect((_) {
      print("🟢 SOCKET CONECTADO");
      _isConnected = true;
    });

    //socket.emit('new-connection', {});


    socket.onDisconnect((_) {
      print("🔴 SOCKET DESCONECTADO");
      _isConnected = false;
    });

    socket.onConnectError((err) {
      print("⚠️ ERROR de conexión del socket: $err");
    });

    socket.onError((err) {
      print("❌ ERROR en el socket: $err");
    });
  }

  void connect() {
    if (!_isConnected) {
      socket.connect();
    }
  }

  void disconnect() {
    socket.disconnect();
  }

  IO.Socket getSocket() {
    return socket;
  }
}
