import 'package:flutter/material.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';

class Ranking_page extends StatelessWidget {
  static const String id = "ranking_page";

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Column(
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
          BottomNavBar(currentIndex: 1),
        ],
      ),
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
