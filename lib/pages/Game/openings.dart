import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
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

  // 👇 Map de posiciones FEN para cada apertura
  final Map<String, String> openingFens = {
    'Apertura Española': 'r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 2 3',
    'Defensa Siciliana': 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq c6 0 3',
    'Gambito de Dama': 'rnbqkbnr/ppp2ppp/8/3pp3/2P5/8/PP1PPPPP/RNBQKBNR b KQkq c3 0 2',
    'Defensa Francesa': 'rnbqkbnr/ppp2ppp/4p3/3p4/3PP3/8/PPP2PPP/RNBQKBNR w KQkq d6 0 4',
    'Apertura Italiana': 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 2 3',
  };

  final List<String> descriptions = [
    "La Apertura Española es una de las más clásicas, enfocándose en el control del centro y la presión temprana sobre el caballo de c6, buscando ventajas a largo plazo.",
    "La Defensa Siciliana ofrece a las negras una respuesta activa a 1.e4, generando un contrajuego dinámico y luchando por el control del flanco de dama desde el inicio.",
    "El Gambito de Dama es una apertura estratégica que ofrece un peón para lograr una mejor estructura central y un desarrollo rápido de las piezas blancas.",
    "La Defensa Francesa es una apertura sólida y estratégica que busca desafiar el centro blanco de manera indirecta, preparando rupturas y estructuras resistentes.",
    "La Apertura Italiana busca un desarrollo rápido de las piezas y un ataque temprano hacia el punto débil f7, combinando simplicidad y agresividad en la apertura.",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadArrow(),
      body: ListView.builder(
        itemCount: openings.length,
        itemBuilder: (context, index) {
          ChessBoardController controller = ChessBoardController();
          String fen = openingFens[openings[index]] ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
          controller.loadFen(fen);

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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12), // 👈 Bordes redondeados
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: ChessBoard(
                          controller: controller,
                          boardColor: BoardColor.brown,
                          boardOrientation: PlayerColor.white,
                          enableUserMoves: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            openings[index],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 70, // 👈 altura máxima para el texto scrollable
                            child: SingleChildScrollView(
                              child: Text(
                                descriptions[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

  const OpeningDetailPage({Key? key, required this.openingName}) : super(key: key);

  @override
  _OpeningDetailPageState createState() => _OpeningDetailPageState();
}

class _OpeningDetailPageState extends State<OpeningDetailPage> {
  final ChessBoardController _chessController = ChessBoardController();
  int moveIndex = -1;

  final Map<String, List<Map<String, String>>> openingMoves = {
    'Apertura Española': [
      {'e2 e4': 'Controla el centro y abre líneas para el desarrollo.'},
      {'e7 e5': 'Iguala la lucha por el centro.'},
      {'g1 f3': 'Desarrolla el caballo y ataca el peón de e5.'},
      {'b8 c6': 'Defiende el peón de e5 y desarrolla una pieza.'},
      {'f1 b5': 'Clava el caballo en c6 y prepara el enroque.'},
      {'FIN': 'FIN'}
    ],
    'Defensa Siciliana': [
      {'e2 e4': 'Controla el centro y libera la dama y el alfil.'},
      {'c7 c5': 'Busca un contrajuego rápido en el flanco de dama.'},
      {'g1 f3': 'Desarrolla el caballo y presiona en d4.'},
      {'d7 d6': 'Prepara el desarrollo del alfil y fortalece el centro.'},
      {'d2 d4': 'Rompe el centro para conseguir ventaja de espacio.'},
      {'FIN': 'FIN'}
    ],
    'Gambito de Dama': [
      {'d2 d4': 'Busca el control central y prepara el gambito.'},
      {'d7 d5': 'Iguala la lucha en el centro.'},
      {'c2 c4': 'Ofrece un peón a cambio de mejor desarrollo.'},
      {'FIN': 'FIN'}
    ],
    'Defensa Francesa': [
      {'e2 e4': 'Controla el centro y facilita el desarrollo.'},
      {'e7 e6': 'Prepara d5 para desafiar el centro blanco.'},
      {'d2 d4': 'Refuerza el control central.'},
      {'d7 d5': 'Rompe el centro y plantea una estructura sólida.'},
      {'FIN': 'FIN'}
    ],
    'Apertura Italiana': [
      {'e2 e4': 'Controla el centro y abre líneas para el desarrollo.'},
      {'e7 e5': 'Iguala la lucha por el centro.'},
      {'g1 f3': 'Desarrolla el caballo y ataca el peón de e5.'},
      {'b8 c6': 'Defiende el peón de e5 y desarrolla una pieza.'},
      {'f1 c4': 'Desarrolla el alfil a una casilla activa apuntando a f7.'},
      {'FIN': 'FIN'}
    ],
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
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadArrow(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // <-- Lo cambiamos a start mejor
        children: [
          const SizedBox(height: 20),
          Text(
            widget.openingName, // <-- Aquí mostramos el nombre de la apertura
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ChessBoard(
            controller: _chessController,
            boardOrientation: PlayerColor.white,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                explanation,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
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
