import 'package:flutter/material.dart';

class Profile_page extends StatefulWidget {
  static const String id = "profile_page"; // Identificador para rutas de navegación

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile_page> {
  // Datos simulados del jugador
  String playerName = "Jugador123";
  int friends = 10;
  int gamesPlayed = 100;
  double winRate = 55.0;
  int maxStreak = 5;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // Hace la flecha visible en el fondo negro
        ),
        title: Image.asset(
          "assets/logoNombre.png",
          height: 40,
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'PERFIL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildProfileCard(), // Tarjeta con la información del jugador
            SizedBox(height: 20),
            Text(
              "Aquí irán los gráficos de rendimiento",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }


  // Widget para la tarjeta de perfil
  Widget _buildProfileCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.white24, blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinear texto a la izquierda
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage("assets/fotoPerfil.png"),
            ),
          ),
          SizedBox(height: 10),
          Stack(
            alignment: Alignment.center, // Asegura que el texto esté centrado
            children: [
              Center(
                child: Text(
                  playerName,
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0, // Lo coloca en el extremo derecho
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: () {
                    _showEditNameDialog();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text("Amigos: $friends", style: TextStyle(color: Colors.white, fontSize: 16)),
          Text("Partidas Jugadas: $gamesPlayed", style: TextStyle(color: Colors.white, fontSize: 16)),
          Text("Porcentaje de Victoria: $winRate%", style: TextStyle(color: Colors.white, fontSize: 16)),
          Text("Máxima Racha: $maxStreak", style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }


  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: playerName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Nombre"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "Ingresa tu nuevo nombre"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  playerName = nameController.text; // Actualizar nombre
                });
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }


}
