import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GameMode {
  final String name;
  final IconData icon;
  final String time;
  final String description;
  final Color color;

  GameMode(this.name, this.icon, this.time, this.description, this.color);
}

class Friends_Page extends StatefulWidget {
  static const String id = "friends_page";

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<Friends_Page> {
  late IO.Socket socket;
  String? idJugador;
  String? nombreJugador;
  String searchInput = "";
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> friends = [];

  final Map<String, String> modoMapeado = {
    "Clásica": "Punt_10",
    "Principiante": "Punt_30",
    "Avanzado": "Punt_5",
    "Relámpago": "Punt_3",
    "Incremento": "Punt_5_10",
    "Incremento exprés": "Punt_3_2"
  };

  final List<GameMode> gameModes = [
    GameMode("Clásica", Icons.extension, "10 min", "Modo tradicional", Colors.brown),
    GameMode("Principiante", Icons.verified, "30 min", "Ideal para nuevos", Colors.green),
    GameMode("Avanzado", Icons.timer_off, "5 min", "Más desafiante", Colors.red),
    GameMode("Relámpago", Icons.bolt, "3 min", "Rápido", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15+10s", "Incremental", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3+2s", "Incremento rápido", Colors.yellow),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSocketAndUser();
  }

  Future<void> _initializeSocketAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? myId = prefs.getString('idJugador');
    final String? myNombre = prefs.getString('usuario');

    if (myId == null || myNombre == null) {
      print("⚠️ No se encontró idJugador o nombre en SharedPreferences.");
      return;
    }

    idJugador = myId;
    nombreJugador = myNombre;

    socket = IO.io(
      'https://checkmatex-gkfda9h5bfb0gsed.spaincentral-01.azurewebsites.net',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket conectado desde ID: $idJugador");
      socket.emit("getFriendsAndUsers", {"idJugador": idJugador});
    });

    _configureSocketListeners();
  }

  void _configureSocketListeners() {
    socket.on("friendsAndUsers", (data) {
      setState(() {
        friends = List<Map<String, dynamic>>.from(data['friends']);
      });
    });

    socket.on("friendRequest", (data) {
      final String idRemitente = data["idJugador"];

      if (idJugador != null && idRemitente != idJugador) {
        _showFriendRequestDialog(idRemitente);
      }
    });

    socket.on("request-accepted", (data) {
      final String nombre = data["nombre"];
      _showInfoDialog("✅ $nombre ha aceptado tu solicitud de amistad.");
    });

    socket.on("request-rejected", (data) {
      final String nombre = data["nombre"];
      _showInfoDialog("❌ $nombre ha rechazado tu solicitud de amistad.");
    });
  }

  void _sendFriendRequest(String idAmigo) {
    if (idJugador != null && idAmigo != idJugador) {
      print("📤 Emitiendo 'addFriend': idJugador: $idJugador, idAmigo: $idAmigo");
      socket.emit('add-friend', {
        'idJugador': idJugador,
        'idAmigo': idAmigo,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Solicitud enviada."),
        backgroundColor: Colors.orange,
      ));
    }
  }

  void _showFriendRequestDialog(String idRemitente) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Solicitud de amistad"),
          content: Text("Tienes una nueva solicitud de amistad."),
          actions: [
            TextButton(
              onPressed: () {
                socket.emit('reject-request', {
                  "idJugador": idJugador,
                  "idAmigo": idRemitente,
                });
                Navigator.of(context).pop();
              },
              child: Text("Rechazar"),
            ),
            TextButton(
              onPressed: () {
                socket.emit('accept-request', {
                  "idJugador": idJugador,
                  "idAmigo": idRemitente,
                });
                Navigator.of(context).pop();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Información"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Aceptar"),
          )
        ],
      ),
    );
  }

  Future<void> _buscarUsuariosBackend() async {
    if (searchInput.trim().isEmpty || idJugador == null) return;

    final uri = Uri.parse(
      'https://checkmatex-gkfda9h5bfb0gsed.spaincentral-01.azurewebsites.net/buscarUsuarioPorUser?NombreUser=${Uri.encodeComponent(searchInput.trim())}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          suggestions = data
              .where((u) =>
          u['NombreUser'] != nombreJugador &&
              !friends.any((f) => f['NombreUser'] == u['NombreUser']))
              .cast<Map<String, dynamic>>()
              .toList();
        });
      } else {
        setState(() => suggestions = []);
      }
    } catch (e) {
      print("❌ Error buscando usuarios: $e");
      setState(() => suggestions = []);
    }
  }

  void _challengeFriend(String idRetado, String modoNombre) {
    final modoBackend = modoMapeado[modoNombre] ?? "Punt_10";
    socket.emit('challengeFriend', {
      'idRetador': idJugador,
      'idRetado': idRetado,
      'modo': modoBackend,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Reto enviado en modo $modoNombre"),
      backgroundColor: Colors.green,
    ));
  }

  void _showGameModes(String idAmigo) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: gameModes.map((mode) {
            return ListTile(
              leading: Icon(mode.icon, color: mode.color),
              title: Text(mode.name, style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _challengeFriend(idAmigo, mode.name);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: AppLayout(
        child: Column(
          children: [
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() => searchInput = value);
                        _buscarUsuariosBackend();
                      },
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Buscar usuario',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: _buscarUsuariosBackend,
                  )
                ],
              ),
            ),
            if (suggestions.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Text("Sugerencias",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    ...suggestions.map((sug) => Card(
                      color: Colors.grey[850],
                      child: ListTile(
                        title: Text(sug['NombreUser'],
                            style: TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () => _sendFriendRequest(
                            sug['id'],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4),
                      child: Text("Amigos",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    ...friends.map((f) => Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(f['NombreUser'],
                            style: TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: Icon(Icons.sports_esports,
                              color: Colors.green),
                          onPressed: () => _showGameModes(f['id']),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
