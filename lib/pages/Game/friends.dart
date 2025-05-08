import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:frontend_android/services/socketService.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_android/utils/photoUtils.dart';
import '../../utils/guestUtils.dart';

class GameMode {
  final String name;
  final IconData icon;
  final String time;
  final String description;
  final Color color;
  final modoMapeado = {
    "Rápida": "Punt_10",
    "Clásica": "Punt_30",
    "Blitz": "Punt_5",
    "Bullet": "Punt_3",
    "Incremento": "Punt_5_10",
    "Incremento exprés": "Punt_3_2",
  };

  GameMode(this.name, this.icon, this.time, this.description, this.color);
}

class Friends_Page extends StatefulWidget {
  static void Function()? onFriendListShouldRefresh;
  static const String id = "friends_page";

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<Friends_Page> {
  late IO.Socket socket;
  String? idJugador;
  String? nombreJugador;
  String searchInput = "";
  String? selectedGameMode;
  late SharedPreferences prefs;

  String? _gameId;
  String? _gameColor;
  bool _yaEntramosAPartida = false;
  Map<String, String>? solicitudPendiente;
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> friends = [];

  final Map<String, String> modoMapeado = {
    "Rápida": "Punt_10",
    "Clásica": "Punt_30",
    "Blitz": "Punt_5",
    "Bullet": "Punt_3",
    "Incremento": "Punt_5_10",
    "Incremento exprés": "Punt_3_2"
  };

  final List<GameMode> gameModes = [
    GameMode("Rápida", Icons.extension, "10 min", "Modo tradicional", Colors.brown),
    GameMode("Clásica", Icons.verified, "30 min", "Ideal para nuevos", Colors.green),
    GameMode("Blitz", Icons.timer_off, "5 min", "Más desafiante", Colors.red),
    GameMode("Bullet", Icons.bolt, "3 min", "Rápido", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15+10s", "Incremental", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3+2s", "Incremento rápido", Colors.yellow),
  ];

  @override
  void initState() {
    super.initState();
    Friends_Page.onFriendListShouldRefresh = () async {
      await _cargarAmigos();
      if (!mounted) return;
      setState(() {});
    };
    verificarAccesoInvitado(context);
    _initializeSocketAndUser();
  }

  Future<void> _initializeSocketAndUser() async {
    socket = await SocketService().getSocket(context);
    prefs = await SharedPreferences.getInstance();  // <-- GUARDAMOS prefs una vez
    idJugador = prefs.getString('idJugador');
    nombreJugador = prefs.getString('usuario');

    if (idJugador == null || nombreJugador == null) {
      return;
    }

    await _cargarAmigos(); // 👈 Cargamos amigos confirmados

    _configureSocketListeners();
  }

  Future<void> _cargarAmigos() async {
    if (idJugador == null) return;

    final serverBackend = dotenv.env['SERVER_BACKEND'];
    if (serverBackend == null) {
      return;
    }

    final uri = Uri.parse('$serverBackend/buscarAmigos?id=$idJugador');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;

        if (decoded is List) {
          setState(() {
            friends = decoded.cast<Map<String, dynamic>>();
          });
        } else if (decoded is Map && decoded.containsKey('Message')) {
          setState(() {
            friends = []; // vacío si no hay amigos
          });
        } else {
        }

      } else {
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Excepción al cargar amigos: $e");
      }
    }
  }

  void _configureSocketListeners() {
    socket.off('friendRequestAccepted'); // importante para evitar duplicados
    socket.on('friendRequestAccepted', (data) async {
      await Future.delayed(Duration(milliseconds: 300));
      await _cargarAmigos(); // recarga lista desde el servidor

      if (!mounted) return;

      setState(() {}); // fuerza reconstrucción del widget

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 16),
              children: [
                TextSpan(text: 'Tu solicitud de amistad fue aceptada'),

              ],
            ),
          ),
        ),
      );
    });
  }

  void _sendFriendRequest(String idAmigo, String nombreAmigo) {
    final idClean = idAmigo.trim();

    if (idJugador != null && idClean != idJugador) {
      socket.emit('add-friend', {
        'idJugador': idJugador,
        'idAmigo': idClean,
        'nombre': nombreJugador,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 2),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 16),
              children: [
                TextSpan(text: 'Solicitud enviada a '),
                TextSpan(
                  text: nombreAmigo,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextSpan(text: ' de tus amigos.'),
              ],
            ),
          ),
        ),
      );
    }
  }

  String clean(String? id) => (id ?? "").trim();

  Future<void> setEloSafe(SharedPreferences prefs, String key, dynamic value) async {
    if (value == null) return;
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String && double.tryParse(value) != null) {
      await prefs.setDouble(key, double.parse(value));
    } else {
    }
  }

  Future<void> _buscarUsuariosBackend() async {
    if (searchInput.trim().isEmpty || idJugador == null) return;

    final serverBackend = dotenv.env['SERVER_BACKEND'];
    if (serverBackend == null) {
      return;
    }

    final uri = Uri.parse(
      '$serverBackend/buscarUsuarioPorUser?NombreUser=${Uri.encodeComponent(searchInput.trim())}',
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
      setState(() => suggestions = []);
    }
  }

  void _challengeFriend(String idRetado, String modoNombre) async {
    final modoBackend = modoMapeado[modoNombre] ?? "Punt_10";
    await prefs.setString('modoDeJuegoActivo', modoNombre); // ✅ Añadir esto

    socket.emit('challenge-friend', {
      'idRetador': idJugador,
      'idRetado': idRetado,
      'modo': modoBackend,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 2),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.white, fontSize: 16),
            children: [
              TextSpan(text: 'Reto enviado en modo '),
              TextSpan(
                text: modoNombre,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeFriend(String idAmigo, String nombreAmigo) {
    if (socket.connected && idJugador != null) {
      socket.emit("remove-friend", {
        "idJugador": idJugador,
        "idAmigo": idAmigo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.white, fontSize: 16),
              children: [
                TextSpan(text: 'Has eliminado a '),
                TextSpan(
                  text: nombreAmigo,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextSpan(text: ' de tus amigos.'),
              ],
            ),
          ),
        ),
      );

      setState(() {
        friends.removeWhere((f) => f['amigoId'].toString().trim() == idAmigo);
      });
    }
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
                setState(() {
                  selectedGameMode = mode.name; // ✅ Guardamos el modo seleccionado
                });
                _challengeFriend(idAmigo, mode.name); // enviamos reto
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
            const SizedBox(height: 16),
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SOCIAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.people, color: Colors.white, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),
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

            // ✅ Solicitud de amistad entrante (si hay)


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
                    ...suggestions.map((sug) {
                      final idSug = sug['id'].toString().trim();
                      final esAmigo = friends.any((f) => f['amigoId'].toString().trim() == idSug);

                      return Card(
                        color: Colors.grey[850],
                        child: ListTile(
                          title: Text(sug['NombreUser'], style: TextStyle(color: Colors.white)),
                          trailing: esAmigo
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.sports_esports, color: Colors.green),
                                onPressed: () => _showGameModes(idSug),
                              ),
                              IconButton(
                                icon: Icon(Icons.person_remove, color: Colors.red),
                                onPressed: () => _removeFriend(idSug, sug['NombreUser']),
                              ),
                            ],
                          )
                              : IconButton(
                            icon: Icon(Icons.person_add, color: Colors.blue),
                            onPressed: () => _sendFriendRequest(idSug, sug['NombreUser']),
                          ),
                        ),
                      );
                    }),


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
                    ...friends.map((f) {
                      final nombre = f['NombreUser'] ?? f['nombreAmigo'] ?? "Amigo";
                      final id = f['amigoId']?.toString().trim() ?? "";
                      final fotoPerfilCruda = f['fotoPerfil'] ?? f['fotoAmigo'] ?? 'none';

                      // 🔥 Aplicas bien la función que me pasaste:
                      final fotoSegura = getRutaSeguraFoto(fotoPerfilCruda);

                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: fotoSegura.startsWith('assets/')
                                ? AssetImage(fotoSegura) as ImageProvider
                                : NetworkImage("https://checkmatex-gkfda9h5bfb0gsed.spaincentral-01.azurewebsites.net/$fotoPerfilCruda"),
                            backgroundColor: Colors.white24,
                          ),
                          title: Text(nombre, style: TextStyle(color: Colors.white)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.sports_esports, color: Colors.green),
                                onPressed: () => _showGameModes(id),
                              ),
                              IconButton(
                                icon: Icon(Icons.person_remove, color: Colors.red),
                                onPressed: () => _removeFriend(id, nombre),
                              ),
                            ],
                          ),
                        ),
                      );

                    })
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