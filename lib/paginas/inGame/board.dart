import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter/material.dart';

/// Clase que representa la pantalla del tablero de ajedrez.
/// Muestra el tablero interactivo con el modo de juego seleccionado.
/// Además, coloca el nombre del jugador rival arriba y el nombre del jugador local abajo.
class BoardScreen extends StatelessWidget {
  static const id = "board_page"; // Identificador único para la pantalla del tablero.

  final ChessBoardController controller = ChessBoardController(); // Controlador del tablero de ajedrez.
  final String gameMode; // Modo de juego seleccionado (Ej: Partida Relámpago, Partida Estándar).

  /// Constructor que recibe el modo de juego y lo asigna a la variable `gameMode`.
  BoardScreen({required this.gameMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[200],
        title: Text(gameMode),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerInfo("Rival"), // Muestra el nombre del rival en la parte superior.
          Expanded(
            child: Center(
              child: ChessBoard(
                controller: controller,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
              ),
            ),
          ),
          _buildPlayerInfo("Yo"), // Muestra el nombre del jugador local en la parte inferior.
        ],
      ),
    );
  }

  /// Construye un widget de texto con el nombre del jugador.
  Widget _buildPlayerInfo(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
