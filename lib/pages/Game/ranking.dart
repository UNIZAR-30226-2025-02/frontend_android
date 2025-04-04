import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';

import '../Login/login.dart';
import '../buildHead.dart';

class Ranking_page extends StatelessWidget {
  static const String id = "ranking_page";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Fondo oscuro
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
        children: [
          SizedBox(height: 16),
          Container(
            color: Colors.grey[900],
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RANKING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.emoji_events, color: Colors.white, size: 36),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildGameModeItem(Icons.extension, 'CLÁSICA'),
                _buildGameModeItem(Icons.verified, 'PRINCIPIANTE'),
                _buildGameModeItem(Icons.timer_off, 'AVANZADO'),
                _buildGameModeItem(Icons.bolt, 'RELÁMPAGO'),
                _buildGameModeItem(Icons.trending_up, 'INCREMENTO'),
                _buildGameModeItem(Icons.star, 'INCREMENTO EXPRÉS'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1), // Índice de "Ranking"
    );
  }

  Widget _buildGameModeItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}