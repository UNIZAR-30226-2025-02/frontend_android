import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/buildHead.dart';

import '../Login/login.dart';

class GameMode {
  final String name;
  final IconData icon;
  final String time;
  final String description;
  final Color color;

  GameMode(this.name, this.icon, this.time, this.description, this.color);
}

class Friends_Page extends StatefulWidget {
  static const String id = "friends_page";
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<Friends_Page> {
  List<String> friends = ["Amigo 1", "Amigo 2", "Amigo 3", "Amigo 4", "Amigo 5"];
  String? challengedFriend;
  GameMode? selectedGameMode;

  final List<GameMode> gameModes = [
    GameMode("Clásica", Icons.extension, "10 min", "Modo tradicional de ajedrez. Cada jugador consta de 10 min para realizar sus movimientos", Colors.brown),
    GameMode("Principiante", Icons.verified, "30 min", "Ideal para quienes están aprendiendo. Cada jugador consta de 30 min para realizar sus movimientos", Colors.green),
    GameMode("Avanzado", Icons.timer_off, "5 min", "Para jugadores experimentados. Cada jugador consta de 5 min para realizar sus movimientos", Colors.red),
    GameMode("Relámpago", Icons.bolt, "3 min", "Modo para expertos. El tiempo es muy limitado, cada jugador cuenta con 3 minutos.", Colors.yellow),
    GameMode("Incremento", Icons.trending_up, "15 min + 10 seg", "Cada jugada suma 10 segundos al tiempo del jugador.", Colors.green),
    GameMode("Incremento exprés", Icons.star, "3 min + 2 seg", "Partidas rápidas con incremento de 2 segundos por jugada.", Colors.yellow),
  ];

  void _removeFriend(String friend) {
    setState(() {
      friends.remove(friend);
    });
  }

  void _showGameModes(BuildContext context, String friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: gameModes.map((mode) {
              return ListTile(
                leading: Icon(mode.icon, color: mode.color),
                title: Text(mode.name, style: TextStyle(color: Colors.white)),
                subtitle: Text(mode.time, style: TextStyle(color: Colors.white70)),
                onTap: () {
                  setState(() {
                    selectedGameMode = mode;
                    challengedFriend = friend;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar por nombre de usuario',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: ListTile(
                    title: Text(friends[index], style: TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _removeFriend(friends[index]),
                        ),
                        IconButton(
                          icon: Icon(Icons.public, color: Colors.blue),
                          onPressed: () => _showGameModes(context, friends[index]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (challengedFriend != null && selectedGameMode != null)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("Has retado a $challengedFriend en modo ${selectedGameMode!.name}", style: TextStyle(color: Colors.white)),
                  Icon(selectedGameMode!.icon, color: selectedGameMode!.color),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        challengedFriend = null;
                        selectedGameMode = null;
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
