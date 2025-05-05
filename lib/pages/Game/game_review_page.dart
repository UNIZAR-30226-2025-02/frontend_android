import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Game/init.dart';
import 'package:stockfish/stockfish.dart';
import 'package:chess/chess.dart' as chess;




class GameReviewPage extends StatefulWidget {
  static const String id = "game_review_page";
  final List<String> historial;

  final String pgn;

  const GameReviewPage({Key? key, required this.historial, required this.pgn}) : super(key: key);

  @override
  _GameReviewPageState createState() => _GameReviewPageState();
}


class _GameReviewPageState extends State<GameReviewPage> {
  final ChessBoardController _controller = ChessBoardController();
  final chess.Chess _game = chess.Chess();  // el motor para parsear SAN
  final List<Map<String,String>> _moveStack = [];
  final List<String> _moveStackReal = []; // Guarda los movimientos reales tipo 'e5-g6'
  late final Stockfish _engine;
  String? _bestMove;
  int? _previousCp;
  String? _bestMoveWhite;
  String? _bestMoveBlack;
  String? _moveClassificationWhite;
  String? _moveClassificationBlack;
  final List<int> _cpLossesWhite = [];
  final List<int> _cpLossesBlack = [];
  int? _previousCpWhite;
  int? _previousCpBlack;

  final List<int> _cpLosses = [];
  String? _moveClassification;

  int _currentCp = 0;
  StreamSubscription<String>? _stdoutSub;

  int moveIndex = -1;
  late final String? serverBackend;
  bool esJugadorBlancas = true;

  @override
  void initState() {
    super.initState();
    _engine = Stockfish();

    SharedPreferences.getInstance().then((prefs) {
      final userId = prefs.getString('idJugador') ?? '';
      final pgn = widget.historial.join(' ');

      final whiteMatch = RegExp(r'\[White "(.*?)"\]').firstMatch(widget.pgn);
      final whiteId = whiteMatch?.group(1) ?? '';

      setState(() {
        esJugadorBlancas = (userId == whiteId);
      });
    });

    // 1) Escucha la salida para parsear 'score cp ...'
    _stdoutSub = _engine.stdout.listen((line) {
      final cpMatch = RegExp(r'score cp (-?\d+)').firstMatch(line);
      if (cpMatch != null) {
        final cp = int.parse(cpMatch.group(1)!);
        setState(() {
          _currentCp = cp;
        });
      }

      final bestMatch = RegExp(r'bestmove (\w{4})').firstMatch(line);
      if (bestMatch != null) {
        final best = bestMatch.group(1)!;
        final isWhiteTurn = moveIndex % 2 == 0;

        setState(() {
          if (isWhiteTurn) {
            _bestMoveWhite = best;
            if (_previousCpWhite != null) {
              final loss = (_previousCpWhite! - _currentCp).abs();
              _cpLossesWhite.add(loss);
              _moveClassificationWhite = _classifyMove(loss);
            }
            _previousCpWhite = _currentCp;
          } else {
            _bestMoveBlack = best;
            if (_previousCpBlack != null) {
              final loss = (_previousCpBlack! - _currentCp).abs();
              _cpLossesBlack.add(loss);
              _moveClassificationBlack = _classifyMove(loss);
            }
            _previousCpBlack = _currentCp;
          }
        });
      }
    });


    // 2) Espera hasta que state cambie a ready, y entonces envía tus primeros comandos
    _engine.state.addListener(() {
      if (_engine.state.value == StockfishState.ready) {
        // Ahora ya está listo: podemos pedirle que compruebe isready y luego evaluar
        _engine.stdin = 'isready';
        _evaluatePosition();
      }
    });
  }

  double get acpl {
    if (_cpLosses.isEmpty) return 0;
    return _cpLosses.reduce((a, b) => a + b) / _cpLosses.length;
  }

  String _classifyMove(int cpLoss) {
    if (cpLoss == 0) return 'Brillante';
    if (cpLoss <= 20) return 'Excelente';
    if (cpLoss <= 50) return 'Buena';
    if (cpLoss <= 100) return 'Inexacta';
    if (cpLoss <= 200) return 'Error';
    return 'Blunder';
  }


