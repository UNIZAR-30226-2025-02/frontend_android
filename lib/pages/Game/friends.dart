import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

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
  String searchInput = "";
  String? foundUser;
  Set<String> localFriends = {};

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
    _initSocket();
  }

  Future<void> _initSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idJugador = prefs.getString('idJugador');
    if (idJugador == null) return;

    print("🔄 Intentando conectar al socket...");

    socket = IO.io('https://checkmatex-gkfda9h5bfb0gsed.spaincentral-01.azurewebsites.net/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ SOCKET CONECTADO");
    });

    socket.on('friendRequest', (data) async {
      final nombre = data['idJugador'];
      print("📩 Solicitud de amistad recibida de $nombre");

      final bool? aceptado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Solicitud de amistad"),
            content: Text("$nombre quiere ser tu amigo. ¿Aceptar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Rechazar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Aceptar"),
              ),
            ],
          );
        },
      );

      if (aceptado == true) {
        socket.emit('acceptFriendRequest', {
          'idJugador': idJugador,
          'idAmigo': nombre,
        });
        print("👍 Has aceptado la solicitud de $nombre");
        setState(() {
          localFriends.add(nombre);
        });
      } else {
        socket.emit('rejectFriendRequest', {
          'idJugador': idJugador,
          'idAmigo': nombre,
        });
        print("❌ Has rechazado la solicitud de $nombre");
      }
    });

    socket.on('friendRequestAccepted', (data) {
      final nuevoAmigo = data['idAmigo'];
      print("✅ Solicitud aceptada por $nuevoAmigo");
      setState(() {
        localFriends.add(nuevoAmigo);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$nuevoAmigo ha aceptado tu solicitud de amistad"),
        backgroundColor: Colors.green,
      ));
    });

    socket.onDisconnect((_) {
      print("🔌 Desconectado del socket (onDisconnect)");
    });
  }

  void _searchUser() {
    if (searchInput.trim().isEmpty) return;
    setState(() {
      foundUser = searchInput.trim();
    });
  }

  void _sendFriendRequest(String nombreBuscado) {
    if (idJugador == null || nombreBuscado == idJugador) return;

    socket.emit('addFriend', {
      'idJugador': idJugador,
      'idAmigo': nombreBuscado,
    });

    print("📤 Solicitud enviada a $nombreBuscado");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Solicitud enviada a $nombreBuscado"),
      backgroundColor: Colors.orange,
    ));
  }

  void _challengeFriend(String nombre, GameMode mode) {
    if (idJugador == null) return;

    socket.emit('challengeFriend', {
      'idRetador': idJugador,
      'idRetado': nombre,
      'modo': mode.name,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Reto enviado a $nombre en modo \${mode.name}"),
      backgroundColor: Colors.green,
    ));
  }

  void _showGameModes(String friendName) {
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
                _challengeFriend(friendName, mode);
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
      backgroundColor: Colors.black,
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
                      onChanged: (value) => searchInput = value,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Buscar usuario',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.white),
                    onPressed: _searchUser,
                  )
                ],
              ),
            ),
            if (foundUser != null)
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      color: Colors.grey[850],
                      child: ListTile(
                        title: Text(foundUser!, style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          localFriends.contains(foundUser!) ? "Es tu amigo" : "No es tu amigo",
                          style: TextStyle(color: Colors.white60),
                        ),
                        trailing: localFriends.contains(foundUser!)
                            ? IconButton(
                          icon: Icon(Icons.sports_esports, color: Colors.green),
                          onPressed: () => _showGameModes(foundUser!),
                        )
                            : IconButton(
                          icon: Icon(Icons.person_add, color: Colors.blue),
                          onPressed: () => _sendFriendRequest(foundUser!),
                        ),
                      ),
                    )
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
