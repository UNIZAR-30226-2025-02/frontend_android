import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/buildHead.dart';

class Openings_Page extends StatelessWidget {
  static const String id = "openings_page";

  final List<String> openings = [
    'Apertura Española',
    'Defensa Siciliana',
    'Gambito de Dama',
    'Defensa Francesa',
    'Apertura Italiana'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: BuildHeadLogo(actions: [
        IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Login_page()),
            );
          },
        ),
      ],),
      body: ListView.builder(
        itemCount: openings.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpeningDetailPage(openingName: openings[index]),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.menu_book, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Text(
                    openings[index],
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

class OpeningDetailPage extends StatefulWidget {
  final String openingName;

  const OpeningDetailPage({super.key, required this.openingName});

  @override
  _OpeningDetailPageState createState() => _OpeningDetailPageState();
}

class _OpeningDetailPageState extends State<OpeningDetailPage> {
  final ChessBoardController _chessController = ChessBoardController();
  int moveIndex = -1;

  final Map<String, List<String>> openingMoves = {
    'Apertura Española': ['e2 e4', 'e7 e5', 'g1 f3', 'b8 c6', 'f1 b5'],
    'Defensa Siciliana': ['e2 e4', 'c7 c5', 'g1 f3', 'd7 d6', 'd2 d4'],
    'Gambito de Dama': ['d2 d4', 'd7 d5', 'c2 c4'],
    'Defensa Francesa': ['e2 e4', 'e7 e6', 'd2 d4', 'd7 d5'],
    'Apertura Italiana': ['e2 e4', 'e7 e5', 'g1 f3', 'b8 c6', 'f1 c4']
  };

  List<String> moves = [];

  @override
  void initState() {
    super.initState();
    moves = openingMoves[widget.openingName] ?? [];
  }

  void _nextMove() {
    if (moveIndex < moves.length - 1) {
      moveIndex++;
      List<String> moveParts = moves[moveIndex].split(' ');
      if (moveParts.length == 2) {
        _chessController.makeMove(from: moveParts[0], to: moveParts[1]);
      }
      setState(() {});
    }
  }

  void _previousMove() {
    if (moveIndex >= 0) {
      _chessController.undoMove();
      setState(() {
        moveIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLastMove = moveIndex == moves.length - 1;

    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: BuildHeadLogo(actions: [
        IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Login_page()),
            );
          },
        ),
      ],),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChessBoard(
            controller: _chessController,
            boardOrientation: PlayerColor.black,
          ),
          SizedBox(height: 20),
          Text(
            isLastMove ? 'FIN' : (moveIndex >= 0 ? 'Movimiento: ${moves[moveIndex]}' : 'Inicio de la partida'),
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _previousMove,
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: isLastMove ? Colors.grey : Colors.white),
                onPressed: isLastMove ? null : _nextMove,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}
