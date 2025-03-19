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
    // ✅ Asegurar que playerColor se asigne correctamente
    playerColor = widget.color.trim().toLowerCase() == "white" ? PlayerColor.white : PlayerColor.black;
    print("✅ BoardScreen iniciado con playerColor: $playerColor");

    _startTimer();
    _joinGame();  // ✅ Unirse a la partida
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

      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        var moveData = data[0];

        if (moveData.containsKey("movimiento") && moveData.containsKey("board")) {
          print("✅ Movimiento recibido correctamente");
          String movimiento = moveData["movimiento"];  // Ejemplo: "e2e4"
          String from = movimiento.substring(0, 2);
          String to = movimiento.substring(2, 4);
          String promotion = movimiento.length > 4 ? movimiento[4] : "";

          print("✅ Movimiento detectado: $from -> $to");

          if (mounted) {
            setState(() {
              try {
                var move = controller.game.move({
                  "from": from,
                  "to": to,
                  "promotion": promotion.isNotEmpty ? promotion : null, // ✅ Aplica promoción si existe
                });

                if (move != null) {
                  print("♟️ Movimiento reflejado en el tablero: $from -> $to");
                  controller.notifyListeners();
                  _changeTurn(); // 🔄 Cambiar turno después del movimiento del oponente
                } else {
                  print("❌ Movimiento inválido recibido.");
                }
              } catch (e) {
                print("⚠️ Error al procesar el movimiento: $e");
              }
            });
          }
        } else {
          print("❌ ERROR: 'moveData' no contiene 'movimiento' o 'board'.");
        }
      } else {
        print("❌ ERROR: 'data' no es un List con Map<String, dynamic> dentro.");
      }
    });
  }

  /// ✅ Envía movimientos al servidor
  Future<void> _sendMoveToServer(String from, String to, String? promotion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    String movimiento = "$from$to";

    if (promotion != null && promotion.isNotEmpty) {
      movimiento = "$from$to$promotion"; // 🔥 Agrega la pieza elegida
    }

    if (idJugador != null) {
      print("📡 ENVIANDO MOVIMIENTO: $from -> $to en partida ${widget.gameId}, jugador: $idJugador");
      socket.emit("make-move", {
        "movimiento": movimiento,
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
      //setState(() {
      //controller.notifyListeners();
      //});
    } else {
      print("⚠️ ERROR: No se encontró el idJugador en SharedPreferences.");
    }
  }

  void _listenToBoardChanges() {
    controller.addListener(() {
      final history = controller.game.getHistory({'verbose': true});

      if (history.isNotEmpty) {
        final lastMove = history.last;
        final from = lastMove['from']; // Ejemplo: "e2"
        final to = lastMove['to']; // Ejemplo: "e4"
        String? promotion = lastMove.containsKey("promotion") ? lastMove["promotion"] : null;

        print("♟️ MOVIMIENTO DETECTADO: $from -> $to");

        // ✅ Obtener la pieza en la casilla de origen directamente desde la librería
        Piece? piece = controller.game.get(to);

        if (piece == null) {
          print("❌ No hay pieza en la casilla de origen.");
          return;
        }

        print("📌 Pieza encontrada en $to: $piece");

        print("📌 Pieza encontrada en $to: $piece");
        print("📌 Tipo de piece.color: ${piece.color} (tipo: ${piece.color.runtimeType})");
        print("📌 Tipo de playerColor: $playerColor (tipo: ${playerColor.runtimeType})");

        // 🔥 Convertir piece.color de Color.BLACK a PlayerColor.black
        PlayerColor piecePlayerColor = (piece.color == Color.WHITE) ? PlayerColor.white : PlayerColor.black;

        // ✅ Verificar que la pieza pertenece al jugador actual
        bool isMovingOwnPiece = (playerColor == piecePlayerColor);
        if (!isMovingOwnPiece) {
          print("❌ No puedes mover piezas del rival.");
          return;
        }

        bool isPromotionMove =
            (from[1] == "7" && to[1] == "8" && playerColor == PlayerColor.white) ||
                (from[1] == "2" && to[1] == "1" && playerColor == PlayerColor.black);

        if (isPromotionMove) {
          print("👑 Promoción detectada: Pieza elegida -> ${promotion ?? "No detectada"}");

          if (promotion == null || promotion.isEmpty) {
            print("⚠️ ERROR: No se detectó la promoción correctamente.");
            return;
          }
        }

        // ✅ Si es su turno y mueve su propia pieza, enviar movimiento al servidor y reflejar en el otro jugador
        if ((isWhiteTurn && playerColor == PlayerColor.white) ||
            (!isWhiteTurn && playerColor == PlayerColor.black)) {
          print("✅ Movimiento válido, enviando al servidor...");
          _sendMoveToServer(from, to, promotion);
          _changeTurn();
        } else {
          print("❌ Movimiento bloqueado: No es tu turno.");
        }
      }
    });
  }

  /// ✅ Cambia el turno sin afectar el temporizador
  void _changeTurn() {
    setState(() {
      isWhiteTurn = !isWhiteTurn;
      print("🔄 Turno cambiado: Ahora juegan las ${isWhiteTurn ? "blancas" : "negras"}");
    });
  }

  void _revertLastMove() {
    setState(() {
      controller.game.undo(); // 🔄 Revierte el último movimiento
      controller.notifyListeners();
      print("🔄 Movimiento revertido porque no era tu turno.");
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

  @override
  void dispose() {
    _timerWhite.cancel();
    _timerBlack.cancel();
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
                    (!isWhiteTurn && playerColor == PlayerColor.black), // 🔥 Solo permite mover en el turno correcto
              ),
            ),
          ),
          _buildPlayerInfo("Blancas", whiteTime),
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