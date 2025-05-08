import 'dart:async';
import 'package:chess/chess.dart' as chess;
import 'package:frontend_android/pages/Game/game_review_page.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/socketService.dart';
import 'package:frontend_android/pages/Game/init.dart';

import '../../utils/photoUtils.dart';

class BoardScreen extends StatefulWidget {
  static const id = "board_page";
  final String gameMode;
  final String color;
  final String gameId;
  final String pgn;
  final int timeLeftW;
  final int timeLeftB;
  final int myElo;
  final int rivalElo;
  final String rivalName;
  final String rivalFoto;

  BoardScreen(this.gameMode, this.color, this.gameId, this.pgn,
      this.timeLeftW, this.timeLeftB, this.myElo, this.rivalElo, this.rivalName, this.rivalFoto);

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
  late String gameMode;
  String? idJugador;
  Piece? piezaPromocion;
  int whiteTime = 0;
  int blackTime = 0;
  bool _gameEnded = false;
  bool isWhiteTurn = true;
  bool _isChatVisible = false;
  bool _isMovesVisible = false;
  bool _isLoaded = false;
  String? miNombre;
  int incrementoPorJugada = 0;
  final TextEditingController _chatController = TextEditingController();
  List<String> _mensajesChat = [];
  List<String> _historialMovimientos = [];
  String nombreBlancas = "Blancas";
  String nombreNegras = "Negras";
  int eloBlancas = 0;
  int eloNegras = 0;
  String fotoBlancas = "none";
  String fotoNegras = "none";

  final Map<String, String> modoVisibleMap = {
    "Punt_10": "Rápida",
    "Punt_30": "Clásica",
    "Punt_5": "Blitz",
    "Punt_3": "Bullet",
    "Punt_5_10": "Incremento",
    "Punt_3_2": "Incremento exprés",
  };

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
    final name = prefs.getString('usuario') ?? "Tú";
    setState(() {
      miNombre = name;
    });
    final miFoto = prefs.getString('fotoPerfil') ?? "none";
    chessGame = chess.Chess();

    if(widget.pgn != "null"){
      chessGame.load_pgn(widget.pgn);
      controller.loadPGN(widget.pgn);
    }
    if (widget.timeLeftW != 0){
      whiteTime = widget.timeLeftW;
    }
    if (widget.timeLeftB != 0){
      blackTime = widget.timeLeftB;
    }

    gameMode = modoVisibleMap[widget.gameMode] ?? widget.gameMode;

    playerColor = widget.color.trim().toLowerCase() == "white"
        ? PlayerColor.white
        : PlayerColor.black;

    if (playerColor == PlayerColor.white) {
      nombreBlancas = name;
      fotoBlancas = miFoto;
      eloBlancas = widget.myElo;
      nombreNegras = widget.rivalName;
      eloNegras = widget.rivalElo;
      fotoNegras = widget.rivalFoto;
    } else {
      nombreNegras = name;
      fotoNegras = miFoto;
      eloNegras = widget.myElo;
      nombreBlancas = widget.rivalName;
      eloBlancas = widget.rivalElo;
      fotoBlancas = widget.rivalFoto;
    }

