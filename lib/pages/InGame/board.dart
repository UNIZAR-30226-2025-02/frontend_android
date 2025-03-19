import 'dart:async';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/socketService.dart';

class BoardScreen extends StatefulWidget {
  static const id = "board_page";
  final String gameMode;
  final String color;
  final String gameId;

  BoardScreen(this.gameMode, this.color, this.gameId);

  @override
  _BoardScreenState createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final ChessBoardController controller = ChessBoardController();
  late PlayerColor playerColor;
  late Timer _timerWhite;
  late Timer _timerBlack;
  late IO.Socket socket;
  int whiteTime = 600;
  int blackTime = 600;
  bool isWhiteTurn = true;
  List<Map<String, String>> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    socket = SocketService().getSocket();
    playerColor = widget.color == "white" ? PlayerColor.white : PlayerColor.black;
    print("✅ BoardScreen iniciado con gameId: ${widget.gameId}");

    _startTimer();
    _joinGame();  // ✅ Asegurarse de unirse a la partida
    _initializeSocketListeners();
    _listenToBoardChanges();
  }

  /// ✅ Unirse a la partida en caso de que se haya perdido la conexión
  void _joinGame() {
    socket.emit('join', {"idPartida": widget.gameId});
    print("📡 Enviando solicitud para unirse a la partida: ${widget.gameId}");
  }

  /// ✅ Maneja los eventos de socket
  void _initializeSocketListeners() {
    socket.on("new-move", (data) {
      print("📥 MOVIMIENTO RECIBIDO: $data");
      print("🔍 Tipo de 'data': ${data.runtimeType}");

      // ✅ Si es una lista, extraer su primer elemento
      if (data is List && data.isNotEmpty) {
        print("🔹 data[0]: ${data[0]}");  // 🔍 Ver qué contiene el primer elemento
        print("🔹 Tipo de data[0]: ${data[0].runtimeType}");
      }

      // Ahora verificamos si el primer elemento es un mapa
      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        var moveData = data[0];

        if (moveData.containsKey("movimiento") && moveData.containsKey("board")) {
          print("✅ Se encontraron las claves correctas en el JSON");
          String movimiento = moveData["movimiento"];  // Ejemplo: "e2e4"
          String from = movimiento.substring(0, 2);
          String to = movimiento.substring(2, 4);

          print("✅ Movimiento detectado: $from -> $to");

          setState(() {
            try {
              var move = controller.game.move({
                "from": from,
                "to": to,
                "promotion": "q"
              });

              if (move != null) {
                print("♟️ Movimiento aplicado en el tablero: $from -> $to");
                controller.notifyListeners();
                _switchTimer();
              } else {
                print("❌ Movimiento inválido recibido.");
              }
            } catch (e) {
              print("⚠️ Error al procesar el movimiento: $e");
            }
          });
        } else {
          print("❌ ERROR: 'moveData' no contiene 'movimiento' o 'board'.");
        }
      } else {
        print("❌ ERROR: 'data' no es un List con Map<String, dynamic> dentro.");
      }
    });

  }

  /// ✅ Envía movimientos al servidor
  Future<void> _sendMoveToServer(String from, String to) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    String movimiento = "$from$to";

    if (idJugador != null) {
      print("📡 ENVIANDO MOVIMIENTO: $from -> $to en partida ${widget.gameId}, jugador: $idJugador");
      socket.emit("make-move", {
        "movimiento": movimiento,
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
    } else {
      print("⚠️ ERROR: No se encontró el idJugador en SharedPreferences.");
    }
  }

  /// ✅ Escucha los cambios en el tablero y envía los movimientos
  void _listenToBoardChanges() {
    controller.addListener(() {
      final history = controller.game.getHistory({'verbose': true});

      if (history.isNotEmpty) {
        final lastMove = history.last;
        final from = lastMove['from'];
        final to = lastMove['to'];

        print("♟️ MOVIMIENTO DETECTADO: $from -> $to");

        if (lastMove.containsKey("from") && lastMove.containsKey("to")) {
          _sendMoveToServer(from, to);
          _switchTimer();
        }
      }
    });
  }

  /// ✅ Cambia el temporizador
  void _startTimer() {
    _timerWhite = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isWhiteTurn) {
        setState(() {
          if (whiteTime > 0) whiteTime--;
        });
      }
    });

    _timerBlack = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isWhiteTurn) {
        setState(() {
          if (blackTime > 0) blackTime--;
        });
      }
    });
  }

  void _switchTimer() {
    setState(() {
      isWhiteTurn = !isWhiteTurn;
    });
  }

  @override
  void dispose() {
    _timerWhite.cancel();
    _timerBlack.cancel();
    super.dispose();  // ❌ No desconectamos el socket aquí
  }

  ///------------------------------------------------------------------------------

  /// ✅ Volver a la pantalla anterior
  void _goBack() {
    Navigator.pop(context);
  }

  /// ✅ Enviar solicitud de tablas
  void _offerDraw() {
    socket.emit("offer-draw", {"game_id": widget.gameId});
    print("🤝 [GAME] Se ha ofrecido tablas en la partida ${widget.gameId}");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Has ofrecido tablas."),
      duration: Duration(seconds: 2),
    ));
  }

  /// ✅ Rendirse en la partida
  void _resignGame() {
    socket.emit("resign", {"game_id": widget.gameId});
    print("🏳️ [GAME] Has abandonado la partida ${widget.gameId}");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Te has rendido."),
      duration: Duration(seconds: 2),
    ));
    Navigator.pop(context); // Salir de la partida al rendirse
  }
  ///------------------------------------------------------------------------------


  /// ✅ Escucha mensajes en tiempo real y almacena el historial
  void _listenToChatMessages() {
    socket.on("chat-message", (data) { // 🔹 Aquí `data` se recibe correctamente del servidor
      print("📩 [CHAT] Evento recibido del servidor: $data");

      if (data is Map<String, dynamic> && data.containsKey("user_id") && data.containsKey("message")) {
        String sender = data["user_id"];
        String message = data["message"];

        // 🔍 Evitar mensajes duplicados
        String? lastMessage = messages.isNotEmpty ? messages.last["message"] : null;

        if (lastMessage == null || lastMessage != message) {
          setState(() {
            messages.add({"sender": sender, "message": message});
          });

          print("✅ [CHAT] Mensaje agregado: $sender -> $message");
        } else {
          print("⚠️ [CHAT] Mensaje duplicado detectado.");
        }
      } else {
        print("⚠️ [CHAT] Datos incorrectos: $data");
      }
    });
  }



  /// ✅ Enviar mensaje al servidor
