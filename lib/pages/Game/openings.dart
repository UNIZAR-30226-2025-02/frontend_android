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
    'Apertura Italiana',

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
      ]),
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

  final Map<String, List<Map<String, String>>> openingMoves = {
    'Apertura Española': [
      {'e2 e4': 'e2 e4 Controla el centro y abre líneas para el desarrollo.'},
      {'e7 e5': 'e7 e5 Iguala la lucha por el centro.'},
      {'g1 f3': 'g1 f3 Desarrolla el caballo y ataca el peón de e5.'},
      {'b8 c6': 'b8 c6 Defiende el peón de e5 y desarrolla una pieza.'},
      {'f1 b5': 'f1 b5 Clava el caballo en c6 y prepara el enroque.'},
      {'FIN':'FIN'}
    ],
    'Defensa Siciliana': [
      {'e2 e4': 'e2 e4 Controla el centro y libera la dama y el alfil.'},
      {'c7 c5': 'c7 c5 Busca un contrajuego rápido en el flanco de dama.'},
      {'g1 f3': 'g1 f3 Desarrolla el caballo y presiona en d4.'},
      {'d7 d6': 'd7 d6 Prepara el desarrollo del alfil y fortalece el centro.'},
      {'d2 d4': 'd2 d4 Rompe el centro para conseguir ventaja de espacio.'},
      {'FIN':'FIN'}
    ],
    'Gambito de Dama': [
      {'d2 d4': 'd2 d4 Busca el control central y prepara el gambito.'},
      {'d7 d5': 'd7 d5 Iguala la lucha en el centro.'},
      {'c2 c4': 'c2 c4 Ofrece un peón a cambio de mejor desarrollo.'},
      {'FIN':'FIN'}
    ],
    'Defensa Francesa': [
      {'e2 e4': 'e2 e4 Controla el centro y facilita el desarrollo.'},
      {'e7 e6': 'e7 e6 Prepara d5 para desafiar el centro blanco.'},
      {'d2 d4': 'd2 d4 Refuerza el control central.'},
      {'d7 d5': 'd7 d5 Rompe el centro y plantea una estructura sólida.'},
      {'FIN':'FIN'}
    ],
    'Apertura Italiana': [
      {'e2 e4': 'e2 e4 Controla el centro y abre líneas para el desarrollo.'},
      {'e7 e5': 'e7 e5 Iguala la lucha por el centro.'},
      {'g1 f3': 'g1 f3 Desarrolla el caballo y ataca el peón de e5.'},
      {'b8 c6': 'b8 c6 Defiende el peón de e5 y desarrolla una pieza.'},
      {'f1 c4': 'f1 c4 Desarrolla el alfil a una casilla activa apuntando a f7.'},
      {'FIN':'FIN'}
    ]
  };

  List<Map<String, String>> moves = [];

  @override
  void initState() {
    super.initState();
    moves = openingMoves[widget.openingName] ?? [];
  }

  void _nextMove() {
    if (moveIndex < moves.length - 1) {
      moveIndex++;
      String move = moves[moveIndex].keys.first;
      List<String> moveParts = move.split(' ');
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
    String explanation = moveIndex >= 0 ? moves[moveIndex].values.first : 'Inicio de la partida';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white, size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Login_page()),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChessBoard(
            controller: _chessController,
            boardOrientation: PlayerColor.black,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              explanation,
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: _previousMove),
              IconButton(icon: Icon(Icons.arrow_forward, color: isLastMove ? Colors.grey : Colors.white), onPressed: isLastMove ? null : _nextMove),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}