  void _evaluatePosition() {
    // Si no está listo, ignora la llamada
    if (_engine.state.value != StockfishState.ready) return;

    // OK, envío la posición y pido el análisis
    final fen = _controller.value.fen;
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'go depth 10';
  }

  chess.PieceType _mapPromotionLetterToPieceType(String letter) {
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
        throw ArgumentError('Letra de promoción no válida: $letter');
    }
  }
  void _showGameOverPopup(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.flag, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text("Fin de la partida", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(mensaje, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.home, color: Colors.blueAccent),
            label: Text("Inicio", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              _goBackToStart();
            },
          ),
          TextButton.icon(
            icon: Icon(Icons.replay, color: Colors.blueAccent),
            label: Text("Reiniciar", style: TextStyle(color: Colors.blueAccent)),
            onPressed: () {
              Navigator.pop(context);
              _restartReview();
            },
          ),
        ],
      ),
    );
  }

  void _nextMove() {
    if (moveIndex < widget.historial.length - 1) {
      moveIndex++;
      final moveStr = widget.historial[moveIndex];
      print('REPE moveStr: $moveStr');

      final fromSquare = moveStr.substring(0, 2);
      final toSquare = moveStr.substring(2, 4);
      final promotionLetter = moveStr.length == 5 ? moveStr[4] : null;

      final legals = _game.generate_moves();
      print('REPE legal moves count: ${legals.length}');

      chess.Move? m;
      for (final mv in legals) {
        final fromMatches = chess.Chess.algebraic(mv.from) == fromSquare;
        final toMatches = chess.Chess.algebraic(mv.to) == toSquare;

        bool promoMatches = true;
        if (promotionLetter != null) {
          final expected = _mapPromotionLetterToPieceType(promotionLetter);
          promoMatches = mv.promotion == expected;
        }

        if (fromMatches && toMatches && promoMatches) {
          m = mv;
          break;
        }
      }

      if (m != null) {
        _moveStackReal.add('${chess.Chess.algebraic(m.from)}-${chess.Chess.algebraic(m.to)}');

        _game.make_move(m);
        print('REPE engine moved from ${chess.Chess.algebraic(m.from)} to ${chess.Chess.algebraic(m.to)}');

        final from = chess.Chess.algebraic(m.from);
        final to = chess.Chess.algebraic(m.to);
        if (promotionLetter != null) {
          _controller.makeMoveWithPromotion(
            from: from,
            to: to,
            pieceToPromoteTo: promotionLetter,
          );
        } else {
          _controller.makeMove(from: from, to: to);
        }

        _moveStack.add({'from': from, 'to': to});
        print('REPE moveStack length: ${_moveStack.length}');
      } else {
        print('REPE ❌ Movimiento no encontrado: $moveStr');
      }

      setState(() {});
      if (moveIndex == widget.historial.length - 1) {
        Future.delayed(Duration(milliseconds: 500), () {
          _showGameOverPopup("Has llegado al final de la partida.");
        });
      }

      _evaluatePosition();
    }
  }

  double _whiteAdvantage() => ((_currentCp.clamp(-1000, 1000) + 1000) / 20.0);
  double _blackAdvantage() => 100.0 - _whiteAdvantage();

