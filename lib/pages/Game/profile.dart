import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_android/pages/buildHead.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile_page extends StatefulWidget {
  static const String id = "profile_page";

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile_page> {
  // Datos del usuario (valores por defecto)
  String playerName = "Cargando...";
  String profileImage = "assets/fotoPerfil.png";
  int friends = 0;
  int gamesPlayed = 0;
  double winRate = 0.0;
  int maxStreak = 0;

  // URL base del servidor backend (se obtiene de la variable de entorno)
  late final String? serverBackend;
  // ID del usuario (por ejemplo, obtenido de SharedPreferences)
  late final String? userId;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    // Recuperar el ID del usuario desde SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('idJugador');

    // Obtener la URL del backend desde el archivo .env
    serverBackend = dotenv.env['SERVER_BACKEND'];

    if (userId == null || serverBackend == null) {
      print("Falta el id del usuario o la URL del backend");
      return;
    }

    // Construir la URL para obtener la información, pasando el id del usuario
    final url = Uri.parse('${serverBackend}getUserInfo?id=$userId');
    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        // Agrega autorización si fuera necesario, por ejemplo: "Authorization": "Bearer $token"
      });
      if (response.statusCode == 200) {
        // Se espera que el backend retorne un JSON que incluya las siguientes propiedades:
        // "NombreUser", "FotoPerfil", "friends", "gamesPlayed", "winRate" y "maxStreak"
        final data = jsonDecode(response.body);
        setState(() {
          playerName = data['NombreUser'] ?? playerName;
          // Si la foto de perfil es "none", mantenemos la imagen predeterminada
          profileImage = (data['FotoPerfil'] != null && data['FotoPerfil'] != "none")
              ? data['FotoPerfil']
              : "assets/fotoPerfil.png";

          // Actualizamos las estadísticas si existen; de lo contrario se mantiene el valor por defecto.
          friends = data['friends'] ?? friends;
          gamesPlayed = data['gamesPlayed'] ?? gamesPlayed;
          winRate = (data['winRate'] != null) ? (data['winRate'] as num).toDouble() : winRate;
          maxStreak = data['maxStreak'] ?? maxStreak;
        });
      } else {
        print("Error al obtener el perfil: ${response.statusCode}");
      }
    } catch (error) {
      print("Error en fetchUserInfo: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: BuildHeadArrow(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildGameModeCharts(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Si profileImage es una URL externa se puede usar NetworkImage, de lo contrario se usa AssetImage.
              CircleAvatar(
                radius: 35,
                backgroundImage: profileImage.startsWith("assets")
                    ? AssetImage(profileImage) as ImageProvider
                    : NetworkImage(profileImage),
              ),
              ElevatedButton.icon(
                onPressed: _showEditNameDialog,
                icon: Icon(Icons.edit),
                label: Text('Editar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              )
            ],
          ),
          SizedBox(height: 10),
          Text(
            playerName,
            style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProfileStat("Amigos", friends.toString()),
              _buildProfileStat("Partidas", gamesPlayed.toString()),
              _buildProfileStat("Victorias", "$winRate%"),
              _buildProfileStat("Racha", maxStreak.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 14))
      ],
    );
  }

  Widget _buildGameModeCharts() {
    Map<String, IconData> modeIcons = {
      "Clásica": Icons.extension,
      "Principiante": Icons.verified,
      "Avanzado": Icons.timer_off,
      "Relámpago": Icons.bolt,
      "Incremento": Icons.trending_up,
      "Incremento exprés": Icons.star,
    };

    Map<String, Color> modeColors = {
      "Clásica": Colors.brown,
      "Principiante": Colors.green,
      "Avanzado": Colors.red,
      "Relámpago": Colors.yellow,
      "Incremento": Colors.green,
      "Incremento exprés": Colors.yellow,
    };

    Map<String, List<double>> userData = {
      "Clásica": [4, 5, 6, 4, 3, 5, 4],
      "Principiante": [2, 3, 4],
      "Avanzado": [5, 7, 6, 8, 7, 6, 7, 8, 9, 8],
      "Relámpago": [3, 2],
      "Incremento": [3, 4, 3, 1, 2],
      "Incremento exprés": [],
    };

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: modeIcons.keys.map((mode) {
        List<double> scores = userData[mode]!;
        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(modeIcons[mode], color: modeColors[mode], size: 32),
              SizedBox(height: 6),
              Text(
                mode,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: scores
                            .asMap()
                            .entries
                            .map(
                              (e) =>
                              FlSpot(e.key.toDouble(), e.value),
                        )
                            .toList(),
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showEditNameDialog() {
    // Lógica para editar el nombre del usuario
  }
}
