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
