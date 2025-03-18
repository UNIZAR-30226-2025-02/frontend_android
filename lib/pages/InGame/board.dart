import 'dart:async';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Game/init.dart';

class BoardScreen extends StatefulWidget {
  static const id = "board_page";
  final String gameMode;
  final String color;
  final String gameId;

  BoardScreen(this.gameMode, this.color, this.gameId);

  @override
  _BoardScreenState createState() => _BoardScreenState(gameId);
}

class _BoardScreenState extends State<BoardScreen> {
  final ChessBoardController controller = ChessBoardController();
  late PlayerColor playerColor;
  late Timer _timerWhite;
  late Timer _timerBlack;
  late final gameId;
  int whiteTime = 600;
  int blackTime = 600;
  bool isWhiteTurn = true;
  late IO.Socket socket;

  _BoardScreenState(String gameId){this.gameId = gameId;}

  @override
  void initState() {
    super.initState();
    playerColor = widget.color == "white" ? PlayerColor.white : PlayerColor.black;
    _startTimer();
    newSocket();

    controller.addListener(() {
      if (controller.isCheckMate()) {
        bool didIWin = (controller.game.turn == Color.WHITE && playerColor == PlayerColor.black) ||
            (controller.game.turn == Color.BLACK && playerColor == PlayerColor.white);
        _showCheckMateDialog(didWin: didIWin);
      }
      _sendMoveToServer(null, null);
      _switchTimer();
    });
  }
  void newSocket(){

    socket = IO.io('https://tu-servidor.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on("new-move", (data) {
      print("♟️ Movimiento recibido del servidor: $data");
      setState(() {
        try {
          var move = controller.game.move({
            "from": data['from'],
            "to": data['to'],
            "promotion": "q"
          });

          if (move != null) {
            _switchTimer();
            _sendMoveToServer(data['from'], data['to']);
          } else {
            print("❌ Movimiento inválido recibido: \${data['from']} -> \${data['to']}");
          }
        } catch (e) {
          print("⚠️ Error al procesar el movimiento: \$e");
        }
      });
    });
  }

  void _startTimer() {
    _timerWhite = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isWhiteTurn) {
        setState(() {
          if (whiteTime > 0) whiteTime--;
        });
      }
    });

    _timerBlack = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isWhiteTurn) {
        setState(() {
          if (blackTime > 0) blackTime--;
        });
      }
    });
  }

  void _sendMoveToServer(String? from, String? to) {
    if (from != null && to != null) {
      print("📡 Enviando movimiento al servidor: \$from -> \$to");
      socket.emit("make-move", {
        "from": from,
        "to": to,
        "gameId": gameId,
        "playerColor": playerColor == PlayerColor.white ? "white" : "black",
      });
    }
  }

  void _switchTimer() {
    setState(() {
      isWhiteTurn = !isWhiteTurn;
    });
  }

  @override
  void dispose() {
    _timerWhite.cancel();
    _timerBlack.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.gameMode, style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerInfo(playerColor == PlayerColor.white ? "Negras" : "Blancas", blackTime),
          Expanded(
            child: Center(
              child: ChessBoard(
                controller: controller,
                boardOrientation: playerColor,
              ),
            ),
          ),
          _buildPlayerInfo("Yo", whiteTime),
          SizedBox(height: 10),
          _buildChatButton(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(String name, int time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Text(
            "\${(time ~/ 60).toString().padLeft(2, '0')}:\${(time % 60).toString().padLeft(2, '0')}",
            style: TextStyle(fontSize: 16, color: Colors.white),
          )
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      onPressed: () {
        Navigator.pushNamed(context, '/chat');
      },
      child: Text('Abrir Chat', style: TextStyle(color: Colors.white)),
    );
  }

  void _showCheckMateDialog({required bool didWin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(didWin ? '¡Has ganado!' : 'Has perdido',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(didWin ? Icons.emoji_events : Icons.close,
                size: 40, color: didWin ? Colors.yellow : Colors.redAccent),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () { Navigator.pop(context);},
              child: Text('Revisar Partida', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Menú', style: TextStyle(color: Colors.white)),
              onPressed: () {Navigator.pushReplacementNamed(context, Init_page.id);},
            ),
          ],
        ),
      ),
    );
  }
}
