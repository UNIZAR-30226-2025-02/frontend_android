import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';

import '../Login/login.dart';
import '../buildHead.dart';

class Ranking_page extends StatelessWidget {
  static const String id = "ranking_page";

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
      body: Column(
        children: [
          Container(
            color: Colors.grey[850],
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RANKING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.emoji_events, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildGameModeItem(Icons.bolt, 'RELÁMPAGO'),
                _buildGameModeItem(Icons.fast_forward, 'TIEMPO'),
                _buildGameModeItem(Icons.show_chart, 'ESTÁNDAR'),
                _buildGameModeItem(Icons.access_time, 'TIEMPO'),
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