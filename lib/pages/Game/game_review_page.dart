import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

import '../Game/init.dart';
import 'package:stockfish/stockfish.dart';
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
  late final Stockfish _engine;
  int _currentCp = 0;
  StreamSubscription<String>? _stdoutSub;

  int moveIndex = -1;
  late final String? serverBackend;


  @override
  void initState() {
    super.initState();
    _engine = Stockfish();

    // 1) Escucha la salida para parsear 'score cp ...'
    _stdoutSub = _engine.stdout.listen((line) {
      final m = RegExp(r'score cp (-?\d+)').firstMatch(line);
      if (m != null) {
        setState(() {
          _currentCp = int.parse(m.group(1)!);
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


  void _evaluatePosition() {
    // Si no está listo, ignora la llamada
    if (_engine.state.value != StockfishState.ready) return;

    // OK, envío la posición y pido el análisis
    final fen = _controller.value.fen;
    _engine.stdin = 'position fen $fen';
    _engine.stdin = 'go depth 10';
  }




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
      _evaluatePosition();

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
      _evaluatePosition();
    } else {
      print("REPE ▶ Ya estás al inicio de la partida.");
    }
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Revisión de partida"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ─── Tu UI unchanged, dentro de un scroll para evitar overflow ───
          SingleChildScrollView(
            child: Column(
              children: [
                ChessBoard(
                  controller: _controller,
                  boardOrientation: PlayerColor.white,
                  enableUserMoves: false,
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
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
                      onPressed: moveIndex == widget.historial.length - 1
                          ? null
                          : _nextMove,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _goBackToStart,
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text("Volver al inicio",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _restartReview,
                  icon: const Icon(Icons.replay, color: Colors.white),
                  label: const Text("Reiniciar repetición",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ─── Aquí la barra, ajusta `left` y `width` hasta cuadrar con tu línea roja ───
          Positioned(
            left: 24,    // <–– pruébalo con 16, 24, 32… hasta que coincida
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,   // <–– grosor aproximado de tu línea roja
              color: Colors.grey[850], // fondo neutro
              child: LayoutBuilder(
                builder: (ctx, box) {
                  final cp = _currentCp.clamp(-1000, 1000).toDouble();
                  final pct = (cp + 1000) / 2000;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: pct,
                      widthFactor: 1,
                      child: Container(
                        color: cp >= 0
                            ? Colors.lightBlueAccent
                            : Colors.redAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
