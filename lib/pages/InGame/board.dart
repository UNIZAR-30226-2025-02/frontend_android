import 'dart:async';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/socketService.dart';
import 'package:frontend_android/pages/Game/init.dart';

class BoardScreen extends StatefulWidget {
  static const id = "board_page";
  final String gameMode;
  final String color;
  final String gameId;
  final String pgn;
  final int timeLeftW;
  final int timeLeftB;


  BoardScreen(this.gameMode, this.color, this.gameId, this.pgn, this.timeLeftW, this.timeLeftB);

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
  String? idJugador;
  //Piece? piezaPromocion;
  int whiteTime = 0;
  int blackTime = 0;
  bool _gameEnded = false;
  bool isWhiteTurn = true;
  bool _isChatVisible = false;
  bool _isMovesVisible = false;
  int incrementoPorJugada = 0;
  final TextEditingController _chatController = TextEditingController();
  List<String> _mensajesChat = [];
  List<String> _historialMovimientos = [];
  bool _esperandoPromocion = false;

  @override
  void initState() {
    super.initState();
    _initAsync();
    playerColor = widget.color == "white" ? PlayerColor.white : PlayerColor.black;
  }

  Future<void> _initAsync() async {
    await SocketService().connect(context);
    socket = await SocketService().getSocket(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idJugador = prefs.getString('idJugador');

    chessGame = chess.Chess();

    if(widget.pgn != "null"){
      chessGame.load_pgn(widget.pgn);
    }
    if(widget.timeLeftW != 0){
      whiteTime = widget.timeLeftW;
    }
    if(widget.timeLeftB != 0){
      blackTime = widget.timeLeftB;
    }
    playerColor = widget.color.trim().toLowerCase() == "white"
        ? PlayerColor.white
        : PlayerColor.black;

    _startTimer();
    _joinGame();
    _initializeSocketListeners();
    _configurarTiempoPorModo(widget.gameMode);
    _listenToBoardChanges();
  }


  Future<void> _initializeSocket() async {
    socket = await SocketService().getSocket(context);
  }

  void _joinGame() {
    socket.emit('join', {"idPartida": widget.gameId});
  }



  Future<void> _handleTimeout({required bool isWhite}) async {
    if (_gameEnded) return;
    _gameEnded = true;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');

    bool hasLost = (isWhite && playerColor == PlayerColor.white) ||
        (!isWhite && playerColor == PlayerColor.black);

    if (idJugador != null) {
      socket.emit('gameOver', [
        {
          "winner": hasLost ? "opponent" : idJugador,
          "idPartida": widget.gameId
        }
      ]);
    }
  }


  void _configurarTiempoPorModo(String modo) {
    switch (modo.toLowerCase()) {
      case "clásica":
        whiteTime = blackTime = 600; // 10 minutos
        break;
      case "principiante":
        whiteTime = blackTime = 1800; // 30 minutos
        break;
      case "avanzado":
        whiteTime = blackTime = 300; // 5 minutos
        break;
      case "relámpago":
        whiteTime = blackTime = 180; // 3 minutos
        break;
      case "incremento":
        whiteTime = blackTime = 900; // 15 minutos
        incrementoPorJugada = 10;
        break;
      case "incremento exprés":
        whiteTime = blackTime = 180; // 3 minutos
        incrementoPorJugada = 2;
        break;
      default:
        whiteTime = whiteTime;
        blackTime = blackTime;
    }
  }


  void _initializeSocketListeners() {
    socket.on('new-move', (data) {
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

                setState(() {
                  _historialMovimientos.add("${from.toUpperCase()}-${to.toUpperCase()}");
                });
              }

            } catch (_) {}
          });
        }
      }
    });

    socket.on('get-game-status', (_) {
      socket.emit('game-status', {
        "estadoPartida": "ingame",
        "timeLeftW": whiteTime,
          "timeLeftB": blackTime,

      });
    });

    socket.on('new-message', (data) {
      print("📩 Mensaje recibido: $data");

      final userIdRemitente = data[0]["user_id"];
      final mensajeRecibido = data[0]["message"];

      setState(() {
        if (userIdRemitente == idJugador) {
          _mensajesChat.add("Tú: $mensajeRecibido");
        } else {
          _mensajesChat.add("Rival: $mensajeRecibido");
        }
      }); // ✅ Ahora está correctamente cerrado
    });



    socket.on('requestTie', (data) async {
      bool? accepted = await _showDrawOfferDialog(context);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      if (accepted == true && idJugador != null) {
        socket.emit('draw-accept', {
          "idPartida": widget.gameId,
          "idJugador": idJugador,
        });

        // 👇 Mostrar popup también para quien acepta
        Future.delayed(Duration.zero, () {
          if (!context.mounted) return;
          /*_showSimpleThenExitDialog(
              "Has aceptado las tablas. La partida ha terminado en empate.");*/
        });
      } else if (idJugador != null) {
        socket.emit('draw-declined', {
          "idPartida": widget.gameId,
          "idJugador": idJugador,
        });
      }
    });

    socket.on('draw-declined', (data) {
      Future.delayed(Duration.zero, () {
        if (!context.mounted) return;
        _showSimpleDialog("El oponente ha rechazado las tablas.");
      });
    });

    socket.on('draw-accepted', (data) async {
      print("[SOCKET] draw-accepted recibido: $data");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      final esMio = data[0]['idJugador'] == idJugador;

      Future.microtask(() {
        if (!context.mounted) {

          return;}

        _showSimpleThenExitDialog("La partida ha terminado en empate.");
      });
    });


    socket.on('player-surrendered', (data) async {
      print("[SURREND] player-surrendered recibido: $data");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      if (data[0]['idJugador'] != idJugador) {
        print("[SOCKET] Tu rival se ha rendido");

      }
    });

    socket.on('gameOver', (data) {
      print("[SOCKET] gameOver recibido: $data");

      Future.microtask(() {
        if (!context.mounted) return;

        final winner = data[0]['winner'];
        print("[SOCKET] gameOver -> Ganador: $winner");
        print("[SOCKET] Mi color: ${widget.color}");

        if (winner == "draw") {
          _exitGame("La partida ha terminado en tablas.");
        } else if (winner == idJugador) {
          _exitGame("¡Has ganado!");
        } else {
          _exitGame("Has perdido. Tu rival ha ganado.");
        }
      });
    });
  }


  void _listenToBoardChanges() {
    controller.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final history = controller.game.getHistory({'verbose': true});
        if (history.isEmpty) return;

        final lastMove = history.last;
        final from = lastMove['from'];
        final to = lastMove['to'];
        final movedPiece = controller.game.get(to);
        if (movedPiece == null) return;

        final isPromotion = movedPiece.type == chess.PieceType.PAWN && (to.endsWith('4') || to.endsWith('1'));
        if (isPromotion) {
          // Deshacer movimiento automático
          controller.undoMove();

          if (!context.mounted) return;
          final selectedPiece = await _showPromotionDialog() ?? 'q';

          controller.game.move({
            "from": from,
            "to": to,
            "promotion": selectedPiece,
          });
          controller.notifyListeners();

          _sendMoveToServer(from, to, selectedPiece);
          _changeTurn();
        } else {
          _sendMoveToServer(from, to, "");
          _changeTurn();
        }

        if (incrementoPorJugada > 0) {
          setState(() {
            if (playerColor == PlayerColor.white && !isWhiteTurn) {
              whiteTime += incrementoPorJugada;
            } else if (playerColor == PlayerColor.black && isWhiteTurn) {
              blackTime += incrementoPorJugada;
            }
          });
        }

        setState(() {
          _historialMovimientos.add("${from.toUpperCase()}-${to.toUpperCase()}");
        });
      });
    });
  }


  Future<String?> _showPromotionDialog() async {
    print("Promotion: entro en el dialogo");
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Promociona tu peón"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['q', 'r', 'b', 'n'].map((e) {
              return IconButton(
                icon: Text(
                  _pieceUnicode(e, playerColor == PlayerColor.white ? chess.Color.WHITE : chess.Color.BLACK),
                  style: TextStyle(fontSize: 32),
                ), // O usa iconos según color
                onPressed: () => Navigator.pop(context, e),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _pieceUnicode(String piece, chess.Color color) {
    const whitePieces = {'q': '♕', 'r': '♖', 'b': '♗', 'n': '♘'};
    const blackPieces = {'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞'};
    return color == chess.Color.WHITE ? whitePieces[piece]! : blackPieces[piece]!;
  }

  chess.PieceType _promotionTypeFromChar(String char) {
    switch (char) {
      case 'q':
        return chess.PieceType.QUEEN;
      case 'r':
        return chess.PieceType.ROOK;
      case 'b':
        return chess.PieceType.BISHOP;
      case 'n':
        return chess.PieceType.KNIGHT;
      default:
        return chess.PieceType.QUEEN;
    }
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
              Navigator.pushReplacementNamed(context, Init_page.id);
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
      _timerWhite = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (isWhiteTurn && whiteTime > 0) {
          setState(() {
            whiteTime--;
          });
          if (whiteTime == 0) await _handleTimeout(isWhite: true);
        }
      });

      _timerBlack = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (!isWhiteTurn && blackTime > 0) {
          setState(() {
            blackTime--;
          });
          if (blackTime == 0) await _handleTimeout(isWhite: false);
        }
      });
    }


    Future<void> _sendMoveToServer(String from, String to, String promotion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    String movimiento = "$from$to";
    if (promotion.isNotEmpty) {
      movimiento = "$from$to$promotion";
    }


    if (idJugador != null) {
      socket.emit('make-move', {
        "movimiento": movimiento,
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });

    }
  }

  Future<void> _surrender() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    if (idJugador != null) {
      print("[SURREND] perder");
      socket.emit('resign', {
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
              print("CLOSE: Cerrando popups y saliendo de partida...");
              Navigator.of(context).pop();
              //Navigator.of(context).pop();
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
  void _enviarMensaje(String mensaje) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('idJugador');

    if (userId != null && mensaje.trim().isNotEmpty) {
      socket.emit('send-message', {
        "game_id": widget.gameId,
        "user_id": userId,
        "message": mensaje.trim(),
      });

      _chatController.clear(); // Limpia el input
    }
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
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(
                playerColor == PlayerColor.white ? "Negras" : "Blancas",
                playerColor == PlayerColor.white ? blackTime : whiteTime,
              ),
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
              _buildPlayerInfo(
                playerColor == PlayerColor.white ? "Blancas" : "Negras",
                playerColor == PlayerColor.white ? whiteTime : blackTime,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _offerDraw,
                    child: Text("Ofrecer tablas"),
                  ),
                  ElevatedButton(
                    onPressed: _surrender,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Rendirse"),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),

          // Botón de chat flotante
          Positioned(
            bottom: 80,
            right: 20,
            child: FloatingActionButton(
              heroTag: "chatFAB",
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.chat),
              onPressed: () {
                setState(() {
                  _isChatVisible = !_isChatVisible;
                });
              },
            ),
          ),

          // Botón historial de movimientos
          Positioned(
            bottom: 80,
            left: 20,
            child: FloatingActionButton(
              heroTag: "movesFAB",
              backgroundColor: Colors.orange,
              child: Icon(Icons.list_alt),
              onPressed: () {
                setState(() {
                  _isMovesVisible = !_isMovesVisible;
                });
              },
            ),
          ),

          if (_isChatVisible)
            Positioned(
              bottom: 150,
              right: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 200,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _mensajesChat.length,
                        itemBuilder: (context, index) => Text(_mensajesChat[index]),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: InputDecoration(hintText: 'Escribe un mensaje...'),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            if (_chatController.text.trim().isNotEmpty) {
                              setState(() {
                                _mensajesChat.add("Tú: ${_chatController.text.trim()}");
                                _enviarMensaje(_chatController.text);
                              });
                            }
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_isMovesVisible)
            Positioned(
              bottom: 370,
              right: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 200,
                child: Column(
                  children: [
                    Text("Movimientos", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _historialMovimientos.length,
                        itemBuilder: (context, index) => Text("${index + 1}. ${_historialMovimientos[index]}"),
                      ),
                    ),
                  ],
                ),
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
