import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/buildHead.dart';

class Rules_Page extends StatelessWidget {
  static const String id = "chess_rules_page";

  final List<Map<String, dynamic>> rules = [
    {
      'title': 'REGLA 1',
      'text': 'El rey no puede moverse a una casilla atacada.',
      'initialFen': '4k3/8/8/8/8/8/4R3/4K3 w - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 2',
      'text': 'Los peones pueden avanzar dos casillas solo en su primer movimiento.',
      'initialFen': '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
      'moves': ['e2 e4'],
    },
    {
      'title': 'REGLA 3',
      'text': 'Los caballos pueden saltar sobre otras piezas.',
      'initialFen': '4k3/8/8/3PPP2/2N1P3/8/8/4K3 w - - 0 1',
      'moves': ['c4 d6'],
    },
    {
      'title': 'REGLA 4',
      'text': 'El enroque solo es posible si el rey y la torre no se han movido.',
      'initialFen': '4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1',
      'moves': ['e1 g1'],
    },
    {
      'title': 'REGLA 5',
      'text': 'El jaque mate ocurre cuando el rey no puede escapar del ataque.',
      'initialFen': '6k1/5ppp/8/8/8/8/5PPP/6RK w - - 0 1',
      'moves': [],
    },{
      'title': 'REGLA 6',
      'text': 'La partida termina en tablas si no hay movimientos legales disponibles.',
      'initialFen': '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 7',
      'text': 'No se puede hacer un movimiento que deje al propio rey en jaque.',
      'initialFen': '4k3/8/8/4r3/8/8/8/4K3 w - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 8',
      'text': 'Si un peón alcanza la octava fila, debe ser promovido a otra pieza.',
      'initialFen': '4k3/P7/8/8/8/8/8/4K3 w - - 0 1',
      'moves': ['a7 a8'],
    },
    {
      'title': 'REGLA 9',
      'text': 'El enroque no es posible si el rey está en jaque o si pasa por una casilla atacada.',
      'initialFen': '4k2r/8/8/8/8/8/8/R3K2R w KQk - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 10',
      'text': 'La captura al paso solo se puede realizar inmediatamente después de que un peón rival avance dos casillas.',
      'initialFen': '4k3/8/8/8/3p4/8/4P3/4K3 w - - 0 1',
      'moves': ['e2 e4', 'd4 e3'],
    },
    {
      'title': 'REGLA 11',
      'text': 'Si la misma posición ocurre tres veces en la partida, se puede reclamar tablas.',
      'initialFen': '8/8/8/8/8/8/8/K6k w - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 12',
      'text': 'El jugador que se queda sin tiempo pierde la partida.',
      'initialFen': '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 13',
      'text': 'Un jugador no puede hacer un movimiento que deje a su propio rey en jaque.',
      'initialFen': '4k3/8/8/4r3/8/8/8/4K3 w - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 14',
      'text': 'Si un jugador no tiene movimientos legales y su rey no está en jaque, la partida termina en tablas por ahogado.',
      'initialFen': '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1',
      'moves': [],
    },
    {
      'title': 'REGLA 15',
      'text': 'La dama puede moverse cualquier cantidad de casillas en línea recta (horizontal, vertical o diagonal).',
      'initialFen': '4k3/8/8/4Q3/8/8/8/4K3 w - - 0 1',
      'moves': ['e5 e8'],
    },
    {
      'title': 'REGLA 16',
      'text': 'La torre se mueve cualquier cantidad de casillas en línea recta (horizontal o vertical).',
      'initialFen': '4k3/8/8/4R3/8/8/8/4K3 w - - 0 1',
      'moves': ['e5 e8'],
    },
    {
      'title': 'REGLA 17',
      'text': 'El alfil se mueve cualquier cantidad de casillas en línea diagonal.',
      'initialFen': '4k3/8/8/4B3/8/8/8/4K3 w - - 0 1',
      'moves': ['e5 h8'],
    },
    {
      'title': 'REGLA 18',
      'text': 'El caballo se mueve en forma de "L" y puede saltar sobre otras piezas.',
      'initialFen': '4k3/8/8/4N3/8/8/8/4K3 w - - 0 1',
      'moves': ['e5 d7'],
    },
    {
      'title': 'REGLA 19',
      'text': 'El peón captura en diagonal, no en línea recta.',
      'initialFen': '4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1',
      'moves': ['e5 d6'],
    },
    // Agrega las reglas restantes siguiendo el mismo formato...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadArrow(),
      body: ListView.builder(
        itemCount: rules.length,
        itemBuilder: (context, index) {
          return RuleCard(rule: rules[index]);
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

class RuleCard extends StatefulWidget {
  final Map<String, dynamic> rule;

  const RuleCard({Key? key, required this.rule}) : super(key: key);

  @override
  State<RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<RuleCard> {
  late ChessBoardController _controller;
  int moveIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = ChessBoardController();
    _controller.loadFen(widget.rule['initialFen']);
  }

  void _nextMove() {
    if (moveIndex < widget.rule['moves'].length - 1) {
      moveIndex++;
      var move = widget.rule['moves'][moveIndex].split(' ');
      _controller.makeMove(from: move[0], to: move[1]);
      setState(() {});
    }
  }

  void _previousMove() {
    if (moveIndex >= 0) {
      moveIndex--;
      _controller.loadFen(widget.rule['initialFen']);
      for (int i = 0; i <= moveIndex; i++) {
        final move = widget.rule['moves'][i].split(' ');
        if (move.length == 2) {
          _controller.makeMove(from: move[0], to: move[1]);
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMoves = widget.rule['moves'].isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SizedBox(
        height: 140, // 🔹 Fijamos la altura total de la tarjeta
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ChessBoard(
                    controller: _controller,
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
                      widget.rule['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Scrollbar(
                        thickness: 3,
                        radius: const Radius.circular(10),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            widget.rule['text'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasMoves)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: _previousMove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_forward,
                              color: moveIndex >= widget.rule['moves'].length - 1
                                  ? Colors.grey
                                  : Colors.white,
                            ),
                            onPressed: moveIndex >= widget.rule['moves'].length - 1
                                ? null
                                : _nextMove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}