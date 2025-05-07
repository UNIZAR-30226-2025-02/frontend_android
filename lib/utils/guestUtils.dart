import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/Presentation/wellcome.dart';
import '../pages/Game/init.dart';
import '../services/socketService.dart';

Future<void> verificarAccesoInvitado(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final estadoUser = prefs.getString('estadoUser');

  if (estadoUser == 'guest') {
    print("⚠️ Invitado detectado. Mostrando opciones de acceso.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarDialogoOpcionesInvitado(context);
    });
  }
}

void _mostrarDialogoOpcionesInvitado(BuildContext context) {
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
          Icon(Icons.lock_outline, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text("Acceso restringido", style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Text(
        "Esta sección es solo para usuarios registrados. Puedes iniciar sesión o seguir como invitado.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacementNamed(context, Init_page.id);
          },
          child: Text("Seguir como invitado", style: TextStyle(color: Colors.blueAccent)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await _cerrarSesionInvitado(context);
          },
          child: Text("Iniciar sesión", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

Future<void> _cerrarSesionInvitado(BuildContext context) async {
  final safeContext = context;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken');
  final idJugador = prefs.getString('idJugador');
  final backendUrl = dotenv.env['SERVER_BACKEND'];

  try {
    final response = await http.post(
      Uri.parse("${backendUrl}borrarInvitado"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({"id": idJugador}),
    );

    if (response.statusCode == 200) {
      print("✅ Invitado eliminado correctamente.");
    } else {
      print("❌ Error al borrar invitado: ${response.body}");
    }
  } catch (e) {
    print("❌ Error al conectar con el servidor: $e");
  }

  await prefs.clear();

  print("🔌 Desconectando socket...");
  SocketService socketService = SocketService();
  socketService.socket.clearListeners();
  socketService.socket.disconnect();
  socketService.socket.dispose();

  await showDialog(
    context: safeContext,
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
        "Tu sesión como invitado ha sido cerrada.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(safeContext).pop(),
          child: Text("Aceptar", style: TextStyle(color: Colors.blueAccent)),
        ),
      ],
    ),
  );

  Navigator.pushReplacementNamed(safeContext, Wellcome_page.id);
}
