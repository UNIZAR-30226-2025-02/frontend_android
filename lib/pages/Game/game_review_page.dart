import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Game/init.dart'; // Ajusta la ruta si es necesario

import 'package:chess/chess.dart' as chess;


class GameReviewPage extends StatefulWidget {
  final List<String> historial;

  const GameReviewPage({Key? key, required this.historial}) : super(key: key);

  @override
  _GameReviewPageState createState() => _GameReviewPageState();
}
class _GameReviewPageState extends State<GameReviewPage> {
  final ChessBoardController _controller = ChessBoardController();
  final chess.Chess _game = chess.Chess();  // el motor para parsear SAN
  final List<Map<String,String>> _moveStack = [];
  final List<String> _moveStackReal = []; // Guarda los movimientos reales tipo 'e5-g6'

  int moveIndex = -1;
  late final String? serverBackend;

  @override
  void initState() {
    super.initState();
  }

  @override
  void _nextMove() {
    if (moveIndex < widget.historial.length - 1) {
      moveIndex++;
      final rawSan = widget.historial[moveIndex];
      print('REPE rawSan: $rawSan');

      // 1) Limpia sufijos de jaque/mate
      String san = rawSan.replaceAll(RegExp(r'[+#]'), '');
      print('REPE sanitized SAN: $san');

      // 2) Quita notación de promoción si la hay
      if (san.contains('=')) {
        san = san.split('=').first;
        print('REPE after promotion removal SAN: $san');
      }

      // 3) Extrae las dos últimas pos-casilla: siempre es el 'to'
      final toSquare = san.substring(san.length - 2).toLowerCase();
      print('REPE toSquare: $toSquare');

      // 4) Genera movimientos legales y busca el que apunte ahí
      final legals = _game.generate_moves();
      print('REPE legal moves count: ${legals.length}');
      final matches = legals.where(
              (mv) => chess.Chess.algebraic(mv.to) == toSquare
      );
      print('REPE matches count: ${matches.length}');
      final chess.Move? m = matches.isNotEmpty ? matches.first : null;

      if (m != null) {
        _moveStackReal.add('${chess.Chess.algebraic(m.from)}-${chess.Chess.algebraic(m.to)}');

        // 5a) actualiza el motor
        _game.make_move(m);
        print('REPE engine moved from ${chess.Chess.algebraic(m.from)} to ${chess.Chess.algebraic(m.to)}');

        // 5b) extrae el 'from'
        final fromSquare = chess.Chess.algebraic(m.from);
        print('REPE fromSquare: $fromSquare');

        // 5c) mueve UI y apila
        _controller.makeMove(from: fromSquare, to: toSquare);
        _moveStack.add({'from': fromSquare, 'to': toSquare});
        print('REPE moveStack length: ${_moveStack.length}');
      } else {
        print('REPE No se encontró ningún movimiento a $toSquare');
      }

      setState(() {});
    }
  }

// Y en tu clase, usa este _previousMove() instrumentado:
  void _previousMove() {
    print("REPE ▶ _previousMove START: moveIndex=$moveIndex");

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

      print("REPE ▶ Retrocedido. Nuevo moveIndex=$moveIndex");
      setState(() {});
    } else {
      print("REPE ▶ Ya estás al inicio de la partida.");
    }
  }


  void _goBackToStart() {
    Navigator.pushReplacementNamed(context, Init_page.id);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Revisión de partida"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ChessBoard(
            controller: _controller,
            boardOrientation: PlayerColor.white,
            enableUserMoves: false,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 10),
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
                      color: moveIndex == widget.historial.length - 1
                          ? Colors.grey
                          : Colors.white,
                    ),
                    onPressed:
                        moveIndex == widget.historial.length - 1 ? null : _nextMove,
                  ),
                ],
              ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _goBackToStart,
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text("Volver al inicio", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
