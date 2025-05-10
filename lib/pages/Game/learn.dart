import 'package:flutter/material.dart';
import 'package:frontend_android/widgets/app_layout.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/Game/rules.dart';
import 'package:frontend_android/pages/Game/openings.dart';

class LearnPage extends StatelessWidget {
  static const String id = "learn_page";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppLayout(
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
                    'APRENDER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.folder, color: Colors.white, size: 36),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(Icons.menu_book, 'APERTURAS', context, Openings_Page()),
                  _buildMenuItem(Icons.assignment, 'REGLAS', context, Rules_Page()),
                ],
              ),
            ),
            BottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, BuildContext context, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}