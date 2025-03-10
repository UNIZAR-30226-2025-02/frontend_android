import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/Login/login.dart';
import 'package:frontend_android/pages/buildHead.dart';

class Rules_Page extends StatelessWidget {
  static const String id = "chess_rules_page";

  final List<String> rules = [
    'El rey no puede moverse a una casilla atacada.',
    'Los peones pueden avanzar dos casillas solo en su primer movimiento.',
    'Los caballos pueden saltar sobre otras piezas.',
    'El enroque solo es posible si el rey y la torre no se han movido.',
    'El jaque mate ocurre cuando el rey no puede escapar del ataque.',
    'La partida termina en tablas si no hay movimientos legales disponibles.',
    'No se puede hacer un movimiento que deje al propio rey en jaque.',
    'Si un peón alcanza la octava fila, debe ser promovido a otra pieza.',
    'El enroque no es posible si el rey está en jaque o si pasa por una casilla atacada.',
    'La captura al paso solo se puede realizar inmediatamente después de que un peón rival avance dos casillas.',
    'Si la misma posición ocurre tres veces en la partida, se puede reclamar tablas.',
    'El jugador que se queda sin tiempo pierde la partida.',
    'Un jugador no puede hacer un movimiento que deje a su propio rey en jaque.',
    'Si un jugador no tiene movimientos legales y su rey no está en jaque, la partida termina en tablas por ahogado.',
    'La dama puede moverse cualquier cantidad de casillas en línea recta (horizontal, vertical o diagonal).',
    'La torre se mueve cualquier cantidad de casillas en línea recta (horizontal o vertical).',
    'El alfil se mueve cualquier cantidad de casillas en línea diagonal.',
    'El caballo se mueve en forma de "L" y puede saltar sobre otras piezas.',
    'El peón captura en diagonal, no en línea recta.',
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
        itemCount: rules.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.rule, color: Colors.white, size: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    rules[index],
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}
