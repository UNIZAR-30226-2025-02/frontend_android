import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockfish/stockfish.dart';
import 'package:chess/chess.dart' as chess;

import 'init.dart';

class GameReviewPage extends StatefulWidget {
  static const String id = "game_review_page";
  final List<String> historial;
  final String miElo;
  final String rivalElo;
  final String pgn;
  final String rival;
  final String yo;
  final String rivalFoto;
  final String miFoto;

  const GameReviewPage({Key? key, required this.historial, required this.pgn, required this.rival,
    required this.rivalElo, required this.miElo, required this.yo,
    required this.rivalFoto, required this.miFoto}) : super(key: key);

  @override
  _GameReviewPageState createState() => _GameReviewPageState();
}


class _GameReviewPageState extends State<GameReviewPage> {
  final ChessBoardController _controller = ChessBoardController();
  final chess.Chess _game = chess.Chess();
  final List<Map<String,String>> _moveStack = [];
  final List<String> _moveStackReal = [];
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

    _engine.state.addListener(() {
      if (_engine.state.value == StockfishState.ready) {
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
    if (_engine.state.value != StockfishState.ready) return;

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
      final fromSquare = moveStr.substring(0, 2);
      final toSquare = moveStr.substring(2, 4);
      final promotionLetter = moveStr.length == 5 ? moveStr[4] : null;
      final legals = _game.generate_moves();

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
      } else {
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
        }
      }
      setState(() {});
      _evaluatePosition();
    } else {
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

  void _restartReview() {
    _game.reset();
    _controller.resetBoard();
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
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 16.0, bottom: 4.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(widget.rivalFoto),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.rival} (${widget.rivalElo})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBarraVentajaNegra(),
                  _buildTablero(),
                  _buildBarraVentajaBlanca(),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 4.0, bottom: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(widget.miFoto),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.yo} (${widget.miElo})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                    : [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(widget.rivalFoto),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.rival} (${widget.rivalElo})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBarraVentajaBlanca(),
                  _buildTablero(),
                  _buildBarraVentajaNegra(),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(widget.miFoto),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${widget.yo} (${widget.miElo})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  moveIndex >= 0
                      ? widget.historial[moveIndex]
                      : "Inicio de la partida",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: moveIndex >= 0 ? Colors.white : Colors.grey,
                  ),
                  onPressed: moveIndex >= 0 ? _previousMove : null,
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward,
                    color: moveIndex == widget.historial.length - 1 ? Colors.grey : Colors.white,
                  ),
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
                  label: const Text("Volver", style: TextStyle(color: Colors.white)),
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
                    backgroundColor: Colors.blueAccent,
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