// Y en tu clase, usa este _previousMove() instrumentado:
  void _previousMove() {

    if (moveIndex >= 0) {
      moveIndex--;
      _game.reset();
      _controller.resetBoard();
      _moveStack.clear();
      _moveStackReal.clear();

      for (int i = 0; i <= moveIndex; i++) {
        final rawSan = widget.historial[i];
        String san = rawSan.replaceAll(RegExp(r'[+#]'), '');

        if (san.contains('=')) {
          san = san.split('=').first;
        }

        final toSquare = san.substring(san.length - 2).toLowerCase();
        final legals = _game.generate_moves();
        final matches = legals.where((mv) => chess.Chess.algebraic(mv.to) == toSquare);
        final chess.Move? m = matches.isNotEmpty ? matches.first : null;

        if (m != null) {
          _game.make_move(m);
          final fromSquare = chess.Chess.algebraic(m.from);
          _controller.makeMove(from: fromSquare, to: toSquare);
          _moveStack.add({'from': fromSquare, 'to': toSquare});
          _moveStackReal.add('$fromSquare-$toSquare');
        } else {
          print("REPE ▶ ❌ No se pudo rehacer movimiento $san");
        }
      }
      setState(() {});
      _evaluatePosition();
    } else {
      print("REPE ▶ Ya estás al inicio de la partida.");
    }
  }

  double get acplWhite {
    if (_cpLossesWhite.isEmpty) return 0;
    return _cpLossesWhite.reduce((a, b) => a + b) / _cpLossesWhite.length;
  }

  double get acplBlack {
    if (_cpLossesBlack.isEmpty) return 0;
    return _cpLossesBlack.reduce((a, b) => a + b) / _cpLossesBlack.length;
  }

  void _goBackToStart() {
    Navigator.pushReplacementNamed(context, Init_page.id);
  }

  // 1) Método para reiniciar por completo la revisión
  void _restartReview() {
    // Reinicia el motor y el tablero UI
    _game.reset();
    _controller.resetBoard();

    // Vuelve al índice inicial y limpia tus pilas
    moveIndex = -1;
    _moveStack.clear();
    _moveStackReal.clear();

    setState(() {});
  }

  Widget _buildBarraVentajaBlanca() => Column(
    children: [
      Text("Ventaja blanca: ${_whiteAdvantage().round()}/100", style: TextStyle(color: Colors.white70)),
      Container(
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(flex: _whiteAdvantage().round(), child: Container(color: Colors.blueAccent)),
            Expanded(flex: (100 - _whiteAdvantage().round()), child: Container(color: Colors.grey[800])),
          ],
        ),
      ),
    ],
  );

  Widget _buildBarraVentajaNegra() => Column(
    children: [
      Text("Ventaja negra: ${_blackAdvantage().round()}/100", style: TextStyle(color: Colors.white70)),
      Container(
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(flex: _blackAdvantage().round(), child: Container(color: Colors.redAccent)),
            Expanded(flex: (100 - _blackAdvantage().round()), child: Container(color: Colors.grey[800])),
          ],
        ),
      ),
    ],
  );

  Widget _buildTablero() => ChessBoard(
    controller: _controller,
    boardOrientation: esJugadorBlancas ? PlayerColor.white : PlayerColor.black,
    enableUserMoves: false,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Revisión de partida",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...(
                esJugadorBlancas
                    ? [
                  _buildBarraVentajaNegra(),
                  _buildTablero(),
                  _buildBarraVentajaBlanca(),
                ]
                    : [
                  _buildBarraVentajaBlanca(),
                  _buildTablero(),
                  _buildBarraVentajaNegra(),
                ]
            ),

            const SizedBox(height: 12),

            // Movimiento actual
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  moveIndex >= 0 ? widget.historial[moveIndex] : "Inicio de la partida",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔍 Análisis según el turno
            if (moveIndex % 2 == 0 && _bestMoveWhite != null) ...[
              Text('♙ Blancas',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Mejor jugada: ${_bestMoveWhite!.substring(0, 2)}-${_bestMoveWhite!.substring(2, 4)}',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ] else if (moveIndex % 2 == 1 && _bestMoveBlack != null) ...[
              Text('♟ Negras',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Mejor jugada: ${_bestMoveBlack!.substring(0, 2)}-${_bestMoveBlack!.substring(2, 4)}',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],

            const SizedBox(height: 16),

            // ⏮️ ⏭️ Botones de navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: moveIndex >= 0 ? Colors.white : Colors.grey),
                  onPressed: moveIndex >= 0 ? _previousMove : null,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.arrow_forward,
                      color: moveIndex == widget.historial.length - 1
                          ? Colors.grey
                          : Colors.white),
                  onPressed: moveIndex == widget.historial.length - 1 ? null : _nextMove,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _goBackToStart,
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text("Inicio", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _restartReview,
                  icon: const Icon(Icons.replay, color: Colors.white),
                  label: const Text("Reiniciar", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // mismo color que el de inicio
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _stdoutSub?.cancel();
    _engine.dispose();
    super.dispose();
  }



}
