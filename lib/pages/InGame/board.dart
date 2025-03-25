import 'dart:async';
import 'package:chess/chess.dart' as chess;
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
  late chess.Chess chessGame;
  Piece? piezaPromocion;
  int whiteTime = 600;
  int blackTime = 600;
  bool isWhiteTurn = true;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await SocketService().connect(context);  // 👈 FORZAR CONEXIÓN COMPLETA
    socket = await SocketService().getSocket();  // 👈 Asignar socket antes de listeners

    chessGame = chess.Chess();
    playerColor = widget.color.trim().toLowerCase() == "white"
        ? PlayerColor.white
        : PlayerColor.black;

    _startTimer();
    _joinGame();


    _initializeSocketListeners();  // 👈 IMPORTANTE: después de tener socket
    _listenToBoardChanges();
  }


  Future<void> _initializeSocket() async {
    socket = await SocketService().getSocket();
  }

  void _joinGame() {
    socket.emit('join', {"idPartida": widget.gameId});
  }

  void _initializeSocketListeners() {
    socket.on("new-move", (data) {
      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        var moveData = data[0];
        if (moveData.containsKey("movimiento")) {
          String movimiento = moveData["movimiento"];
          String from = movimiento.substring(0, 2);
          String to = movimiento.substring(2, 4);
          String promotion = movimiento.length > 4 ? movimiento[4] : "";

          setState(() {
            try {
              var move = controller.game.move({
                "from": from,
                "to": to,
                "promotion": promotion.isNotEmpty ? promotion : null,
              });
              if (move != null) {
                controller.notifyListeners();
                _changeTurn();
              }
            } catch (_) {}
          });
        }
      }
    });

    socket.on("requestTie", (data) async {
      bool? accepted = await _showDrawOfferDialog(context);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      if (accepted == true && idJugador != null) {
        socket.emit('draw-accepted', {
          "idPartida": widget.gameId,
          "idJugador": idJugador,
        });

        // 👇 Mostrar popup también para quien acepta
        Future.delayed(Duration.zero, () {
          if (!context.mounted) return;
          _showSimpleThenExitDialog(
              "Has aceptado las tablas. La partida ha terminado en empate.");
        });
      } else if (idJugador != null) {
        socket.emit('draw-declined', {
          "idPartida": widget.gameId,
          "idJugador": idJugador,
        });
      }
    });

    socket.on("draw-declined", (data) {
      Future.delayed(Duration.zero, () {
        if (!context.mounted) return;
        _showSimpleDialog("El oponente ha rechazado las tablas.");
      });
    });

    socket.on("draw-accepted", (data) async {
      print("[SOCKET] draw-accepted recibido: $data");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      final esMio = data["idJugador"] == idJugador;

      Future.microtask(() {
        if (!context.mounted) return;

        if (esMio) {
          _showSimpleThenExitDialog("Has aceptado las tablas. La partida ha terminado en empate.");
        } else {
          _showSimpleThenExitDialog("El oponente ha aceptado tu oferta de tablas.");
        }
      });
    });


    socket.on("player-surrendered", (data) async {
      print("[SOCKET] player-surrendered recibido: $data");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      if (data["idJugador"] != idJugador) {
        print("[SOCKET] Tu rival se ha rendido");
        _showSimpleThenExitDialog("Tu rival se ha rendido. ¡Has ganado!");
      }
    });

    socket.on("gameOver", (data) {
      print("[SOCKET] gameOver recibido: $data");

      Future.microtask(() {
        if (!context.mounted) return;

        final winner = data["winner"];
        print("[SOCKET] gameOver -> Ganador: $winner");
        print("[SOCKET] Mi color: ${widget.color}");

        if (winner == "draw") {
          _exitGame("La partida ha terminado en tablas.");
        } else if (winner == widget.color) {
          _exitGame("¡Has ganado!");
        } else {
          _exitGame("Has perdido. Tu rival ha ganado.");
        }
      });
    });
  }
    void _listenToBoardChanges() {
    controller.addListener(() async {
      final history = controller.game.getHistory({'verbose': true});
      if (history.isNotEmpty) {
        final lastMove = history.last;
        final from = lastMove['from'];
        final to = lastMove['to'];
        Piece? movedPiece = controller.game.get(to);
        if (movedPiece == null) return;

        PlayerColor piecePlayerColor =
        (movedPiece.color == chess.Color.WHITE) ? PlayerColor.white : PlayerColor.black;
        if (playerColor != piecePlayerColor) return;

        _sendMoveToServer(from, to, "");
        _changeTurn();
      }
    });
  }
  // ✅ Popup para cualquier final de partida
  void _exitGame(String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Fin de la partida"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  void _changeTurn() {
    setState(() {
      isWhiteTurn = !isWhiteTurn;
    });
  }

  void _startTimer() {
    _timerWhite = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isWhiteTurn && whiteTime > 0) {
        setState(() {
          whiteTime--;
        });
      }
    });

    _timerBlack = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isWhiteTurn && blackTime > 0) {
        setState(() {
          blackTime--;
        });
      }
    });
  }

  Future<void> _sendMoveToServer(String from, String to, String promotion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    String movimiento = "$from$to";
    if (piezaPromocion != null) {
      movimiento = "$from$to${piezaPromocion!.type}";
    }

    if (idJugador != null) {
      socket.emit("make-move", {
        "movimiento": movimiento,
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
      piezaPromocion = null;
    }
  }

  Future<void> _surrender() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    if (idJugador != null) {
      print("[DEBUG] perder");
      socket.emit('surrender', {
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
    }
  }

  Future<void> _offerDraw() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    if (idJugador != null) {
      socket.emit('draw-offer', {
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
    }
  }

  void _showConfirmThenExitDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Información"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el popup
              Navigator.of(context).pop(); // Sale del BoardScreen
            },
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDrawOfferDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Oferta de tablas"),
          content: Text("Tu oponente ha ofrecido tablas. ¿Aceptas?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Rechazar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }



  void _showSimpleThenExitDialog(String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Información"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (!context.mounted) return;
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }


  // ✅ Popup informativo que no cierra la partida
  void _showSimpleDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Información"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerWhite.cancel();
    _timerBlack.cancel();

    socket.off("new-move");
    socket.off("player-surrendered");
    socket.off("draw-accepted");
    socket.off("draw-declined");
    socket.off("requestTie");
    socket.off("gameOver");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.gameMode, style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
                enableUserMoves: (isWhiteTurn && playerColor == PlayerColor.white) ||
                    (!isWhiteTurn && playerColor == PlayerColor.black),
              ),
            ),
          ),
          _buildPlayerInfo("Blancas", whiteTime),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _offerDraw, // correcto
                child: Text("Ofrecer tablas"),
              ),
              ElevatedButton(
                onPressed: _surrender, // correcto
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Rendirse"),
              ),

            ],
          ),
          SizedBox(height: 10),
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