void _sendChatMessage() {
  SharedPreferences.getInstance().then((prefs) {
    String? sender = prefs.getString('idJugador');
    String message = messageController.text.trim();

    print("📤 [CHAT] Intentando enviar mensaje: '$message' de usuario '$sender' en partida '${widget.gameId}'");

    if (message.isNotEmpty && sender != null) {
      socket.emit("send-message", {
        "game_id": widget.gameId,
        "user_id": sender,
        "message": message
      });

      print("✅ [CHAT] Mensaje enviado al servidor: $message en partida '${widget.gameId}'");

      setState(() {
        messages.add({"sender": sender, "message": message});
      });

      messageController.clear();
    } else {
      print("⚠️ [CHAT] Mensaje NO enviado: Campo vacío o usuario no encontrado.");
    }
  });
}
void _fetchChatMessages() {
  print("📡 [CHAT] Solicitando mensajes para la partida: '${widget.gameId}'");

  // ✅ Enviar la petición y esperar la respuesta
  socket.emitWithAck("fetch-messages", {"game_id": widget.gameId}, ack: (data) {
    print("📩 [CHAT] Mensajes recibidos del servidor para partida '${widget.gameId}': $data");

    if (data is List && data.isNotEmpty) {
      setState(() {
        messages.clear(); // 🔥 Limpiar mensajes antes de agregar nuevos
        messages.addAll(data.map((msg) => {
          "sender": msg["Id_usuario"],
          "message": msg["Mensaje"]
        }));
      });

      print("✅ [CHAT] Mensajes cargados en la UI para partida '${widget.gameId}'.");
    } else {
      print("⚠️ [CHAT] No hay mensajes en la base de datos o formato incorrecto.");
    }
  });
}



void _openChat() {
  // ✅ Cargar mensajes antes de abrir el chat
  _fetchChatMessages();
  _listenToChatMessages();

  SharedPreferences.getInstance().then((prefs) {
    String? idJugador = prefs.getString('idJugador');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: 300,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isMe = message["sender"] == idJugador; // ✅ Comparar con el ID del usuario autenticado

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message["message"]!),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _sendChatMessage,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });
}
///------------------------------------------------------------------------------
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      title: Text(widget.gameMode, style: TextStyle(color: Colors.white)),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _goBack, // Botón para volver atrás
      ),
    ),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPlayerInfo("Negras", blackTime),
        Expanded(
          child: Center(
            child: ChessBoard(
              controller: controller,
              boardOrientation: playerColor,
            ),
          ),
        ),
        _buildPlayerInfo("Blancas", whiteTime),
        SizedBox(height: 10),

        // 🔥 FILA CON BOTONES DE "TABLAS" Y "RENDIRSE"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _offerDraw,
                icon: Icon(Icons.handshake, color: Colors.white),
                label: Text("Tablas"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _resignGame,
                icon: Icon(Icons.flag, color: Colors.white),
                label: Text("Rendirse"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50), // 🔥 Ajusta la distancia desde abajo
        child: FloatingActionButton.extended(
          onPressed: _openChat,
          label: Text("Chat"),
          icon: Icon(Icons.chat),
          backgroundColor: Colors.blueAccent,)
    ),
  );
}

  Widget _buildPlayerInfo(String name, int time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center),
          Text(
            "${(time ~/ 60).toString().padLeft(2, '0')}:${(time % 60).toString().padLeft(2, '0')}",
            style: TextStyle(fontSize: 16, color: Colors.white),
          )
        ],
      ),
    );
  }
}
