import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/friends.dart';
import 'package:frontend_android/pages/Game/init.dart';
import 'package:frontend_android/pages/Game/settings.dart';
import 'package:frontend_android/pages/Game/ranking.dart';
import 'package:frontend_android/pages/Game/learn.dart';


class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Si ya está en la página, no hace nada

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Init_page()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Ranking_page()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LearnPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Friends_Page()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Settings_page()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarIcon(context, Icons.home, 0),
          _buildNavBarIcon(context, Icons.emoji_events, 1),
          _buildNavBarIcon(context, Icons.folder, 2),
          _buildNavBarIcon(context, Icons.group, 3),
          _buildNavBarIcon(context, Icons.settings, 4),
        ],
      ),
    );
  }

  Widget _buildNavBarIcon(BuildContext context, IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: index == currentIndex ? Colors.white : Colors.grey,
        size: 32,
      ),
      onPressed: () => _onItemTapped(context, index),
    );
  }
}
