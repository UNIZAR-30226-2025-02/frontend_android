import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../Game/init.dart'; // Ajusta la ruta si es necesario

class GameReviewPage extends StatefulWidget {
  final List<String> historial;

  const GameReviewPage({Key? key, required this.historial}) : super(key: key);

  @override
  _GameReviewPageState createState() => _GameReviewPageState();
}

class _GameReviewPageState extends State<GameReviewPage> {
  final ChessBoardController _controller = ChessBoardController();
  int moveIndex = -1;

  void _nextMove() {
    if (moveIndex < widget.historial.length - 1) {
      moveIndex++;
      final parts = widget.historial[moveIndex].split("-");
      if (parts.length >= 2) {
        _controller.makeMove(from: parts[0].toLowerCase(), to: parts[1].toLowerCase());
      }
      setState(() {});
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
