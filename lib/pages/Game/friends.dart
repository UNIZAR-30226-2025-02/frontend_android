import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend_android/pages/inGame/board.dart';
import 'package:http/http.dart' as http;

import '../../utils/guestUtils.dart';

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
  String? _gameId;
  String? _gameColor;
  bool _yaEntramosAPartida = false;
  Map<String, String>? solicitudPendiente;
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
    verificarAccesoInvitado(context);
    _initializeSocketAndUser();
  }

  Future<void> _initializeSocketAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    idJugador = prefs.getString('idJugador');
    nombreJugador = prefs.getString('usuario');

    if (idJugador == null || nombreJugador == null) {
      print("⚠️ No se encontró idJugador o nombre en SharedPreferences.");
      return;
    }

    await _cargarAmigos(); // 👈 Cargamos amigos confirmados

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

  Future<void> _cargarAmigos() async {
    if (idJugador == null) return;

    final uri = Uri.parse(
      'https://checkmatex-gkfda9h5bfb0gsed.spaincentral-01.azurewebsites.net/buscarAmigos?id=$idJugador',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          friends = data.cast<Map<String, dynamic>>();
        });
      } else {
        print("❌ Error cargando amigos: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Excepción al cargar amigos: $e");
    }
  }

  void _configureSocketListeners() {
    print("🛠️ Configurando listeners...");

    socket.on("challengeSent", (data) {
      print("🎯 Evento challengeSent recibido: $data (${data.runtimeType})");


        final challengeData = (data as List)[0] as Map<String, dynamic>;

        final String idRetador = challengeData["idRetador"].toString();
        final String idRetado = challengeData["idRetado"].toString();
        final String modo = challengeData["modo"].toString();

        print("✅ Reto recibido de $idRetador a $idRetado en modo $modo");

        _mostrarPopupReto(idRetador, idRetado, modo);

    });
    socket.on('game-ready', (data) {
      print("🎯 game-ready recibido: $data");
      final idPartida = data[0]['idPartida'];
      _gameId = idPartida;
    });

    socket.on('color', (data) async {
      print("🎨 color recibido: $data");
      if (idJugador == null) return;
      final jugadores = List<Map<String, dynamic>>.from(data[0]['jugadores']);
      final yo = jugadores.firstWhere((jugador) => jugador['id'] == idJugador, orElse: () => {});
      final rival = jugadores.firstWhere((jugador) => jugador['id'] != idJugador, orElse: () => {});

      if (yo.isNotEmpty && yo.containsKey('color')) {
        final String color = yo['color'];
        final prefs = await SharedPreferences.getInstance();

        if (color == 'white') {
          await prefs.setString('nombreBlancas', yo['nombreW']);
          await prefs.setInt('eloBlancas', yo['eloW']);
          await prefs.setString('nombreNegras', rival['nombreB']);
          await prefs.setInt('eloNegras', rival['eloB']);
        } else {
          await prefs.setString('nombreNegras', yo['nombreB']);
          await prefs.setInt('eloNegras', yo['eloB']);
          await prefs.setString('nombreBlancas', rival['nombreW']);
          await prefs.setInt('eloBlancas', rival['eloW']);
        }

        final miElo = color == 'white' ? prefs.getInt('eloBlancas') ?? 0 : prefs.getInt('eloNegras') ?? 0;
        final rivalElo = color == 'white' ? prefs.getInt('eloNegras') ?? 0 : prefs.getInt('eloBlancas') ?? 0;
        final rivalName = color == 'white' ? prefs.getString('nombreNegras') ?? "Rival" : prefs.getString('nombreBlancas') ?? "Rival";

        if (_gameId != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BoardScreen(
                "Modo personalizado", // puedes pasar el modo si lo guardas
                color,
                _gameId!,
                "null",
                0,
                0,
                miElo,
                rivalElo,
                rivalName,
              ),
            ),
          );
        }
      }
    });

    socket.on("friendRequest", (dataRaw) {
      print("📩 Evento recibido: friendRequest");

      final data = dataRaw is String ? jsonDecode(dataRaw) : dataRaw;

      print("📨 Data recibida: $data (${data.runtimeType})");

      try {
        final Map<String, dynamic> userData = data[0]; // <-- idJugador, idAmigo
        final String nombre = data[1];                 // <-- nombre del remitente
        final String idRemitente = userData["idJugador"].toString().trim();

        if (idJugador != null && idRemitente != idJugador) {
          setState(() {
            solicitudPendiente = {
              "idRemitente": idRemitente,
              "nombre": nombre,
            };
          });
        }
      } catch (e) {
        print("❌ Error procesando friendRequest: $e");
      }
    });


    socket.on("game-ready", (data) {
      print("🎯 Partida lista → $data");

      try {
        final partidaId = data['id'];
        final color = data['color'];

        if (!mounted) return;

        Navigator.pushNamed(
          context,
          '/board',
          arguments: {
            'partidaId': partidaId,
            'color': color,
            'modo': data['modo'] ?? '', // opcional
          },
        );
      } catch (e) {
        print("❌ Error al procesar game-ready: $e");
      }
    });


    socket.on("request-accepted", (data) {
      final String nombre = data["nombre"];
      print("✅ $nombre aceptó tu solicitud");
      _showInfoDialog("✅ $nombre ha aceptado tu solicitud de amistad.");
    });

    socket.on("request-rejected", (data) {
      final String nombre = data["nombre"];
      print("❌ $nombre rechazó tu solicitud");
      _showInfoDialog("❌ $nombre ha rechazado tu solicitud de amistad.");
    });

    socket.on("friend-removed", (data) {
      final nombre = data["nombre"];
      print("🗑️ $nombre ya no es tu amigo.");
      _showInfoDialog("🗑️ $nombre ya no es tu amigo.");
    });

    print("✅ Listeners configurados");
  }

  void _sendFriendRequest(String idAmigo, String nombreAmigo) {
    final idClean = idAmigo.trim();
    print("📤 Enviando solicitud a $idClean ($nombreAmigo)");

    if (idJugador != null && idClean != idJugador) {
      socket.emit('add-friend', {
        'idJugador': idJugador,
        'idAmigo': idClean,
        'nombre': nombreJugador,
      });

      print("📬 Evento emitido: add-friend {idJugador: $idJugador, idAmigo: $idClean}");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Solicitud enviada a $nombreAmigo"),
        backgroundColor: Colors.orange,
      ));
    }
  }

  void _showFriendRequestDialog(String idRemitente, String nombre) {
    print("🪧 Mostrando popup de solicitud de $nombre ($idRemitente)");

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Solicitud de amistad"),
        content: Text("$nombre quiere ser tu amigo."),
        actions: [
          TextButton(
            onPressed: () {
              print("❌ Rechazada");
              socket.emit('reject-request', {
                "idJugador": idRemitente,
                "idAmigo": idJugador,
                "nombre": nombreJugador,
              });
              Navigator.of(context).pop();
            },
            child: Text("Rechazar"),
          ),
          TextButton(
            onPressed: () {
              print("✅ Aceptada");
              socket.emit('accept-request', {
                "idJugador": idRemitente,
                "idAmigo": idJugador,
                "nombre": nombreJugador,
              });
              Navigator.of(context).pop();
            },
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  String clean(String? id) => (id ?? "").trim();

  void _mostrarPopupReto(String idRetador, String idRetado, String modo) {
    if (!mounted) {
      print("⚠️ Widget desmontado. No se puede mostrar popup.");
      return;
    }

    print("📥 Popup de reto recibido → idRetador: $idRetador | idRetado: $idRetado | modo: $modo");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("¡Has recibido un reto!"),
        content: Text("Te han retado a una partida en modo $modo."),
        actions: [
          TextButton(
            onPressed: () {
              print("✅ Aceptando reto...");
              print("✅ Enviando accept-challenge → { idRetador: $idRetador, idRetado: $idRetado, modo: $modo }");
              socket.emit('accept-challenge', {
                "idRetado": idRetado,
                "idRetador": idRetador,
                "modo": modo,
              });
              Navigator.of(context).pop();
            },
            child: Text("Aceptar"),
          ),
          TextButton(
            onPressed: () {
              print("❌ Reto rechazado.");
              Navigator.of(context).pop();
            },
            child: Text("Rechazar"),
          ),
        ],
      ),
    );
  }



  void _showInfoDialog(String message) {
    if (!mounted) return;

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

    print("📡 Enviando reto → idRetador: $idJugador | idRetado: $idRetado | modo: $modoBackend");

    socket.emit('challenge-friend', {
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

            // ✅ Solicitud de amistad entrante (si hay)
            if (solicitudPendiente != null)
              Card(
                color: Colors.blueGrey,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  title: Text(
                    "${solicitudPendiente!["nombre"]} quiere ser tu amigo.",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          socket.emit('accept-request', {
                            "idJugador": solicitudPendiente!["idRemitente"],
                            "idAmigo": idJugador,
                            "nombre": nombreJugador,
                          });
                          setState(() => solicitudPendiente = null);
                        },
                        child: Text("Aceptar", style: TextStyle(color: Colors.green)),
                      ),
                      TextButton(
                        onPressed: () {
                          socket.emit('reject-request', {
                            "idJugador": solicitudPendiente!["idRemitente"],
                            "idAmigo": idJugador,
                            "nombre": nombreJugador,
                          });
                          setState(() => solicitudPendiente = null);
                        },
                        child: Text("Rechazar", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
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
                              sug['id'].toString(), sug['NombreUser']),
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
                    ...friends.map((f) {
                      final nombre = f['NombreUser'] ?? f['nombreAmigo'] ?? "Amigo";
                      final id = f['amigoId']?.toString().trim() ?? "";

                      print("👤 Amigo: $nombre | ID extraído: $id");

                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          title: Text(nombre, style: TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: Icon(Icons.sports_esports, color: Colors.green),
                            onPressed: () => _showGameModes(id),
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