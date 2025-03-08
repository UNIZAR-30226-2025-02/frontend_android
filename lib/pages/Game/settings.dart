import 'package:flutter/material.dart';
import 'package:frontend_android/pages/Game/botton_nav_bar.dart';
import 'package:frontend_android/pages/Game/profile.dart';

import '../Presentation/wellcome.dart';

class Settings_page extends StatelessWidget {
  static const String id = "setting_page";



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // Color oscuro para la barra superior
        title: Text(
          'CHECKMATES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[850],
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AJUSTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                Icon(Icons.settings, color: Colors.white),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.person, 'PERFIL', () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Profile_page()),
                        (route) => true, // Elimina todas las rutas previas
                  );
                }),
                _buildMenuItem(Icons.group, 'AMIGOS', () {

                }),
               /* _buildMenuItem(Icons.emoji_events, 'RANKING', () {
                  Navigator.pushNamed(context, '/ranking');
                }),*/
               /* _buildMenuItem(Icons.star, 'VALORA LA APP', () {
                  // Aquí puedes agregar la lógica para valorar la app
                  print('Valorar la app');
                }),*/
                /*_buildMenuItem(Icons.play_arrow, 'HISTORIAL PARTIDAS', () {
                  Navigator.pushNamed(context, '');
                }),*/
                _buildMenuItem(Icons.close, 'CERRAR SESIÓN', () {
                  _confirmCloseSession(context);

                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4), // Índice de "Ajustes"
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
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

  void _confirmCloseSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cerrar sesión"),
          content: Text("¿Estás seguro de que quieres cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin hacer nada
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _closeSession(context); // Ejecutar la función de cerrar sesión
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  void _closeSession(BuildContext context){
    // 🔹 2. Mostrar un mensaje (Opcional)
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Has cerrado sesión'))
    );

    // 🔹 3. Navegar a la pantalla de bienvenida
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => welcome_page()),
          (route) => false, // Elimina todas las rutas previas
    );
  }
}