    _startTimer();
    _joinGame();
    _initializeSocketListeners();
    _configurarTiempoPorModo(widget.gameMode);
    _listenToBoardChanges();
    setState(() {
      _isLoaded = true;
    });
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
      socket.emit('game-timeout', [
        {
          "idJugador": idJugador,
          "idPartida": widget.gameId
        }
      ]);
    }
  }

  void _configurarTiempoPorModo(String modo) {
    if (whiteTime != 0 || blackTime != 0) {
      return;
    }

    switch (modo.toLowerCase()) {
      case "rápida":
        whiteTime = blackTime = 600; // 10 minutos
        break;
      case "clásica":
        whiteTime = blackTime = 1800; // 30 minutos
        break;
      case "blitz":
        whiteTime = blackTime = 300; // 5 minutos
        break;
      case "bullet":
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
          String? promotion;
          String movimiento = moveData["movimiento"];
          String from = movimiento.substring(0, 2);
          String to = movimiento.substring(2, 4);

          if (movimiento.length == 5) {
            promotion = movimiento[4];
          } else {
            promotion = "";
          }

          try {
            bool wasWhiteTurn = isWhiteTurn;
            if (promotion.isNotEmpty) {
              controller.makeMoveWithPromotion(
                from: from,
                to: to,
                pieceToPromoteTo: promotion,
              );
            } else {
              controller.makeMove(
                from: from,
                to: to,
              );
            }

            // Aplica incremento antes de cambiar turno
            if (incrementoPorJugada > 0) {
              setState(() {
                if (wasWhiteTurn) {
                  whiteTime += incrementoPorJugada;
                } else {
                  blackTime += incrementoPorJugada;
                }
              });
            }

            _changeTurn();

            setState(() {
              final move = "$from$to${promotion ?? ""}".toLowerCase();
              _historialMovimientos.add(move);
            });

          } catch (e) {
            print("❌ Error al aplicar el movimiento recibido: $e");
          }
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
      final userIdRemitente = data[0]["user_id"];
      final mensajeRecibido = data[0]["message"];

      setState(() {
        if (userIdRemitente == idJugador) {
          _mensajesChat.add("Tú: $mensajeRecibido");
        } else {
          _mensajesChat.add("Rival: $mensajeRecibido");
        }
      });
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
      Future.microtask(() {
        if (!context.mounted) {
          return;
        }
        _exitGame("La partida ha terminado en tablas.");
      });
    });

    socket.on('player-surrendered', (data) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idJugador = prefs.getString('idJugador');

      if (data[0]['idJugador'] != idJugador) {
        print("[SOCKET] Tu rival se ha rendido");
      }
    });

    socket.on('gameOver', (data) {
      Future.microtask(() {
        if (!context.mounted) return;

        final info = (data is List && data.isNotEmpty) ? data[0] : data;
        final winner = info['winner'];
        final timeout = info['timeout'] == 'true';

        if (winner == "draw") {
          _exitGame("La partida ha terminado en tablas.");
        } else if (winner == idJugador) {
          _exitGame(timeout ? "¡Has ganado por tiempo!" : "¡Has ganado!");
        } else {
          _exitGame(timeout ? "Has perdido por tiempo." : "Has perdido. Tu rival ha ganado.");
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
        final String flags = lastMove['flags'];
        String? promotion;
        Piece? movedPiece = controller.game.get(to);

        if (movedPiece == null) return;

        PlayerColor piecePlayerColor =
        (movedPiece.color == chess.Color.WHITE) ? PlayerColor.white : PlayerColor.black;

        if (playerColor != piecePlayerColor) return;

        final isPromotion = isRealPromotion(flags, to);

        if (isPromotion){
          if (movedPiece.type == PieceType.ROOK){
            promotion = "r";
          }
          if (movedPiece.type == PieceType.BISHOP){
            promotion = "b";
          }
          if (movedPiece.type == PieceType.QUEEN){
            promotion = "q";
          }
          if (movedPiece.type == PieceType.KNIGHT){
            promotion = "n";
          }

          _sendMoveToServer(from, to, promotion);
        }
        else{
          promotion = "";
          _sendMoveToServer(from, to, promotion);
        }

        _changeTurn();

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
          final move = "$from$to${promotion ?? ""}".toLowerCase();
          _historialMovimientos.add(move);
        });
      }
    });
  }

  bool isRealPromotion(String piece, String to) {
    final rank = to[1];

    if (rank == null) return false;

    final isPawn = piece.contains('p');
    final isWhitePromotion = rank == "8";
    final isBlackPromotion = rank == "1";

    return isPawn && (isWhitePromotion || isBlackPromotion);
  }

  String generarPGNConTags({
    required String pgnBody,
    required String myId,
    required String rivalId,
    required String myAlias,
    required String rivalAlias,
    required int myElo,
    required int rivalElo,
    required bool soyBlancas,
  }) {
    final whiteId = soyBlancas ? myId : rivalId;
    final blackId = soyBlancas ? rivalId : myId;
    final whiteAlias = soyBlancas ? myAlias : rivalAlias;
    final blackAlias = soyBlancas ? rivalAlias : myAlias;
    final whiteElo = soyBlancas ? myElo : rivalElo;
    final blackElo = soyBlancas ? rivalElo : myElo;

    final tags = [
      '[White "$whiteId"]',
      '[Black "$blackId"]',
      '[White Alias "$whiteAlias"]',
      '[Black Alias "$blackAlias"]',
      '[White Elo "$whiteElo"]',
      '[Black Elo "$blackElo"]',
      '',
    ];

    return '${tags.join('\n')}\n${pgnBody.trim()}';
  }

  List<String> convertirPGNaMovimientosUCI(String pgn) {
    final game = chess.Chess();

    try {
      game.load_pgn(pgn);
    } catch (e) {
      print("❌ Error al cargar PGN: $e");
      return [];
    }

    final moves = game.getHistory({'verbose': true});
    return moves.map((m) => "${m['from']}${m['to']}${m['promotion'] ?? ''}").toList();
  }

  List<String> transformarMovimientosConPromocion(List<String> movimientosRaw) {
    final List<String> movimientosLimpios = [];

    for (final mov in movimientosRaw) {
      final uci = mov.replaceAll(RegExp(r'[^a-h1-8qrbn]'), '').toLowerCase();

      // Solo acepta strings de longitud 4 o 5 (con promoción válida)
      if (uci.length == 4 || (uci.length == 5 && RegExp(r'[qrbn]$').hasMatch(uci))) {
        movimientosLimpios.add(uci);
      } else {
        print("⚠️ Movimiento descartado por formato inválido: $uci");
      }
    }

    return movimientosLimpios;
  }

  chess.PieceType _mapPromotionLetter(String letter) {
    switch (letter.toLowerCase()) {
      case 'q':
        return chess.PieceType.QUEEN;
      case 'r':
        return chess.PieceType.ROOK;
      case 'b':
        return chess.PieceType.BISHOP;
      case 'n':
        return chess.PieceType.KNIGHT;
      default:
        throw ArgumentError("Letra de promoción no válida: $letter");
    }
  }

  Future<void> _exitGame(String message) async {
    if (!context.mounted) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String estadoUser = prefs.getString('estadoUser') ?? "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                message.toLowerCase().contains("has ganado")
                    ? Icons.emoji_events
                    : message.toLowerCase().contains("tablas")
                    ? Icons.handshake
                    : Icons.sentiment_dissatisfied,
                size: 60,
                color: message.toLowerCase().contains("has ganado")
                    ? Colors.amber
                    : message.toLowerCase().contains("tablas")
                    ? Colors.blueAccent
                    : Colors.redAccent,
              ),
              SizedBox(height: 20),
              Text(
                "Fin de la partida",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              SizedBox(height: 20),
              // Botones normales como querías
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(context, Init_page.id);
                    },
                    child: Text(
                      "Volver al inicio",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  if (estadoUser != "guest") // Solo si no es invitado
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        print("PGN sin tags: ${chessGame.pgn()}");
                        final pgnFinal = generarPGNConTags(
                          pgnBody: chessGame.pgn(),
                          myId: idJugador ?? "yo",
                          rivalId: widget.rivalName,
                          myAlias: miNombre ?? "Tú",
                          rivalAlias: widget.rivalName,
                          myElo: widget.myElo,
                          rivalElo: widget.rivalElo,
                          soyBlancas: playerColor == PlayerColor.white,
                        );
                        final movimientosConvertidos = transformarMovimientosConPromocion(_historialMovimientos);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameReviewPage(
                              historial: movimientosConvertidos,
                              pgn: pgnFinal,
                              rival: widget.rivalName,
                              miElo: widget.myElo.toString(),
                              rivalElo: widget.rivalElo.toString(),
                              yo: miNombre ?? "Tú",
                              rivalFoto: getRutaSeguraFoto(playerColor == PlayerColor.white ? fotoNegras : fotoBlancas),
                              miFoto: getRutaSeguraFoto(playerColor == PlayerColor.white ? fotoBlancas : fotoNegras),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Analizar partida",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
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
        if (whiteTime == 0 && playerColor == PlayerColor.white) await _handleTimeout(isWhite: true);
      }
    });

    _timerBlack = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!isWhiteTurn && blackTime > 0) {
        setState(() {
          blackTime--;
        });
        if (blackTime == 0 && playerColor == PlayerColor.black) await _handleTimeout(isWhite: false);
      }
    });
  }

  Future<void> _sendMoveToServer(String from, String to, String? promotion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idJugador = prefs.getString('idJugador');
    String movimiento;

    if (promotion != null) {
      movimiento = "$from$to$promotion";
      print("$movimiento");
    }
    else{
      movimiento = "$from$to";
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
      socket.emit('resign', {
        "idPartida": widget.gameId,
        "idJugador": idJugador,
      });
    }
  }

  Future<void> _confirmarRendicion() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, size: 48, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  "¿Seguro que quieres rendirte?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancelar"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _surrender();
                      },
                      child: Text("Rendirse"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
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

  void _confirmDrawOffer() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 48, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                "¿Deseas ofrecer tablas?",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                "Tu oponente podrá aceptarlas o rechazarlas.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Cancelar"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _offerDraw();
                    },
                    child: Text("Ofrecer"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDrawOfferDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.handshake,
                  size: 60,
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 20),
                Text(
                  "Oferta de tablas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Tu oponente ha ofrecido tablas. ¿Aceptas?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        "Rechazar",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        "Aceptar",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSimpleDialog(String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true, // Puedes cerrar tocando fuera del dialog
      builder: (context) => Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 60,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              Text(
                "Información",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Aceptar",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            ],
          ),
        ),
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: Text(
            _isLoaded ? gameMode : "",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: !_isLoaded
            ? Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        )
            : Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 36), // margen superior
                  // 🧍‍♂️ Rival con avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                getRutaSeguraFoto(playerColor == PlayerColor.white ? fotoNegras : fotoBlancas),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerColor == PlayerColor.white ? nombreNegras : nombreBlancas,
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "ELO: ${playerColor == PlayerColor.white ? eloNegras : eloBlancas}",
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          "${((playerColor == PlayerColor.white ? blackTime : whiteTime) ~/ 60).toString().padLeft(2, '0')}:${((playerColor == PlayerColor.white ? blackTime : whiteTime) % 60).toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12), // entre nombre y tablero

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.95, // tablero cuadrado proporcional
                      child: ChessBoard(
                        controller: controller,
                        boardOrientation: playerColor,
                        enableUserMoves:
                        (isWhiteTurn && playerColor == PlayerColor.white) ||
                            (!isWhiteTurn && playerColor == PlayerColor.black),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // 🧍‍♂️ Tú con avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                getRutaSeguraFoto(playerColor == PlayerColor.white ? fotoBlancas : fotoNegras),
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerColor == PlayerColor.white ? nombreBlancas : nombreNegras,
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "ELO: ${playerColor == PlayerColor.white ? eloBlancas : eloNegras}",
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          "${((playerColor == PlayerColor.white ? whiteTime : blackTime) ~/ 60).toString().padLeft(2, '0')}:${((playerColor == PlayerColor.white ? whiteTime : blackTime) % 60).toString().padLeft(2, '0')}",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 36), // aire antes de los botones
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _confirmDrawOffer,
                          icon: Icon(Icons.handshake, color: Colors.blue),
                          label: Text("Ofrecer tablas"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _confirmarRendicion,
                          icon: Icon(Icons.flag, color: Colors.white),
                          label: Text("Rendirse"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Nueva fila para botones flotantes
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: "chatFAB",
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.chat, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isChatVisible = !_isChatVisible;
                            });
                          },
                        ),
                        FloatingActionButton(
                          heroTag: "movesFAB",
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.list_alt, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isMovesVisible = !_isMovesVisible;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isChatVisible)
              Positioned(
                bottom: 170,
                right: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.all(12), // Más espacio interior
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // Fondo oscuro acorde con el tema
                    borderRadius: BorderRadius.circular(16), // Bordes redondeados
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4), // Sombra suave abajo
                      ),
                    ],
                  ),
                  height: 200,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _mensajesChat.length,
                          itemBuilder: (context, index) => Text(
                            _mensajesChat[index],
                            style: TextStyle(color: Colors.white), // Texto blanco para contraste
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: TextStyle(color: Colors.grey[900]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white, // Fondo sutil del campo de texto
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.blueAccent), // Icono en azul
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
                bottom: 170,
                right: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.all(12), // Más espacio interior
                  decoration: BoxDecoration(
                    color: Colors.grey[850], // Fondo oscuro acorde con el tema
                    borderRadius: BorderRadius.circular(16), // Bordes redondeados
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4), // Sombra suave abajo
                      ),
                    ],
                  ),
                  height: 200,
                  child: Column(
                    children: [
                      Text(
                        "Movimientos",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _historialMovimientos.length,
                          itemBuilder: (context, index) => Text(
                            "${index + 1}. ${_historialMovimientos[index]}",
                            style: TextStyle(color: Colors.white70), // Texto en gris suave
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

      ),
    );
  }
}
